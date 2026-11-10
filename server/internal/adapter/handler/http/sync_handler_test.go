package http_test

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strconv"
	"testing"
	"time"

	httpAdapter "github.com/ftthreign/savoryx_app/server/internal/adapter/handler/http"
	"github.com/ftthreign/savoryx_app/server/internal/adapter/security"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/ftthreign/savoryx_app/server/internal/testutil"
	"github.com/ftthreign/savoryx_app/server/internal/testutil/mocks"
	"github.com/shopspring/decimal"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestSyncAndTransactionHandlers_WithHMACAndAuth(t *testing.T) {
	const hmacSecret = "savoryx-sync-test-secret-key-2026"

	logger := slog.New(slog.NewJSONHandler(io.Discard, nil))
	tokenMgr, err := security.NewPasetoTokenManager("")
	require.NoError(t, err)

	token, err := tokenMgr.GenerateDeviceToken(testutil.DefaultDeviceID, time.Hour)
	require.NoError(t, err)

	accID := domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000001")
	catID := domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000010")
	txID := domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000100")

	txSvc := &mocks.MockTransactionService{
		CreateTransactionFunc: func(ctx context.Context, tx *domain.Transaction) error {
			assert.Equal(t, txID, tx.ID)
			assert.Equal(t, accID, tx.AccountID)
			assert.True(t, decimal.NewFromInt(75000).Equal(tx.Amount))
			return nil
		},
		ListTransactionsFunc: func(ctx context.Context, filterAccID *domain.UUID, limit, offset int) ([]*domain.Transaction, int, error) {
			require.NotNil(t, filterAccID)
			assert.Equal(t, accID, *filterAccID)
			c := catID
			return []*domain.Transaction{
				{
					ID:                 txID,
					AccountID:          accID,
					CategoryID:         &c,
					Type:               domain.TransactionTypeExpense,
					Amount:             decimal.NewFromInt(75000),
					Currency:           "IDR",
					ExchangeRateToBase: decimal.NewFromInt(1),
					BaseAmount:         decimal.NewFromInt(75000),
					TransactionDate:    time.Now().UTC(),
				},
			}, 1, nil
		},
	}

	syncSvc := &mocks.MockSyncService{
		PullChangesFunc: func(ctx context.Context, lastPulledAt time.Time) (*port.SyncPullResult, error) {
			return &port.SyncPullResult{
				Accounts: []*domain.Account{
					{
						ID:       accID,
						Name:     "Main Bank",
						Type:     domain.AccountTypeBank,
						Currency: "IDR",
						Balance:  decimal.NewFromInt(925000),
					},
				},
				Categories:   []*domain.Category{},
				Transactions: []*domain.Transaction{},
				PulledAt:     time.Now().UTC(),
			}, nil
		},
		PushChangesFunc: func(ctx context.Context, payload *port.SyncPushPayload) (*port.SyncPushResult, error) {
			return &port.SyncPushResult{
				AccountsApplied:     len(payload.Accounts),
				CategoriesApplied:   len(payload.Categories),
				TransactionsApplied: len(payload.Transactions),
				SyncedAt:            time.Now().UTC(),
			}, nil
		},
	}

	router := httpAdapter.SetupRouter(
		logger,
		&mocks.MockHealthService{Status: "ok"},
		"1.0.0",
		"test",
		httpAdapter.WithTokenManager(tokenMgr),
		httpAdapter.WithHMACSecretKey(hmacSecret),
		httpAdapter.WithTransactionService(txSvc),
		httpAdapter.WithSyncService(syncSvc),
	)

	signRequest := func(method, path string, body []byte) *http.Request {
		req := httptest.NewRequest(method, path, bytes.NewReader(body))
		req.Header.Set("Authorization", "Bearer "+token)
		req.Header.Set("Content-Type", "application/json")
		ts := strconv.FormatInt(time.Now().UTC().Unix(), 10)
		sig := httpAdapter.ComputeHMACSignature(hmacSecret, ts, method, path, body)
		req.Header.Set("X-Timestamp", ts)
		req.Header.Set("X-Signature", sig)
		return req
	}

	t.Run("POST /api/v1/transactions creates transaction with valid HMAC signature", func(t *testing.T) {
		body := []byte(`{
			"id": "0192d6e2-5b9c-7000-8000-000000000100",
			"account_id": "0192d6e2-5b9c-7000-8000-000000000001",
			"category_id": "0192d6e2-5b9c-7000-8000-000000000010",
			"type": "EXPENSE",
			"amount": "75000.00",
			"currency": "IDR",
			"note": "Dinner"
		}`)

		req := signRequest(http.MethodPost, "/api/v1/transactions", body)
		rec := httptest.NewRecorder()
		router.ServeHTTP(rec, req)

		require.Equal(t, http.StatusCreated, rec.Code)
		assert.Equal(t, "/api/v1/transactions/0192d6e2-5b9c-7000-8000-000000000100", rec.Header().Get("Location"))
	})

	t.Run("GET /api/v1/transactions supports account_id filter and pagination", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/transactions?account_id=0192d6e2-5b9c-7000-8000-000000000001&limit=10&offset=0", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		rec := httptest.NewRecorder()
		router.ServeHTTP(rec, req)

		require.Equal(t, http.StatusOK, rec.Code)
		var resp httpAdapter.ResponseEnvelope
		require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &resp))
		assert.NotNil(t, resp.Data)
		assert.NotNil(t, resp.Meta)
	})

	t.Run("POST /api/v1/sync/pull returns delta payload", func(t *testing.T) {
		body := []byte(`{"last_pulled_at": "2026-11-01T00:00:00Z"}`)
		req := signRequest(http.MethodPost, "/api/v1/sync/pull", body)
		rec := httptest.NewRecorder()
		router.ServeHTTP(rec, req)

		require.Equal(t, http.StatusOK, rec.Code)
	})

	t.Run("POST /api/v1/sync/push applies batch changes", func(t *testing.T) {
		body := []byte(`{
			"accounts": [{
				"id": "0192d6e2-5b9c-7000-8000-000000000001",
				"name": "Main Bank",
				"type": "BANK",
				"currency": "IDR",
				"balance": "1000000.00"
			}],
			"categories": [],
			"transactions": []
		}`)
		req := signRequest(http.MethodPost, "/api/v1/sync/push", body)
		rec := httptest.NewRecorder()
		router.ServeHTTP(rec, req)

		require.Equal(t, http.StatusOK, rec.Code)
	})
}

func TestSyncHandler_SecurityRateLimitAndQueryParamPull(t *testing.T) {
	const hmacSecret = "savoryx-sync-handler-secret-2026"

	var logBuf bytes.Buffer
	logger := slog.New(slog.NewJSONHandler(&logBuf, nil))
	tokenMgr, err := security.NewPasetoTokenManager("")
	require.NoError(t, err)

	token, err := tokenMgr.GenerateDeviceToken(testutil.DefaultDeviceID, time.Hour)
	require.NoError(t, err)

	var capturedPullDevice domain.UUID
	var capturedPullSince time.Time
	var capturedPushDevice domain.UUID
	var capturedPushClientTS time.Time

	syncSvc := &mocks.MockSyncService{
		PullChangesFunc: func(ctx context.Context, lastPulledAt time.Time) (*port.SyncPullResult, error) {
			capturedPullDevice, _ = domain.SyncDeviceIDFromContext(ctx)
			capturedPullSince = lastPulledAt
			return &port.SyncPullResult{
				Accounts:     []*domain.Account{},
				Categories:   []*domain.Category{},
				Transactions: []*domain.Transaction{},
				PulledAt:     time.Date(2026, 11, 10, 12, 0, 0, 123456000, time.UTC),
			}, nil
		},
		PushChangesFunc: func(ctx context.Context, payload *port.SyncPushPayload) (*port.SyncPushResult, error) {
			capturedPushDevice = payload.DeviceID
			capturedPushClientTS = payload.ClientTimestamp
			return &port.SyncPushResult{
				AccountsApplied:     len(payload.Accounts),
				CategoriesApplied:   len(payload.Categories),
				TransactionsApplied: len(payload.Transactions),
				SyncedAt:            time.Now().UTC(),
			}, nil
		},
	}

	syncLimiter := httpAdapter.NewSlidingWindowLimiter(2)
	router := httpAdapter.SetupRouter(
		logger,
		&mocks.MockHealthService{Status: "ok"},
		"1.0.0",
		"test",
		httpAdapter.WithTokenManager(tokenMgr),
		httpAdapter.WithHMACSecretKey(hmacSecret),
		httpAdapter.WithSyncService(syncSvc),
		httpAdapter.WithSyncRateLimiter(syncLimiter),
	)

	t.Run("rejects unauthenticated request without PASETO token", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/sync/pull?since=2026-11-01T00:00:00Z", nil)
		rec := httptest.NewRecorder()
		router.ServeHTTP(rec, req)
		assert.Equal(t, http.StatusUnauthorized, rec.Code)
	})

	t.Run("GET /api/v1/sync/pull?since=... parses query cursor and binds device context", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/sync/pull?since=2026-11-01T00:00:00Z", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		rec := httptest.NewRecorder()
		router.ServeHTTP(rec, req)

		require.Equal(t, http.StatusOK, rec.Code)
		assert.Equal(t, testutil.DefaultDeviceID, capturedPullDevice)
		assert.Equal(t, time.Date(2026, 11, 1, 0, 0, 0, 0, time.UTC), capturedPullSince)
		assert.Equal(t, "2", rec.Header().Get("X-RateLimit-Limit"))
		assert.Equal(t, "1", rec.Header().Get("X-RateLimit-Remaining"))
		assert.Contains(t, rec.Body.String(), `"server_time":"2026-11-10T12:00:00.123456Z"`)
	})

	t.Run("GET /api/v1/sync/pull rejects malformed since timestamp with 400", func(t *testing.T) {
		freshLimiter := httpAdapter.NewSlidingWindowLimiter(10)
		r := httpAdapter.SetupRouter(
			logger,
			&mocks.MockHealthService{Status: "ok"},
			"1.0.0",
			"test",
			httpAdapter.WithTokenManager(tokenMgr),
			httpAdapter.WithHMACSecretKey(hmacSecret),
			httpAdapter.WithSyncService(syncSvc),
			httpAdapter.WithSyncRateLimiter(freshLimiter),
		)

		req := httptest.NewRequest(http.MethodGet, "/api/v1/sync/pull?since=bad-timestamp", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		rec := httptest.NewRecorder()
		r.ServeHTTP(rec, req)
		assert.Equal(t, http.StatusBadRequest, rec.Code)
	})

	t.Run("POST /api/v1/sync/push binds device ID + timestamp, hides financial details in logs, and enforces 429 limit", func(t *testing.T) {
		body := []byte(`{
			"accounts": [{
				"id": "0192d6e2-5b9c-7000-8000-000000000001",
				"name": "Secret Bank",
				"type": "BANK",
				"currency": "IDR",
				"balance": "9876543.21"
			}],
			"categories": [],
			"transactions": [{
				"id": "0192d6e2-5b9c-7000-8000-000000000100",
				"account_id": "0192d6e2-5b9c-7000-8000-000000000001",
				"category_id": "0192d6e2-5b9c-7000-8000-000000000010",
				"type": "EXPENSE",
				"amount": "123456.78",
				"currency": "IDR",
				"note": "Private Medical Purchase",
				"transaction_date": "2026-11-10T10:00:00Z"
			}]
		}`)
		ts := time.Now().UTC().Format(time.RFC3339Nano)
		sig := httpAdapter.ComputePipeHMACSignature(hmacSecret, ts, http.MethodPost, "/api/v1/sync/push", body)

		// Request #2 consumes the 2nd and final slot in syncLimiter(limit=2).
		req := httptest.NewRequest(http.MethodPost, "/api/v1/sync/push", bytes.NewReader(body))
		req.Header.Set("Authorization", "Bearer "+token)
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("X-Device-ID", testutil.DefaultDeviceID.String())
		req.Header.Set("X-Timestamp", ts)
		req.Header.Set("X-Signature", sig)
		rec := httptest.NewRecorder()
		router.ServeHTTP(rec, req)

		require.Equal(t, http.StatusOK, rec.Code)
		assert.Equal(t, testutil.DefaultDeviceID, capturedPushDevice)
		assert.False(t, capturedPushClientTS.IsZero())
		assert.Equal(t, "0", rec.Header().Get("X-RateLimit-Remaining"))

		// Verify Zero Financial Detail in Logs rule.
		logs := logBuf.String()
		assert.NotContains(t, logs, "9876543.21")
		assert.NotContains(t, logs, "123456.78")
		assert.NotContains(t, logs, "Private Medical Purchase")
		assert.NotContains(t, logs, "Secret Bank")

		// Request #3 exceeds sliding window quota and returns 429 Too Many Requests.
		reqOver := httptest.NewRequest(http.MethodPost, "/api/v1/sync/push", bytes.NewReader(body))
		reqOver.Header.Set("Authorization", "Bearer "+token)
		reqOver.Header.Set("Content-Type", "application/json")
		reqOver.Header.Set("X-Device-ID", testutil.DefaultDeviceID.String())
		reqOver.Header.Set("X-Timestamp", ts)
		reqOver.Header.Set("X-Signature", sig)
		recOver := httptest.NewRecorder()
		router.ServeHTTP(recOver, reqOver)

		assert.Equal(t, http.StatusTooManyRequests, recOver.Code)
		assert.NotEmpty(t, recOver.Header().Get("Retry-After"))
		var env httpAdapter.ErrorEnvelope
		require.NoError(t, json.Unmarshal(recOver.Body.Bytes(), &env))
		assert.Equal(t, "rate_limit_exceeded", env.Error.Code)
	})

	t.Run("rejects tampered HMAC signature with 401 before reaching sync handler", func(t *testing.T) {
		freshRouter := httpAdapter.SetupRouter(
			logger,
			&mocks.MockHealthService{Status: "ok"},
			"1.0.0",
			"test",
			httpAdapter.WithTokenManager(tokenMgr),
			httpAdapter.WithHMACSecretKey(hmacSecret),
			httpAdapter.WithSyncService(syncSvc),
		)

		body := []byte(`{"last_pulled_at":"2026-11-10T00:00:00Z"}`)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/sync/pull", bytes.NewReader(body))
		req.Header.Set("Authorization", "Bearer "+token)
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("X-Timestamp", time.Now().UTC().Format(time.RFC3339))
		req.Header.Set("X-Signature", "00000000000000000000000000000000")
		rec := httptest.NewRecorder()
		freshRouter.ServeHTTP(rec, req)

		assert.Equal(t, http.StatusUnauthorized, rec.Code)
	})
}
