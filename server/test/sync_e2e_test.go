package test

import (
	"bytes"
	"encoding/json"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strconv"
	"testing"
	"time"

	httpAdapter "github.com/ftthreign/savoryx_app/server/internal/adapter/handler/http"
	"github.com/ftthreign/savoryx_app/server/internal/adapter/handler/http/dto"
	"github.com/ftthreign/savoryx_app/server/internal/adapter/security"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/core/service"
	"github.com/ftthreign/savoryx_app/server/internal/testutil"
	"github.com/ftthreign/savoryx_app/server/internal/testutil/fakes"
	"github.com/ftthreign/savoryx_app/server/internal/testutil/mocks"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestE2E_OfflineFirstDeltaSyncAndLedger(t *testing.T) {
	const hmacSecret = "e2e-sync-hmac-secret-key-2026"

	var logBuf bytes.Buffer
	logger := slog.New(slog.NewJSONHandler(&logBuf, nil))
	tokenMgr, err := security.NewPasetoTokenManager("")
	require.NoError(t, err)

	deviceToken, err := tokenMgr.GenerateDeviceToken(testutil.DefaultDeviceID, 24*time.Hour)
	require.NoError(t, err)

	accRepo := fakes.NewInMemoryAccountRepository()
	catRepo := fakes.NewInMemoryCategoryRepository()
	txRepo := fakes.NewInMemoryTransactionRepository()

	accSvc := service.NewAccountService(accRepo)
	catSvc := service.NewCategoryService(catRepo)
	txSvc := service.NewTransactionService(txRepo, accRepo, catRepo)
	syncSvc := service.NewSyncService(accRepo, catRepo, txRepo)

	router := httpAdapter.SetupRouter(
		logger,
		&mocks.MockHealthService{Status: "ok"},
		"1.0.0-e2e",
		"test",
		httpAdapter.WithTokenManager(tokenMgr),
		httpAdapter.WithHMACSecretKey(hmacSecret),
		httpAdapter.WithAccountService(accSvc),
		httpAdapter.WithCategoryService(catSvc),
		httpAdapter.WithTransactionService(txSvc),
		httpAdapter.WithSyncService(syncSvc),
	)

	doSigned := func(method, path string, payload any) *httptest.ResponseRecorder {
		var bodyBytes []byte
		if payload != nil {
			b, err := json.Marshal(payload)
			require.NoError(t, err)
			bodyBytes = b
		}
		req := httptest.NewRequest(method, path, bytes.NewReader(bodyBytes))
		req.Header.Set("Authorization", "Bearer "+deviceToken)
		req.Header.Set("Content-Type", "application/json")
		if method == http.MethodPost || method == http.MethodPut || method == http.MethodPatch || method == http.MethodDelete {
			ts := strconv.FormatInt(time.Now().UTC().Unix(), 10)
			sig := httpAdapter.ComputeHMACSignature(hmacSecret, ts, method, path, bodyBytes)
			req.Header.Set("X-Timestamp", ts)
			req.Header.Set("X-Signature", sig)
		}
		rec := httptest.NewRecorder()
		router.ServeHTTP(rec, req)
		return rec
	}

	accID := "0192d6e2-5b9c-7000-8000-000000000001"
	catID := "0192d6e2-5b9c-7000-8000-000000000010"
	txID := "0192d6e2-5b9c-7000-8000-000000000100"

	t0 := time.Date(2026, 11, 10, 8, 0, 0, 0, time.UTC)
	t1 := t0.Add(10 * time.Minute)
	t2 := t0.Add(20 * time.Minute)
	tOld := t0.Add(-30 * time.Minute)

	t.Run("1. Initial Batch Push creates accounts, categories, and transactions", func(t *testing.T) {
		pushReq := dto.SyncPushRequest{
			Accounts: []dto.SyncAccountDTO{
				{
					ID:        accID,
					Name:      "BCA Main",
					Type:      "BANK",
					Currency:  "IDR",
					Balance:   "5000000.00",
					CreatedAt: t0.Format(time.RFC3339Nano),
					UpdatedAt: t1.Format(time.RFC3339Nano),
				},
			},
			Categories: []dto.SyncCategoryDTO{
				{
					ID:        catID,
					Name:      "Medical",
					Icon:      "medical_services",
					Color:     "#D90000",
					IsWants:   false,
					CreatedAt: t0.Format(time.RFC3339Nano),
					UpdatedAt: t1.Format(time.RFC3339Nano),
				},
			},
			Transactions: []dto.SyncTransactionDTO{
				{
					ID:              txID,
					AccountID:       accID,
					CategoryID:      catID,
					Type:            "EXPENSE",
					Amount:          "888888.88",
					Currency:        "IDR",
					Note:            "Confidential Hospital Bill",
					TransactionDate: t1.Format(time.RFC3339Nano),
					CreatedAt:       t1.Format(time.RFC3339Nano),
					UpdatedAt:       t1.Format(time.RFC3339Nano),
				},
			},
		}

		rec := doSigned(http.MethodPost, "/api/v1/sync/push", pushReq)
		require.Equal(t, http.StatusOK, rec.Code)
	})

	t.Run("2. LWW Conflict Resolution ignores stale account update and applies newer update", func(t *testing.T) {
		// Stale push (tOld < t1) must be ignored
		stalePush := dto.SyncPushRequest{
			Accounts: []dto.SyncAccountDTO{
				{
					ID:        accID,
					Name:      "Stale Outdated Name",
					Type:      "BANK",
					Currency:  "IDR",
					Balance:   "100.00",
					CreatedAt: t0.Format(time.RFC3339Nano),
					UpdatedAt: tOld.Format(time.RFC3339Nano),
				},
			},
		}
		rec := doSigned(http.MethodPost, "/api/v1/sync/push", stalePush)
		require.Equal(t, http.StatusOK, rec.Code)

		getRec := doSigned(http.MethodGet, "/api/v1/accounts/"+accID, nil)
		require.Equal(t, http.StatusOK, getRec.Code)
		assert.Contains(t, getRec.Body.String(), "BCA Main")
		assert.NotContains(t, getRec.Body.String(), "Stale Outdated Name")

		// Newer push (t2 > t1) must win
		newerPush := dto.SyncPushRequest{
			Accounts: []dto.SyncAccountDTO{
				{
					ID:        accID,
					Name:      "BCA Prioritas Updated",
					Type:      "BANK",
					Currency:  "IDR",
					Balance:   "4111111.12",
					CreatedAt: t0.Format(time.RFC3339Nano),
					UpdatedAt: t2.Format(time.RFC3339Nano),
				},
			},
		}
		rec = doSigned(http.MethodPost, "/api/v1/sync/push", newerPush)
		require.Equal(t, http.StatusOK, rec.Code)

		getRec = doSigned(http.MethodGet, "/api/v1/accounts/"+accID, nil)
		require.Equal(t, http.StatusOK, getRec.Code)
		assert.Contains(t, getRec.Body.String(), "BCA Prioritas Updated")
	})

	t.Run("3. Append-Only Ledger idempotency and Tombstone propagation on Pull", func(t *testing.T) {
		// Attempting to mutate amount of an existing UUIDv7 transaction without tombstone is ignored
		duplicateTxPush := dto.SyncPushRequest{
			Transactions: []dto.SyncTransactionDTO{
				{
					ID:              txID,
					AccountID:       accID,
					CategoryID:      catID,
					Type:            "EXPENSE",
					Amount:          "999999.99",
					Currency:        "IDR",
					Note:            "Tampered Note",
					TransactionDate: t1.Format(time.RFC3339Nano),
					CreatedAt:       t1.Format(time.RFC3339Nano),
					UpdatedAt:       t2.Format(time.RFC3339Nano),
				},
			},
		}
		rec := doSigned(http.MethodPost, "/api/v1/sync/push", duplicateTxPush)
		require.Equal(t, http.StatusOK, rec.Code)

		getTxRec := doSigned(http.MethodGet, "/api/v1/transactions/"+txID, nil)
		require.Equal(t, http.StatusOK, getTxRec.Code)
		assert.Contains(t, getTxRec.Body.String(), "888888.88")
		assert.NotContains(t, getTxRec.Body.String(), "999999.99")

		// Push tombstone for transaction
		t3 := t2.Add(5 * time.Minute).Format(time.RFC3339Nano)
		tombstonePush := dto.SyncPushRequest{
			Transactions: []dto.SyncTransactionDTO{
				{
					ID:              txID,
					AccountID:       accID,
					CategoryID:      catID,
					Type:            "EXPENSE",
					Amount:          "888888.88",
					Currency:        "IDR",
					TransactionDate: t1.Format(time.RFC3339Nano),
					CreatedAt:       t1.Format(time.RFC3339Nano),
					UpdatedAt:       t3,
					DeletedAt:       &t3,
				},
			},
		}
		rec = doSigned(http.MethodPost, "/api/v1/sync/push", tombstonePush)
		require.Equal(t, http.StatusOK, rec.Code)

		// Delta pull after t1 returns updated account and tombstoned transaction
		pullRec := doSigned(http.MethodPost, "/api/v1/sync/pull", dto.SyncPullRequest{
			LastPulledAt: t1.Format(time.RFC3339Nano),
		})
		require.Equal(t, http.StatusOK, pullRec.Code)

		var pullEnv struct {
			Data dto.SyncPullResponse `json:"data"`
		}
		require.NoError(t, json.Unmarshal(pullRec.Body.Bytes(), &pullEnv))
		require.Len(t, pullEnv.Data.Accounts, 1)
		assert.Equal(t, "BCA Prioritas Updated", pullEnv.Data.Accounts[0].Name)
		require.Len(t, pullEnv.Data.Transactions, 1)
		assert.NotNil(t, pullEnv.Data.Transactions[0].DeletedAt, "tombstone deleted_at must be returned in delta pull")
	})

	t.Run("4. Zero Financial Detail in Server Logs", func(t *testing.T) {
		logs := logBuf.String()
		assert.NotContains(t, logs, "888888.88", "transaction amount must never appear in server logs")
		assert.NotContains(t, logs, "Confidential Hospital Bill", "transaction note must never appear in server logs")
		assert.NotContains(t, logs, "4111111.12", "account balance must never appear in server logs")
	})
}

func TestE2E_MergeCheckpoint1_FullHandshakeToSyncLogsAndSecurity(t *testing.T) {
	const hmacSecret = "savoryx-checkpoint1-hmac-secret-2026"

	var logBuf bytes.Buffer
	logger := slog.New(slog.NewJSONHandler(&logBuf, nil))
	tokenMgr, err := security.NewPasetoTokenManager("")
	require.NoError(t, err)

	deviceRepo := fakes.NewInMemoryDeviceRepository()
	accRepo := fakes.NewInMemoryAccountRepository()
	catRepo := fakes.NewInMemoryCategoryRepository()
	txRepo := fakes.NewInMemoryTransactionRepository()
	syncLogRepo := fakes.NewInMemorySyncLogRepository()

	authSvc := service.NewAuthService(deviceRepo, tokenMgr)
	accSvc := service.NewAccountService(accRepo)
	catSvc := service.NewCategoryService(catRepo)
	txSvc := service.NewTransactionService(txRepo, accRepo, catRepo)
	syncSvc := service.NewSyncServiceWithOptions(
		accRepo,
		catRepo,
		txRepo,
		service.WithSyncTxManager(&mocks.MockTxManager{}),
		service.WithSyncLogRepository(syncLogRepo),
	)
	syncLimiter := httpAdapter.NewSlidingWindowLimiter(httpAdapter.DefaultSyncRateLimitPerMinute)

	router := httpAdapter.SetupRouter(
		logger,
		&mocks.MockHealthService{Status: "ok"},
		"1.0.0-checkpoint1",
		"test",
		httpAdapter.WithTokenManager(tokenMgr),
		httpAdapter.WithHMACSecretKey(hmacSecret),
		httpAdapter.WithAuthService(authSvc),
		httpAdapter.WithAccountService(accSvc),
		httpAdapter.WithCategoryService(catSvc),
		httpAdapter.WithTransactionService(txSvc),
		httpAdapter.WithSyncService(syncSvc),
		httpAdapter.WithSyncRateLimiter(syncLimiter),
	)

	deviceID := domain.NewUUIDv7()
	var bearerToken string

	baseTime := time.Now().UTC().Add(-2 * time.Hour).Truncate(time.Microsecond)
	t1 := baseTime.Add(10 * time.Minute)
	t2 := baseTime.Add(20 * time.Minute)
	tStale := baseTime.Add(5 * time.Minute)
	tTombstone := baseTime.Add(30 * time.Minute)

	bcaID := domain.NewUUIDv7().String()
	cashID := domain.NewUUIDv7().String()
	foodCatID := domain.NewUUIDv7().String()
	utilCatID := domain.NewUUIDv7().String()
	expTxID := domain.NewUUIDv7().String()
	incTxID := domain.NewUUIDv7().String()
	trfTxID := domain.NewUUIDv7().String()

	signPipe := func(method, path string, payload any, ts string) *http.Request {
		var bodyBytes []byte
		if payload != nil {
			b, marshalErr := json.Marshal(payload)
			require.NoError(t, marshalErr)
			bodyBytes = b
		}
		req := httptest.NewRequest(method, path, bytes.NewReader(bodyBytes))
		req.Header.Set("Authorization", "Bearer "+bearerToken)
		req.Header.Set("Content-Type", "application/json")
		if ts == "" {
			ts = time.Now().UTC().Format(time.RFC3339Nano)
		}
		if method == http.MethodPost || method == http.MethodPut || method == http.MethodPatch || method == http.MethodDelete {
			sig := httpAdapter.ComputePipeHMACSignature(hmacSecret, ts, method, path, bodyBytes)
			req.Header.Set("X-Device-ID", deviceID.String())
			req.Header.Set("X-Timestamp", ts)
			req.Header.Set("X-Signature", sig)
		}
		return req
	}

	t.Run("Scenario 1: Device Handshake -> Signed Batch Push (Accounts+Categories+3 Txs incl Transfer) -> Incremental Pull & SyncLogs", func(t *testing.T) {
		// Step 1: Register Device
		regBody, err := json.Marshal(dto.RegisterDeviceRequest{
			DeviceID:   deviceID.String(),
			DeviceName: "Pixel 9 Pro",
			Platform:   "android",
			AppVersion: "1.0.0",
		})
		require.NoError(t, err)

		regReq := httptest.NewRequest(http.MethodPost, "/api/v1/auth/register-device", bytes.NewReader(regBody))
		regReq.Header.Set("Content-Type", "application/json")
		regRec := httptest.NewRecorder()
		router.ServeHTTP(regRec, regReq)
		require.Equal(t, http.StatusCreated, regRec.Code)

		var regEnv struct {
			Data dto.RegisterDeviceResponse `json:"data"`
		}
		require.NoError(t, json.Unmarshal(regRec.Body.Bytes(), &regEnv))
		require.NotEmpty(t, regEnv.Data.Token)
		require.NotEmpty(t, regEnv.Data.DeviceSecret)
		bearerToken = regEnv.Data.Token

		// Step 2a: Push 2 accounts and 2 categories
		push1 := dto.SyncPushRequest{
			Accounts: []dto.SyncAccountDTO{
				{ID: bcaID, Name: "Bank BCA", Type: "BANK", Currency: "IDR", Balance: "2000000.00", CreatedAt: baseTime.Format(time.RFC3339Nano), UpdatedAt: t1.Format(time.RFC3339Nano)},
				{ID: cashID, Name: "Dompet Tunai", Type: "CASH", Currency: "IDR", Balance: "500000.00", CreatedAt: baseTime.Format(time.RFC3339Nano), UpdatedAt: t1.Format(time.RFC3339Nano)},
			},
			Categories: []dto.SyncCategoryDTO{
				{ID: foodCatID, Name: "Groceries", Icon: "shopping_cart", Color: "#8DB355", IsWants: false, CreatedAt: baseTime.Format(time.RFC3339Nano), UpdatedAt: t1.Format(time.RFC3339Nano)},
				{ID: utilCatID, Name: "Utilities", Icon: "bolt", Color: "#FFEA93", IsWants: false, CreatedAt: baseTime.Format(time.RFC3339Nano), UpdatedAt: t1.Format(time.RFC3339Nano)},
			},
		}
		rec1 := httptest.NewRecorder()
		router.ServeHTTP(rec1, signPipe(http.MethodPost, "/api/v1/sync/push", push1, ""))
		require.Equal(t, http.StatusOK, rec1.Code)

		// Step 2b: Push 3 transactions (Expense, Income, Transfer) to verify row-locked decimal reconciliation
		push2 := dto.SyncPushRequest{
			Transactions: []dto.SyncTransactionDTO{
				{ID: expTxID, AccountID: bcaID, CategoryID: foodCatID, Type: "EXPENSE", Amount: "150000.00", Currency: "IDR", Note: "Private Groceries Receipt", TransactionDate: t1.Format(time.RFC3339Nano), CreatedAt: t1.Format(time.RFC3339Nano), UpdatedAt: t1.Format(time.RFC3339Nano)},
				{ID: incTxID, AccountID: cashID, CategoryID: utilCatID, Type: "INCOME", Amount: "300000.00", Currency: "IDR", Note: "Secret Utility Refund", TransactionDate: t1.Format(time.RFC3339Nano), CreatedAt: t1.Format(time.RFC3339Nano), UpdatedAt: t1.Format(time.RFC3339Nano)},
				{ID: trfTxID, AccountID: bcaID, DestinationAccountID: cashID, Type: "TRANSFER", Amount: "250000.00", Currency: "IDR", Note: "ATM Topup", TransactionDate: t1.Format(time.RFC3339Nano), CreatedAt: t1.Format(time.RFC3339Nano), UpdatedAt: t1.Format(time.RFC3339Nano)},
			},
		}
		rec2 := httptest.NewRecorder()
		router.ServeHTTP(rec2, signPipe(http.MethodPost, "/api/v1/sync/push", push2, ""))
		require.Equal(t, http.StatusOK, rec2.Code)

		// Verify reconciled account balances: BCA = 2000000 - 150000 - 250000 = 1600000.00; Cash = 500000 + 300000 + 250000 = 1050000.00
		getBCA := httptest.NewRecorder()
		router.ServeHTTP(getBCA, signPipe(http.MethodGet, "/api/v1/accounts/"+bcaID, nil, ""))
		require.Equal(t, http.StatusOK, getBCA.Code)
		assert.Contains(t, getBCA.Body.String(), `"balance":"1600000.00"`)

		getCash := httptest.NewRecorder()
		router.ServeHTTP(getCash, signPipe(http.MethodGet, "/api/v1/accounts/"+cashID, nil, ""))
		require.Equal(t, http.StatusOK, getCash.Code)
		assert.Contains(t, getCash.Body.String(), `"balance":"1050000.00"`)

		// Step 3: Incremental Delta Pull via GET /api/v1/sync/pull?since=...
		pullReq := signPipe(http.MethodGet, "/api/v1/sync/pull?since="+baseTime.Format(time.RFC3339Nano), nil, "")
		pullRec := httptest.NewRecorder()
		router.ServeHTTP(pullRec, pullReq)
		require.Equal(t, http.StatusOK, pullRec.Code)

		var pullEnv struct {
			Data dto.SyncPullResponse `json:"data"`
		}
		require.NoError(t, json.Unmarshal(pullRec.Body.Bytes(), &pullEnv))
		assert.Len(t, pullEnv.Data.Accounts, 2)
		assert.Len(t, pullEnv.Data.Categories, 2)
		assert.Len(t, pullEnv.Data.Transactions, 3)
		assert.False(t, pullEnv.Data.PulledAt.IsZero())
		assert.NotEmpty(t, pullEnv.Data.ServerTime)

		// Step 4: Verify sync_logs recorded 2 PUSH entries + 1 PULL entry for this device
		totalLogs, err := syncLogRepo.CountByDevice(t.Context(), deviceID)
		require.NoError(t, err)
		assert.Equal(t, 3, totalLogs)

		logsList, err := syncLogRepo.ListByDevice(t.Context(), deviceID, 10, 0)
		require.NoError(t, err)
		require.Len(t, logsList, 3)
		assert.Equal(t, domain.SyncDirectionPull, logsList[0].Direction)
		assert.Equal(t, 7, logsList[0].BatchSize)
	})

	t.Run("Scenario 2: Category LWW Conflict Resolution & Transaction Tombstone Propagation", func(t *testing.T) {
		// Stale category update (tStale < t1) must be ignored
		staleCatPush := dto.SyncPushRequest{
			Categories: []dto.SyncCategoryDTO{
				{ID: foodCatID, Name: "Outdated Stale Groceries", Icon: "old", Color: "#000000", IsWants: true, CreatedAt: baseTime.Format(time.RFC3339Nano), UpdatedAt: tStale.Format(time.RFC3339Nano)},
			},
		}
		recStale := httptest.NewRecorder()
		router.ServeHTTP(recStale, signPipe(http.MethodPost, "/api/v1/sync/push", staleCatPush, ""))
		require.Equal(t, http.StatusOK, recStale.Code)

		// Newer category update (t2 > t1) and transaction tombstone (tTombstone) must win
		delStr := tTombstone.Format(time.RFC3339Nano)
		winAndDeletePush := dto.SyncPushRequest{
			Categories: []dto.SyncCategoryDTO{
				{ID: foodCatID, Name: "Fresh Groceries LWW", Icon: "shopping_bag", Color: "#8DB355", IsWants: false, CreatedAt: baseTime.Format(time.RFC3339Nano), UpdatedAt: t2.Format(time.RFC3339Nano)},
			},
			Transactions: []dto.SyncTransactionDTO{
				{ID: expTxID, AccountID: bcaID, CategoryID: foodCatID, Type: "EXPENSE", Amount: "150000.00", Currency: "IDR", TransactionDate: t1.Format(time.RFC3339Nano), CreatedAt: t1.Format(time.RFC3339Nano), UpdatedAt: delStr, DeletedAt: &delStr},
			},
		}
		recWin := httptest.NewRecorder()
		router.ServeHTTP(recWin, signPipe(http.MethodPost, "/api/v1/sync/push", winAndDeletePush, ""))
		require.Equal(t, http.StatusOK, recWin.Code)

		// Pull after t1 returns updated category name (not stale) and tombstoned transaction
		pullRec := httptest.NewRecorder()
		router.ServeHTTP(pullRec, signPipe(http.MethodGet, "/api/v1/sync/pull?since="+t1.Format(time.RFC3339Nano), nil, ""))
		require.Equal(t, http.StatusOK, pullRec.Code)

		var pullEnv struct {
			Data dto.SyncPullResponse `json:"data"`
		}
		require.NoError(t, json.Unmarshal(pullRec.Body.Bytes(), &pullEnv))
		require.Len(t, pullEnv.Data.Categories, 1)
		assert.Equal(t, "Fresh Groceries LWW", pullEnv.Data.Categories[0].Name)
		require.Len(t, pullEnv.Data.Transactions, 1)
		assert.NotNil(t, pullEnv.Data.Transactions[0].DeletedAt)
	})

	t.Run("Scenario 3: Security (Tampered Signature, Clock Skew + X-Server-Time, Device Spoofing) & 429 Rate Limit", func(t *testing.T) {
		body := []byte(`{"last_pulled_at":"2026-11-10T00:00:00Z"}`)

		// 3a. Tampered signature -> 401 invalid_signature
		badSigReq := httptest.NewRequest(http.MethodPost, "/api/v1/sync/pull", bytes.NewReader(body))
		badSigReq.Header.Set("Authorization", "Bearer "+bearerToken)
		badSigReq.Header.Set("Content-Type", "application/json")
		badSigReq.Header.Set("X-Timestamp", time.Now().UTC().Format(time.RFC3339Nano))
		badSigReq.Header.Set("X-Signature", "deadbeef")
		badSigRec := httptest.NewRecorder()
		router.ServeHTTP(badSigRec, badSigReq)
		assert.Equal(t, http.StatusUnauthorized, badSigRec.Code)

		// 3b. Clock skew > 60s -> 401 clock_skew_exceeded + X-Server-Time
		expiredTS := time.Now().UTC().Add(-90 * time.Second).Format(time.RFC3339Nano)
		skewReq := signPipe(http.MethodPost, "/api/v1/sync/pull", map[string]string{"last_pulled_at": "2026-11-10T00:00:00Z"}, expiredTS)
		skewRec := httptest.NewRecorder()
		router.ServeHTTP(skewRec, skewReq)
		assert.Equal(t, http.StatusUnauthorized, skewRec.Code)
		assert.NotEmpty(t, skewRec.Header().Get("X-Server-Time"))

		// 3c. Spoofed X-Device-ID differing from PASETO claims -> 401 device_id_mismatch
		spoofReq := signPipe(http.MethodPost, "/api/v1/sync/pull", map[string]string{"last_pulled_at": "2026-11-10T00:00:00Z"}, "")
		spoofReq.Header.Set("X-Device-ID", domain.NewUUIDv7().String())
		spoofRec := httptest.NewRecorder()
		router.ServeHTTP(spoofRec, spoofReq)
		assert.Equal(t, http.StatusUnauthorized, spoofRec.Code)

		// 3d. Exceed 120 req/min sliding window quota -> 429 Too Many Requests + Retry-After
		rateLimited := false
		for i := 0; i < httpAdapter.DefaultSyncRateLimitPerMinute+5; i++ {
			rec := httptest.NewRecorder()
			router.ServeHTTP(rec, signPipe(http.MethodGet, "/api/v1/sync/pull?since="+baseTime.Format(time.RFC3339Nano), nil, ""))
			if rec.Code == http.StatusTooManyRequests {
				rateLimited = true
				assert.Equal(t, "0", rec.Header().Get("X-RateLimit-Remaining"))
				assert.NotEmpty(t, rec.Header().Get("Retry-After"))
				break
			}
			require.Equal(t, http.StatusOK, rec.Code)
		}
		assert.True(t, rateLimited, "exceeding 120 req/min must return HTTP 429")
	})

	t.Run("Scenario 4: Zero Financial Detail Privacy Audit across Full Server Logs", func(t *testing.T) {
		logs := logBuf.String()
		assert.NotEmpty(t, logs)
		assert.NotContains(t, logs, "150000.00")
		assert.NotContains(t, logs, "2000000.00")
		assert.NotContains(t, logs, "1600000.00")
		assert.NotContains(t, logs, "1050000.00")
		assert.NotContains(t, logs, "Private Groceries Receipt")
		assert.NotContains(t, logs, "Secret Utility Refund")
	})
}
