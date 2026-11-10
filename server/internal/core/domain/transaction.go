package domain

import (
	"fmt"
	"strings"
	"time"

	"github.com/shopspring/decimal"
)

type TransactionType string

const (
	TransactionTypeIncome   TransactionType = "INCOME"
	TransactionTypeExpense  TransactionType = "EXPENSE"
	TransactionTypeTransfer TransactionType = "TRANSFER"
)

func (t TransactionType) IsValid() bool {
	switch t {
	case TransactionTypeIncome, TransactionTypeExpense, TransactionTypeTransfer:
		return true
	default:
		return false
	}
}

type Transaction struct {
	ID                   UUID            `json:"id"`
	AccountID            UUID            `json:"account_id"`
	CategoryID           *UUID           `json:"category_id,omitempty"`
	DestinationAccountID *UUID           `json:"destination_account_id,omitempty"`
	Type                 TransactionType `json:"type"`
	Amount               decimal.Decimal `json:"amount"`
	Currency             string          `json:"currency"`
	ExchangeRateToBase   decimal.Decimal `json:"exchange_rate_to_base"`
	BaseAmount           decimal.Decimal `json:"base_amount"`
	Note                 string          `json:"note"`
	IsTalangan           bool            `json:"is_talangan"`
	TransactionDate      time.Time       `json:"transaction_date"`
	CreatedAt            time.Time       `json:"created_at"`
	UpdatedAt            time.Time       `json:"updated_at"`
	DeletedAt            *time.Time      `json:"deleted_at,omitempty"`
}

func (tx *Transaction) Validate() error {
	if tx == nil {
		return fmt.Errorf("%w: transaction entity cannot be nil", ErrInvalidInput)
	}
	if tx.ID.IsZero() {
		return fmt.Errorf("%w: transaction ID cannot be zero", ErrInvalidInput)
	}
	if tx.AccountID.IsZero() {
		return fmt.Errorf("%w: account ID cannot be zero", ErrInvalidInput)
	}
	if !tx.Type.IsValid() {
		return fmt.Errorf("%w: invalid transaction type %q", ErrInvalidInput, tx.Type)
	}
	if !tx.Amount.GreaterThan(decimal.Zero) {
		return fmt.Errorf("%w: transaction amount must be greater than zero", ErrInvalidInput)
	}

	currency := strings.ToUpper(strings.TrimSpace(tx.Currency))
	if len(currency) != 3 {
		return fmt.Errorf("%w: currency must be a 3-character ISO-4217 code", ErrInvalidInput)
	}

	if !tx.ExchangeRateToBase.GreaterThan(decimal.Zero) {
		return fmt.Errorf("%w: exchange rate to base must be greater than zero", ErrInvalidInput)
	}
	if !tx.BaseAmount.GreaterThan(decimal.Zero) {
		return fmt.Errorf("%w: base amount must be greater than zero", ErrInvalidInput)
	}
	if tx.TransactionDate.IsZero() {
		return fmt.Errorf("%w: transaction date cannot be zero", ErrInvalidInput)
	}

	if tx.Type == TransactionTypeTransfer {
		if tx.DestinationAccountID == nil || tx.DestinationAccountID.IsZero() {
			return fmt.Errorf("%w: transfer transaction requires a valid destination account ID", ErrInvalidInput)
		}
		if *tx.DestinationAccountID == tx.AccountID {
			return fmt.Errorf("%w: destination account ID must differ from source account ID", ErrInvalidInput)
		}
	} else {
		if tx.CategoryID == nil || tx.CategoryID.IsZero() {
			return fmt.Errorf("%w: %s transaction requires a valid category ID", ErrInvalidInput, tx.Type)
		}
	}

	return nil
}
