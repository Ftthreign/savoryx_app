package http_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/ftthreign/savoryx_app/server/docs"
	httpAdapter "github.com/ftthreign/savoryx_app/server/internal/adapter/handler/http"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/testutil/mocks"
	"github.com/shopspring/decimal"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"go.yaml.in/yaml/v3"
)

func TestOpenAPISpecIntegrity(t *testing.T) {
	require.NotEmpty(t, docs.OpenAPISpec, "OpenAPI spec should not be empty")

	var spec map[string]any
	err := yaml.Unmarshal(docs.OpenAPISpec, &spec)
	require.NoError(t, err, "OpenAPI spec must be valid YAML")

	assert.Equal(t, "3.0.3", spec["openapi"])

	components, ok := spec["components"].(map[string]any)
	require.True(t, ok, "components section must exist")

	secSchemes, ok := components["securitySchemes"].(map[string]any)
	require.True(t, ok, "securitySchemes must exist")
	bearerAuth, ok := secSchemes["BearerAuth"].(map[string]any)
	require.True(t, ok, "BearerAuth security scheme must be defined")
	assert.Equal(t, "http", bearerAuth["type"])
	assert.Equal(t, "bearer", bearerAuth["scheme"])
	assert.Equal(t, "PASETO", bearerAuth["bearerFormat"])

	schemas, ok := components["schemas"].(map[string]any)
	require.True(t, ok, "schemas section must exist")

	// Verify required schemas exist
	assert.Contains(t, schemas, "PaginationMeta")
	assert.Contains(t, schemas, "ResponseEnvelope")
	assert.Contains(t, schemas, "ErrorEnvelope")
	assert.Contains(t, schemas, "AccountResponse")
	assert.Contains(t, schemas, "CategoryResponse")

	paths, ok := spec["paths"].(map[string]any)
	require.True(t, ok, "paths section must exist")

	// Verify Accounts collection path
	accountsPath, ok := paths["/api/v1/accounts"].(map[string]any)
	require.True(t, ok, "/api/v1/accounts path must be registered")
	accountsGet, ok := accountsPath["get"].(map[string]any)
	require.True(t, ok, "GET /api/v1/accounts must be defined")
	assert.Contains(t, accountsGet, "responses")

	// Verify Categories collection path
	categoriesPath, ok := paths["/api/v1/categories"].(map[string]any)
	require.True(t, ok, "/api/v1/categories path must be registered")
	categoriesGet, ok := categoriesPath["get"].(map[string]any)
	require.True(t, ok, "GET /api/v1/categories must be defined")
	assert.Contains(t, categoriesGet, "responses")
}

func TestContract_ListAccounts_ResponseEnvelope(t *testing.T) {
	now := time.Now().UTC()
	accounts := []*domain.Account{
		{
			ID:        domain.NewUUIDv7(),
			Name:      "BCA Primary Checking",
			Type:      domain.AccountTypeBank,
			Currency:  "IDR",
			Balance:   decimal.NewFromInt(15000000),
			CreatedAt: now,
			UpdatedAt: now,
		},
		{
			ID:        domain.NewUUIDv7(),
			Name:      "Cash Wallet",
			Type:      domain.AccountTypeCash,
			Currency:  "IDR",
			Balance:   decimal.NewFromInt(500000),
			CreatedAt: now,
			UpdatedAt: now,
		},
	}

	mockService := &mocks.MockAccountService{
		ListAccountsFunc: func(ctx context.Context) ([]*domain.Account, error) {
			return accounts, nil
		},
	}

	handler := httpAdapter.NewAccountHandler(mockService)
	req := httptest.NewRequest(http.MethodGet, "/api/v1/accounts", nil)
	rec := httptest.NewRecorder()

	handler.ListAccounts(rec, req)

	require.Equal(t, http.StatusOK, rec.Code)
	assert.Contains(t, rec.Header().Get("Content-Type"), "application/json")

	var body struct {
		Data []struct {
			ID       string `json:"id"`
			Name     string `json:"name"`
			Type     string `json:"type"`
			Currency string `json:"currency"`
			Balance  string `json:"balance"`
		} `json:"data"`
		Meta struct {
			Total  int `json:"total"`
			Limit  int `json:"limit"`
			Offset int `json:"offset"`
		} `json:"meta"`
	}

	err := json.Unmarshal(rec.Body.Bytes(), &body)
	require.NoError(t, err, "Response must deserialize into collection envelope with meta")

	assert.Len(t, body.Data, 2)
	assert.Equal(t, 2, body.Meta.Total)
	assert.Equal(t, 50, body.Meta.Limit)
	assert.Equal(t, 0, body.Meta.Offset)
	assert.Equal(t, "BCA Primary Checking", body.Data[0].Name)
	assert.Equal(t, "15000000.00", body.Data[0].Balance)
}

func TestContract_ListCategories_ResponseEnvelope(t *testing.T) {
	now := time.Now().UTC()
	categories := []*domain.Category{
		{
			ID:        domain.NewUUIDv7(),
			Name:      "Food and Dining",
			Icon:      "fastfood",
			Color:     "#8DB355",
			IsWants:   false,
			CreatedAt: now,
			UpdatedAt: now,
		},
	}

	mockService := &mocks.MockCategoryService{
		ListCategoriesFunc: func(ctx context.Context) ([]*domain.Category, error) {
			return categories, nil
		},
	}

	handler := httpAdapter.NewCategoryHandler(mockService)
	req := httptest.NewRequest(http.MethodGet, "/api/v1/categories", nil)
	rec := httptest.NewRecorder()

	handler.ListCategories(rec, req)

	require.Equal(t, http.StatusOK, rec.Code)
	assert.Contains(t, rec.Header().Get("Content-Type"), "application/json")

	var body struct {
		Data []struct {
			ID      string `json:"id"`
			Name    string `json:"name"`
			Icon    string `json:"icon"`
			Color   string `json:"color"`
			IsWants bool   `json:"is_wants"`
		} `json:"data"`
		Meta struct {
			Total  int `json:"total"`
			Limit  int `json:"limit"`
			Offset int `json:"offset"`
		} `json:"meta"`
	}

	err := json.Unmarshal(rec.Body.Bytes(), &body)
	require.NoError(t, err, "Response must deserialize into collection envelope with meta")

	assert.Len(t, body.Data, 1)
	assert.Equal(t, 1, body.Meta.Total)
	assert.Equal(t, 50, body.Meta.Limit)
	assert.Equal(t, 0, body.Meta.Offset)
	assert.Equal(t, "Food and Dining", body.Data[0].Name)
	assert.False(t, body.Data[0].IsWants)
}
