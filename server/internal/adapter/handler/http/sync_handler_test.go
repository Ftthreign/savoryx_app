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
