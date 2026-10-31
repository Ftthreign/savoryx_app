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
)

func TestCategoryHandler_CreateCategory(t *testing.T) {
	t.Parallel()

	t.Run("success returns 201 Created with Location header", func(t *testing.T) {
		t.Parallel()

		mockService := &mocks.MockCategoryService{
			CreateCategoryFunc: func(ctx context.Context, cat *domain.Category) error {
				cat.CreatedAt = time.Now().UTC()
				cat.UpdatedAt = time.Now().UTC()
				return nil
			},
		}

		handler := httpAdapter.NewCategoryHandler(mockService)

		body := map[string]any{
			"name":     "Makanan & Minuman",
			"icon":     "utensils",
			"color":    "#FF5733",
			"is_wants": false,
		}
		jsonBytes, _ := json.Marshal(body)

		req := httptest.NewRequest(http.MethodPost, "/api/v1/categories", bytes.NewReader(jsonBytes))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()

		handler.CreateCategory(rec, req)

		if rec.Code != http.StatusCreated {
			t.Fatalf("expected status 201, got %d. Body: %s", rec.Code, rec.Body.String())
		}

		location := rec.Header().Get("Location")
		if location == "" {
			t.Error("expected non-empty Location header")
		}

		var resp struct {
			Data struct {
				ID      string `json:"id"`
				Name    string `json:"name"`
				Icon    string `json:"icon"`
				Color   string `json:"color"`
				IsWants bool   `json:"is_wants"`
			} `json:"data"`
		}
		if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
			t.Fatalf("failed to decode response: %v", err)
		}
		if resp.Data.Name != "Makanan & Minuman" || resp.Data.IsWants != false {
			t.Errorf("unexpected payload content: %+v", resp.Data)
		}
	})

	t.Run("returns 400 on malformed json", func(t *testing.T) {
		t.Parallel()

		mockService := &mocks.MockCategoryService{}
		handler := httpAdapter.NewCategoryHandler(mockService)

		req := httptest.NewRequest(http.MethodPost, "/api/v1/categories", bytes.NewReader([]byte("{bad-json")))
		rec := httptest.NewRecorder()

		handler.CreateCategory(rec, req)

		if rec.Code != http.StatusBadRequest {
			t.Fatalf("expected status 400, got %d", rec.Code)
		}
	})

	t.Run("returns 400 on empty category name", func(t *testing.T) {
		t.Parallel()

		mockService := &mocks.MockCategoryService{}
		handler := httpAdapter.NewCategoryHandler(mockService)

		body := map[string]any{
			"name":  "",
			"icon":  "utensils",
			"color": "#FF5733",
		}
		jsonBytes, _ := json.Marshal(body)

		req := httptest.NewRequest(http.MethodPost, "/api/v1/categories", bytes.NewReader(jsonBytes))
		rec := httptest.NewRecorder()

		handler.CreateCategory(rec, req)

		if rec.Code != http.StatusBadRequest {
			t.Fatalf("expected status 400, got %d", rec.Code)
		}
	})
}

func TestCategoryHandler_ListCategories(t *testing.T) {
	t.Parallel()

	t.Run("success returns list of categories", func(t *testing.T) {
		t.Parallel()

		testCategories := []*domain.Category{
			{
				ID:        domain.NewUUIDv7(),
				Name:      "Gaji & Pendapatan",
				Icon:      "wallet",
				Color:     "#2ECC71",
				IsWants:   false,
				CreatedAt: time.Now().UTC(),
				UpdatedAt: time.Now().UTC(),
			},
		}

		mockService := &mocks.MockCategoryService{
			ListCategoriesFunc: func(ctx context.Context) ([]*domain.Category, error) {
				return testCategories, nil
			},
		}

		handler := httpAdapter.NewCategoryHandler(mockService)

		req := httptest.NewRequest(http.MethodGet, "/api/v1/categories", nil)
		rec := httptest.NewRecorder()

		handler.ListCategories(rec, req)

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
			t.Fatalf("expected 1 category, got %d", len(resp.Data))
		}
	})
}

func TestCategoryHandler_GetCategory(t *testing.T) {
	t.Parallel()

	targetID := domain.NewUUIDv7()

	t.Run("success returns single category", func(t *testing.T) {
		t.Parallel()

		mockService := &mocks.MockCategoryService{
			GetCategoryFunc: func(ctx context.Context, id domain.UUID) (*domain.Category, error) {
				if id == targetID {
					return &domain.Category{
						ID:        targetID,
						Name:      "Hobi & Hiburan",
						Icon:      "gamepad",
						Color:     "#9B59B6",
						IsWants:   true,
						CreatedAt: time.Now().UTC(),
						UpdatedAt: time.Now().UTC(),
					}, nil
				}
				return nil, domain.ErrCategoryNotFound
			},
		}

		handler := httpAdapter.NewCategoryHandler(mockService)

		r := chi.NewRouter()
		r.Get("/api/v1/categories/{id}", handler.GetCategory)

		req := httptest.NewRequest(http.MethodGet, "/api/v1/categories/"+targetID.String(), nil)
		rec := httptest.NewRecorder()

		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected status 200, got %d", rec.Code)
		}
	})

	t.Run("returns 400 on invalid UUID string", func(t *testing.T) {
		t.Parallel()

		mockService := &mocks.MockCategoryService{}
		handler := httpAdapter.NewCategoryHandler(mockService)

		r := chi.NewRouter()
		r.Get("/api/v1/categories/{id}", handler.GetCategory)

		req := httptest.NewRequest(http.MethodGet, "/api/v1/categories/invalid-uuid", nil)
		rec := httptest.NewRecorder()

		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusBadRequest {
			t.Fatalf("expected status 400, got %d", rec.Code)
		}
	})

	t.Run("returns 404 when category not found", func(t *testing.T) {
		t.Parallel()

		mockService := &mocks.MockCategoryService{
			GetCategoryFunc: func(ctx context.Context, id domain.UUID) (*domain.Category, error) {
				return nil, domain.ErrCategoryNotFound
			},
		}

		handler := httpAdapter.NewCategoryHandler(mockService)

		r := chi.NewRouter()
		r.Get("/api/v1/categories/{id}", handler.GetCategory)

		req := httptest.NewRequest(http.MethodGet, "/api/v1/categories/"+domain.NewUUIDv7().String(), nil)
		rec := httptest.NewRecorder()

		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusNotFound {
			t.Fatalf("expected status 404, got %d", rec.Code)
		}
	})
}

func TestCategoryHandler_UpdateCategory(t *testing.T) {
	t.Parallel()

	targetID := domain.NewUUIDv7()

	t.Run("success updates category properties", func(t *testing.T) {
		t.Parallel()

		mockService := &mocks.MockCategoryService{
			UpdateCategoryFunc: func(ctx context.Context, id domain.UUID, name, icon, color string, isWants bool) (*domain.Category, error) {
				return &domain.Category{
					ID:        targetID,
					Name:      name,
					Icon:      icon,
					Color:     color,
					IsWants:   isWants,
					CreatedAt: time.Now().UTC(),
					UpdatedAt: time.Now().UTC(),
				}, nil
			},
		}

		handler := httpAdapter.NewCategoryHandler(mockService)

		r := chi.NewRouter()
		r.Put("/api/v1/categories/{id}", handler.UpdateCategory)

		body := map[string]any{
			"name":     "Kuliner Lezat",
			"icon":     "coffee",
			"color":    "#F39C12",
			"is_wants": true,
		}
		jsonBytes, _ := json.Marshal(body)

		req := httptest.NewRequest(http.MethodPut, "/api/v1/categories/"+targetID.String(), bytes.NewReader(jsonBytes))
		rec := httptest.NewRecorder()

		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected status 200, got %d. Body: %s", rec.Code, rec.Body.String())
		}

		var resp struct {
			Data struct {
				Name    string `json:"name"`
				Icon    string `json:"icon"`
				Color   string `json:"color"`
				IsWants bool   `json:"is_wants"`
			} `json:"data"`
		}
		if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
			t.Fatalf("failed to decode response: %v", err)
		}
		if resp.Data.Name != "Kuliner Lezat" || resp.Data.Color != "#F39C12" || resp.Data.IsWants != true {
			t.Errorf("unexpected updated data: %+v", resp.Data)
		}
	})

	t.Run("returns 400 on invalid UUID", func(t *testing.T) {
		t.Parallel()

		mockService := &mocks.MockCategoryService{}
		handler := httpAdapter.NewCategoryHandler(mockService)

		r := chi.NewRouter()
		r.Put("/api/v1/categories/{id}", handler.UpdateCategory)

		req := httptest.NewRequest(http.MethodPut, "/api/v1/categories/not-a-uuid", bytes.NewReader([]byte("{}")))
		rec := httptest.NewRecorder()

		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusBadRequest {
			t.Fatalf("expected status 400, got %d", rec.Code)
		}
	})

	t.Run("returns 400 on validation error", func(t *testing.T) {
		t.Parallel()

		mockService := &mocks.MockCategoryService{}
		handler := httpAdapter.NewCategoryHandler(mockService)

		r := chi.NewRouter()
		r.Put("/api/v1/categories/{id}", handler.UpdateCategory)

		body := map[string]any{"name": "", "icon": ""}
		jsonBytes, _ := json.Marshal(body)

		req := httptest.NewRequest(http.MethodPut, "/api/v1/categories/"+targetID.String(), bytes.NewReader(jsonBytes))
		rec := httptest.NewRecorder()

		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusBadRequest {
			t.Fatalf("expected status 400, got %d", rec.Code)
		}
	})

	t.Run("returns 404 when category not found", func(t *testing.T) {
		t.Parallel()

		mockService := &mocks.MockCategoryService{
			UpdateCategoryFunc: func(ctx context.Context, id domain.UUID, name, icon, color string, isWants bool) (*domain.Category, error) {
				return nil, domain.ErrCategoryNotFound
			},
		}

		handler := httpAdapter.NewCategoryHandler(mockService)

		r := chi.NewRouter()
		r.Put("/api/v1/categories/{id}", handler.UpdateCategory)

		body := map[string]any{
			"name":     "Kuliner",
			"icon":     "coffee",
			"color":    "#F39C12",
			"is_wants": true,
		}
		jsonBytes, _ := json.Marshal(body)

		req := httptest.NewRequest(http.MethodPut, "/api/v1/categories/"+targetID.String(), bytes.NewReader(jsonBytes))
		rec := httptest.NewRecorder()

		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusNotFound {
			t.Fatalf("expected status 404, got %d", rec.Code)
		}
	})
}

func TestCategoryHandler_DeleteCategory(t *testing.T) {
	t.Parallel()

	targetID := domain.NewUUIDv7()

	t.Run("success returns 204 No Content", func(t *testing.T) {
		t.Parallel()

		mockService := &mocks.MockCategoryService{
			DeleteCategoryFunc: func(ctx context.Context, id domain.UUID) error {
				return nil
			},
		}

		handler := httpAdapter.NewCategoryHandler(mockService)

		r := chi.NewRouter()
		r.Delete("/api/v1/categories/{id}", handler.DeleteCategory)

		req := httptest.NewRequest(http.MethodDelete, "/api/v1/categories/"+targetID.String(), nil)
		rec := httptest.NewRecorder()

		r.ServeHTTP(rec, req)

		if rec.Code != http.StatusNoContent {
			t.Fatalf("expected status 204, got %d", rec.Code)
		}
	})
}
