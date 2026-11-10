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
