package dto

import (
	"fmt"
	"strings"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/shopspring/decimal"
)

type CreateAccountRequest struct {
	ID       string `json:"id,omitempty"`
	Name     string `json:"name"`
	Type     string `json:"type"`
	Currency string `json:"currency"`
	Balance  string `json:"balance"`
}

func (r *CreateAccountRequest) Validate() (*domain.Account, error) {
	trimmedName := strings.TrimSpace(r.Name)
	if trimmedName == "" {
		return nil, fmt.Errorf("name is required")
	}
	if len(trimmedName) > 64 {
		return nil, fmt.Errorf("name exceeds 64 characters")
	}

	accType := domain.AccountType(strings.ToUpper(strings.TrimSpace(r.Type)))
	if !accType.IsValid() {
		return nil, fmt.Errorf("invalid account type '%s'", r.Type)
	}

	currency := strings.ToUpper(strings.TrimSpace(r.Currency))
	if currency == "" {
		currency = "IDR"
	}
	if len(currency) != 3 {
		return nil, fmt.Errorf("currency must be a 3-letter ISO code")
	}

	balanceStr := strings.TrimSpace(r.Balance)
	if balanceStr == "" {
		balanceStr = "0"
	}
	balance, err := decimal.NewFromString(balanceStr)
	if err != nil {
		return nil, fmt.Errorf("invalid balance format: %w", err)
	}

	var accountID domain.UUID
	trimmedID := strings.TrimSpace(r.ID)
	if trimmedID != "" {
		parsedID, err := domain.ParseUUID(trimmedID)
		if err != nil {
			return nil, fmt.Errorf("invalid id format: %w", err)
		}
		accountID = parsedID
	} else {
		accountID = domain.NewUUIDv7()
	}

	return &domain.Account{
		ID:       accountID,
		Name:     trimmedName,
		Type:     accType,
		Currency: currency,
		Balance:  balance,
	}, nil
}

type UpdateAccountRequest struct {
	Name string `json:"name"`
	Type string `json:"type"`
}

func (r *UpdateAccountRequest) Validate() (string, domain.AccountType, error) {
	trimmedName := strings.TrimSpace(r.Name)
	if trimmedName == "" {
		return "", "", fmt.Errorf("name is required")
	}
	if len(trimmedName) > 64 {
		return "", "", fmt.Errorf("name exceeds 64 characters")
	}

	accType := domain.AccountType(strings.ToUpper(strings.TrimSpace(r.Type)))
	if !accType.IsValid() {
		return "", "", fmt.Errorf("invalid account type '%s'", r.Type)
	}

	return trimmedName, accType, nil
}

type UpdateBalanceRequest struct {
	Balance string `json:"balance"`
}

func (r *UpdateBalanceRequest) Validate() (decimal.Decimal, error) {
	balanceStr := strings.TrimSpace(r.Balance)
	if balanceStr == "" {
		return decimal.Zero, fmt.Errorf("balance is required")
	}

	balance, err := decimal.NewFromString(balanceStr)
	if err != nil {
		return decimal.Zero, fmt.Errorf("invalid balance format: %w", err)
	}

	return balance, nil
}

type AccountResponse struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	Type      string    `json:"type"`
	Currency  string    `json:"currency"`
	Balance   string    `json:"balance"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

func ToAccountResponse(acc *domain.Account) AccountResponse {
	return AccountResponse{
		ID:        acc.ID.String(),
		Name:      acc.Name,
		Type:      string(acc.Type),
		Currency:  acc.Currency,
		Balance:   acc.Balance.StringFixed(2),
		CreatedAt: acc.CreatedAt,
		UpdatedAt: acc.UpdatedAt,
	}
}

func ToAccountResponseList(accounts []*domain.Account) []AccountResponse {
	result := make([]AccountResponse, len(accounts))
	for i, acc := range accounts {
		result[i] = ToAccountResponse(acc)
	}
	return result
}
