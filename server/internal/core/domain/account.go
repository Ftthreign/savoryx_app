package domain

import (
	"time"

	"github.com/shopspring/decimal"
)

type AccountType string

const (
	AccountTypeCash       AccountType = "CASH"
	AccountTypeBank       AccountType = "BANK"
	AccountTypeEWallet    AccountType = "E_WALLET"
	AccountTypeCreditCard AccountType = "CREDIT_CARD"
	AccountTypeInvestment AccountType = "INVESTMENT"
	AccountTypeAsset      AccountType = "ASSET"
)

type Account struct {
	ID        UUID            `json:"id"`
	Name      string          `json:"name"`
	Type      AccountType     `json:"type"`
	Currency  string          `json:"currency"`
	Balance   decimal.Decimal `json:"balance"`
	CreatedAt time.Time       `json:"created_at"`
	UpdatedAt time.Time       `json:"updated_at"`
	DeletedAt *time.Time      `json:"deleted_at,omitempty"`
}
