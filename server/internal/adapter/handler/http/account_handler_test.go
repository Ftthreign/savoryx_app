package http_test

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	httpAdapter "github.com/ftthreign/savoryx_app/server/internal/adapter/handler/http"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/testutil/mocks"
	"github.com/go-chi/chi/v5"
	"github.com/shopspring/decimal"
)

func TestAccountHandler_CreateAccount(t *testing.T) {
	t.Parallel()

	t.Run("success returns 201 Created with Location header", func(t *testing.T) {
		t.Parallel()

		mockService := &mocks.MockAccountService{
			CreateAccountFunc: func(ctx context.Context, acc *domain.Account) error {
				acc.CreatedAt = time.Now().UTC()
				acc.UpdatedAt = time.Now().UTC()
				return nil
			},
		}

		handler := httpAdapter.NewAccountHandler(mockService)

		body := map[string]any{
			"name":     "Bank BCA",
			"type":     "BANK",
			"currency": "IDR",
			"balance":  "5000000.00",
		}
		jsonBytes, _ := json.Marshal(body)

		req := httptest.NewRequest(http.MethodPost, "/api/v1/accounts", bytes.NewReader(jsonBytes))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()

		handler.CreateAccount(rec, req)

		if rec.Code != http.StatusCreated {
			t.Fatalf("expected status 201, got %d. Body: %s", rec.Code, rec.Body.String())
		}

		location := rec.Header().Get("Location")
		if location == "" {
			t.Error("expected non-empty Location header")
		}

		var resp struct {
			Data struct {
				ID       string `json:"id"`
				Name     string `json:"name"`
				Type     string `json:"type"`
				Balance  string `json:"balance"`
				Currency string `json:"currency"`
			} `json:"data"`
		}
		if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
			t.Fatalf("failed to decode response: %v", err)
		}
		if resp.Data.Name != "Bank BCA" || resp.Data.Balance != "5000000.00" {
			t.Errorf("unexpected payload content: %+v", resp.Data)
		}
	})

	t.Run("returns 400 on malformed json", func(t *testing.T) {
		t.Parallel()

		mockService := &mocks.MockAccountService{}
		handler := httpAdapter.NewAccountHandler(mockService)

		req := httptest.NewRequest(http.MethodPost, "/api/v1/accounts", bytes.NewReader([]byte("{invalid-json")))
		rec := httptest.NewRecorder()

		handler.CreateAccount(rec, req)

		if rec.Code != http.StatusBadRequest {
			t.Fatalf("expected status 400, got %d", rec.Code)
		}
	})

	t.Run("returns 400 on invalid account type", func(t *testing.T) {
		t.Parallel()

		mockService := &mocks.MockAccountService{}
		handler := httpAdapter.NewAccountHandler(mockService)

		body := map[string]any{
			"name": "Invalid Type Acc",
			"type": "BITCOIN",
		}
		jsonBytes, _ := json.Marshal(body)

		req := httptest.NewRequest(http.MethodPost, "/api/v1/accounts", bytes.NewReader(jsonBytes))
		rec := httptest.NewRecorder()

		handler.CreateAccount(rec, req)

		if rec.Code != http.StatusBadRequest {
			t.Fatalf("expected status 400, got %d", rec.Code)
		}
	})
}

func TestAccountHandler_ListAccounts(t *testing.T) {
	t.Parallel()

	t.Run("success returns list of accounts", func(t *testing.T) {
		t.Parallel()

		testAccounts := []*domain.Account{
			{
				ID:        domain.NewUUIDv7(),
				Name:      "BCA Primary",
				Type:      domain.AccountTypeBank,
				Currency:  "IDR",
				Balance:   decimal.NewFromInt(1000000),
				CreatedAt: time.Now().UTC(),
				UpdatedAt: time.Now().UTC(),
			},
		}

		mockService := &mocks.MockAccountService{
			ListAccountsFunc: func(ctx context.Context) ([]*domain.Account, error) {
				return testAccounts, nil
			},
		}

		handler := httpAdapter.NewAccountHandler(mockService)

		req := httptest.NewRequest(http.MethodGet, "/api/v1/accounts", nil)
		rec := httptest.NewRecorder()

		handler.ListAccounts(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected status 200, got %d", rec.Code)
		}

		var resp struct {
			Data []map[string]any `json:"data"`
		}
		if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
			t.Fatalf("failed to decode response: %v", err)
		}
		if len(resp.Data) != 1 {
			t.Fatalf("expected 1 account, got %d", len(resp.Data))
		}
	})
}

func TestAccountHandler_GetAccount(t *testing.T) {
	t.Parallel()

	targetID := domain.NewUUIDv7()

	t.Run("success returns single account", func(t *testing.T) {
		t.Parallel()

		mockService := &mocks.MockAccountService{
			GetAccountFunc: func(ctx context.Context, id domain.UUID) (*domain.Account, error) {
				if id == targetID {
					return &domain.Account{
						ID:        targetID,
						Name:      "Cash Dompet",
						Type:      domain.AccountTypeCash,
						Currency:  "IDR",
						Balance:   decimal.NewFromInt(250000),
						CreatedAt: time.Now().UTC(),
						UpdatedAt: time.Now().UTC(),
					}, nil
				}
				return nil, domain.ErrAccountNotFound
			},
		}

		handler := httpAdapter.NewAccountHandler(mockService)

		r := chi.NewRouter()
		r.Get("/api/v1/accounts/{id}", handler.GetAccount)

		req := httptest.NewRequest(http.MethodGet, "/api/v1/accounts/"+targetID.String(), nil)
		rec := httptest.NewRecorder()

		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected status 200, got %d", rec.Code)
		}
	})

	t.Run("returns 400 on invalid UUID string", func(t *testing.T) {
		t.Parallel()

		mockService := &mocks.MockAccountService{}
		handler := httpAdapter.NewAccountHandler(mockService)

		r := chi.NewRouter()
		r.Get("/api/v1/accounts/{id}", handler.GetAccount)

		req := httptest.NewRequest(http.MethodGet, "/api/v1/accounts/not-a-uuid", nil)
		rec := httptest.NewRecorder()

		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusBadRequest {
			t.Fatalf("expected status 400, got %d", rec.Code)
		}
	})

	t.Run("returns 404 when account not found", func(t *testing.T) {
		t.Parallel()

		mockService := &mocks.MockAccountService{
			GetAccountFunc: func(ctx context.Context, id domain.UUID) (*domain.Account, error) {
				return nil, domain.ErrAccountNotFound
			},
		}

		handler := httpAdapter.NewAccountHandler(mockService)

		r := chi.NewRouter()
		r.Get("/api/v1/accounts/{id}", handler.GetAccount)

		req := httptest.NewRequest(http.MethodGet, "/api/v1/accounts/"+domain.NewUUIDv7().String(), nil)
		rec := httptest.NewRecorder()

		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusNotFound {
			t.Fatalf("expected status 404, got %d", rec.Code)
		}
	})
}

func TestAccountHandler_UpdateBalance(t *testing.T) {
	t.Parallel()

	targetID := domain.NewUUIDv7()

	t.Run("success updates balance and returns updated account", func(t *testing.T) {
		t.Parallel()

		mockService := &mocks.MockAccountService{
			UpdateBalanceFunc: func(ctx context.Context, id domain.UUID, newBalance decimal.Decimal) error {
				return nil
			},
			GetAccountFunc: func(ctx context.Context, id domain.UUID) (*domain.Account, error) {
				return &domain.Account{
					ID:        targetID,
					Name:      "BCA Primary",
					Type:      domain.AccountTypeBank,
					Currency:  "IDR",
					Balance:   decimal.NewFromInt(7500000),
					CreatedAt: time.Now().UTC(),
					UpdatedAt: time.Now().UTC(),
				}, nil
			},
		}

		handler := httpAdapter.NewAccountHandler(mockService)

		r := chi.NewRouter()
		r.Put("/api/v1/accounts/{id}/balance", handler.UpdateBalance)

		body := map[string]any{"balance": "7500000.00"}
		jsonBytes, _ := json.Marshal(body)

		req := httptest.NewRequest(http.MethodPut, "/api/v1/accounts/"+targetID.String()+"/balance", bytes.NewReader(jsonBytes))
		rec := httptest.NewRecorder()

		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected status 200, got %d. Body: %s", rec.Code, rec.Body.String())
		}
	})
}

func TestAccountHandler_UpdateAccount(t *testing.T) {
	t.Parallel()

	targetID := domain.NewUUIDv7()

	t.Run("success updates account name and type", func(t *testing.T) {
		t.Parallel()

		mockService := &mocks.MockAccountService{
			UpdateAccountFunc: func(ctx context.Context, id domain.UUID, name string, accType domain.AccountType) (*domain.Account, error) {
				return &domain.Account{
					ID:        targetID,
					Name:      name,
					Type:      accType,
					Currency:  "IDR",
					Balance:   decimal.NewFromInt(10000000),
					CreatedAt: time.Now().UTC(),
					UpdatedAt: time.Now().UTC(),
				}, nil
			},
		}

		handler := httpAdapter.NewAccountHandler(mockService)

		r := chi.NewRouter()
		r.Put("/api/v1/accounts/{id}", handler.UpdateAccount)

		body := map[string]any{
			"name": "BCA Bisnis",
			"type": "BANK",
		}
		jsonBytes, _ := json.Marshal(body)

		req := httptest.NewRequest(http.MethodPut, "/api/v1/accounts/"+targetID.String(), bytes.NewReader(jsonBytes))
		rec := httptest.NewRecorder()

		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected status 200, got %d. Body: %s", rec.Code, rec.Body.String())
		}

		var resp struct {
			Data struct {
				Name string `json:"name"`
				Type string `json:"type"`
			} `json:"data"`
		}
		if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
			t.Fatalf("failed to decode response: %v", err)
		}
		if resp.Data.Name != "BCA Bisnis" || resp.Data.Type != "BANK" {
			t.Errorf("unexpected updated data: %+v", resp.Data)
		}
	})

	t.Run("returns 400 on invalid UUID", func(t *testing.T) {
		t.Parallel()

		mockService := &mocks.MockAccountService{}
		handler := httpAdapter.NewAccountHandler(mockService)

		r := chi.NewRouter()
		r.Put("/api/v1/accounts/{id}", handler.UpdateAccount)

		req := httptest.NewRequest(http.MethodPut, "/api/v1/accounts/not-a-uuid", bytes.NewReader([]byte("{}")))
		rec := httptest.NewRecorder()

		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusBadRequest {
			t.Fatalf("expected status 400, got %d", rec.Code)
		}
	})

	t.Run("returns 400 on validation error", func(t *testing.T) {
		t.Parallel()

		mockService := &mocks.MockAccountService{}
		handler := httpAdapter.NewAccountHandler(mockService)

		r := chi.NewRouter()
		r.Put("/api/v1/accounts/{id}", handler.UpdateAccount)

		body := map[string]any{"name": "", "type": "INVALID"}
		jsonBytes, _ := json.Marshal(body)

		req := httptest.NewRequest(http.MethodPut, "/api/v1/accounts/"+targetID.String(), bytes.NewReader(jsonBytes))
		rec := httptest.NewRecorder()

		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusBadRequest {
			t.Fatalf("expected status 400, got %d", rec.Code)
		}
	})

	t.Run("returns 404 when account not found", func(t *testing.T) {
		t.Parallel()

		mockService := &mocks.MockAccountService{
			UpdateAccountFunc: func(ctx context.Context, id domain.UUID, name string, accType domain.AccountType) (*domain.Account, error) {
				return nil, domain.ErrAccountNotFound
			},
		}

		handler := httpAdapter.NewAccountHandler(mockService)

		r := chi.NewRouter()
		r.Put("/api/v1/accounts/{id}", handler.UpdateAccount)

		body := map[string]any{"name": "BCA Bisnis", "type": "BANK"}
		jsonBytes, _ := json.Marshal(body)

		req := httptest.NewRequest(http.MethodPut, "/api/v1/accounts/"+targetID.String(), bytes.NewReader(jsonBytes))
		rec := httptest.NewRecorder()

		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusNotFound {
			t.Fatalf("expected status 404, got %d", rec.Code)
		}
	})
}

func TestAccountHandler_DeleteAccount(t *testing.T) {
	t.Parallel()

	targetID := domain.NewUUIDv7()

	t.Run("success returns 204 No Content", func(t *testing.T) {
		t.Parallel()

		mockService := &mocks.MockAccountService{
			DeleteAccountFunc: func(ctx context.Context, id domain.UUID) error {
				return nil
			},
		}

		handler := httpAdapter.NewAccountHandler(mockService)

		r := chi.NewRouter()
		r.Delete("/api/v1/accounts/{id}", handler.DeleteAccount)

		req := httptest.NewRequest(http.MethodDelete, "/api/v1/accounts/"+targetID.String(), nil)
		rec := httptest.NewRecorder()

		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusNoContent {
			t.Fatalf("expected status 204, got %d", rec.Code)
		}
	})
}
