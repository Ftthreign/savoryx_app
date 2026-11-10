package dto

import (
	"fmt"
	"strings"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/shopspring/decimal"
)

type CreateTransactionRequest struct {
	ID                   string `json:"id,omitempty"`
	AccountID            string `json:"account_id"`
	CategoryID           string `json:"category_id,omitempty"`
	DestinationAccountID string `json:"destination_account_id,omitempty"`
	Type                 string `json:"type"`
	Amount               string `json:"amount"`
	Currency             string `json:"currency,omitempty"`
	ExchangeRateToBase   string `json:"exchange_rate_to_base,omitempty"`
	BaseAmount           string `json:"base_amount,omitempty"`
	Note                 string `json:"note,omitempty"`
	IsTalangan           bool   `json:"is_talangan,omitempty"`
	TransactionDate      string `json:"transaction_date,omitempty"`
}

func (r *CreateTransactionRequest) Validate() (*domain.Transaction, error) {
	var txID domain.UUID
	trimmedID := strings.TrimSpace(r.ID)
	if trimmedID != "" {
		parsedID, err := domain.ParseUUID(trimmedID)
		if err != nil {
			return nil, fmt.Errorf("invalid id format: %w", err)
		}
		txID = parsedID
	} else {
		txID = domain.NewUUIDv7()
	}

	accountID, err := domain.ParseUUID(strings.TrimSpace(r.AccountID))
	if err != nil {
		return nil, fmt.Errorf("invalid account_id format: %w", err)
	}

	var categoryID *domain.UUID
	if trimmedCat := strings.TrimSpace(r.CategoryID); trimmedCat != "" {
		parsedCat, err := domain.ParseUUID(trimmedCat)
		if err != nil {
			return nil, fmt.Errorf("invalid category_id format: %w", err)
		}
		categoryID = &parsedCat
	}

	var destAccountID *domain.UUID
	if trimmedDest := strings.TrimSpace(r.DestinationAccountID); trimmedDest != "" {
		parsedDest, err := domain.ParseUUID(trimmedDest)
		if err != nil {
			return nil, fmt.Errorf("invalid destination_account_id format: %w", err)
		}
		destAccountID = &parsedDest
	}

	txType := domain.TransactionType(strings.ToUpper(strings.TrimSpace(r.Type)))
	if !txType.IsValid() {
		return nil, fmt.Errorf("invalid transaction type %q", r.Type)
	}

	amountStr := strings.TrimSpace(r.Amount)
	if amountStr == "" {
		return nil, fmt.Errorf("amount is required")
	}
	amount, err := decimal.NewFromString(amountStr)
	if err != nil || !amount.GreaterThan(decimal.Zero) {
		return nil, fmt.Errorf("amount must be a positive decimal string")
	}

	currency := strings.ToUpper(strings.TrimSpace(r.Currency))
	if currency == "" {
		currency = "IDR"
	}
	if len(currency) != 3 {
		return nil, fmt.Errorf("currency must be a 3-letter ISO code")
	}

	rate := decimal.NewFromInt(1)
	if rateStr := strings.TrimSpace(r.ExchangeRateToBase); rateStr != "" {
		parsedRate, err := decimal.NewFromString(rateStr)
		if err != nil || !parsedRate.GreaterThan(decimal.Zero) {
			return nil, fmt.Errorf("exchange_rate_to_base must be a positive decimal string")
		}
		rate = parsedRate
	}

	baseAmount := amount.Mul(rate).Round(4)
	if baseStr := strings.TrimSpace(r.BaseAmount); baseStr != "" {
		parsedBase, err := decimal.NewFromString(baseStr)
		if err != nil || !parsedBase.GreaterThan(decimal.Zero) {
			return nil, fmt.Errorf("base_amount must be a positive decimal string")
		}
		baseAmount = parsedBase
	}

	now := time.Now().UTC()
	txDate := now
	if dateStr := strings.TrimSpace(r.TransactionDate); dateStr != "" {
		parsedDate, err := parseRFC3339Time(dateStr)
		if err != nil {
			return nil, fmt.Errorf("invalid transaction_date format (expected RFC3339): %w", err)
		}
		txDate = parsedDate
	}

	tx := &domain.Transaction{
		ID:                   txID,
		AccountID:            accountID,
		CategoryID:           categoryID,
		DestinationAccountID: destAccountID,
		Type:                 txType,
		Amount:               amount,
		Currency:             currency,
		ExchangeRateToBase:   rate,
		BaseAmount:           baseAmount,
		Note:                 strings.TrimSpace(r.Note),
		IsTalangan:           r.IsTalangan,
		TransactionDate:      txDate,
		CreatedAt:            now,
		UpdatedAt:            now,
	}

	if err := tx.Validate(); err != nil {
		return nil, err
	}

	return tx, nil
}

type TransactionResponse struct {
	ID                   string     `json:"id"`
	AccountID            string     `json:"account_id"`
	CategoryID           *string    `json:"category_id,omitempty"`
	DestinationAccountID *string    `json:"destination_account_id,omitempty"`
	Type                 string     `json:"type"`
	Amount               string     `json:"amount"`
	Currency             string     `json:"currency"`
	ExchangeRateToBase   string     `json:"exchange_rate_to_base"`
	BaseAmount           string     `json:"base_amount"`
	Note                 string     `json:"note"`
	IsTalangan           bool       `json:"is_talangan"`
	TransactionDate      time.Time  `json:"transaction_date"`
	CreatedAt            time.Time  `json:"created_at"`
	UpdatedAt            time.Time  `json:"updated_at"`
	DeletedAt            *time.Time `json:"deleted_at,omitempty"`
}

func ToTransactionResponse(tx *domain.Transaction) TransactionResponse {
	var catID *string
	if tx.CategoryID != nil && !tx.CategoryID.IsZero() {
		s := tx.CategoryID.String()
		catID = &s
	}

	var destID *string
	if tx.DestinationAccountID != nil && !tx.DestinationAccountID.IsZero() {
		s := tx.DestinationAccountID.String()
		destID = &s
	}

	return TransactionResponse{
		ID:                   tx.ID.String(),
		AccountID:            tx.AccountID.String(),
		CategoryID:           catID,
		DestinationAccountID: destID,
		Type:                 string(tx.Type),
		Amount:               tx.Amount.StringFixed(2),
		Currency:             tx.Currency,
		ExchangeRateToBase:   tx.ExchangeRateToBase.StringFixed(6),
		BaseAmount:           tx.BaseAmount.StringFixed(2),
		Note:                 tx.Note,
		IsTalangan:           tx.IsTalangan,
		TransactionDate:      tx.TransactionDate,
		CreatedAt:            tx.CreatedAt,
		UpdatedAt:            tx.UpdatedAt,
		DeletedAt:            tx.DeletedAt,
	}
}

func ToTransactionResponseList(txs []*domain.Transaction) []TransactionResponse {
	result := make([]TransactionResponse, len(txs))
	for i, tx := range txs {
		result[i] = ToTransactionResponse(tx)
	}
	return result
}

func parseRFC3339Time(s string) (time.Time, error) {
	if t, err := time.Parse(time.RFC3339Nano, s); err == nil {
		return t.UTC(), nil
	}
	t, err := time.Parse(time.RFC3339, s)
	if err != nil {
		return time.Time{}, err
	}
	return t.UTC(), nil
}
