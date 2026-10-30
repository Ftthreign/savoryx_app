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

type ThemePreference string

const (
	ThemePreferenceClayLight ThemePreference = "CLAY_LIGHT"
	ThemePreferenceClayDark  ThemePreference = "CLAY_DARK"
	ThemePreferenceOledBlack ThemePreference = "OLED_BLACK"
)

type FontFamilyType string

const (
	FontFamilyNunitoSans FontFamilyType = "NUNITO_SANS"
	FontFamilyInter      FontFamilyType = "INTER"
	FontFamilyPoppins    FontFamilyType = "POPPINS"
	FontFamilyUbuntu     FontFamilyType = "UBUNTU"
	FontFamilyChangaOne  FontFamilyType = "CHANGA_ONE"
	FontFamilyTiny5      FontFamilyType = "TINY5"
)

type Account struct {
	ID        [16]byte        `json:"id"`
	Name      string          `json:"name"`
	Type      AccountType     `json:"type"`
	Currency  string          `json:"currency"`
	Balance   decimal.Decimal `json:"balance"`
	CreatedAt time.Time       `json:"created_at"`
	UpdatedAt time.Time       `json:"updated_at"`
	DeletedAt *time.Time      `json:"deleted_at,omitempty"`
}

type Category struct {
	ID        [16]byte   `json:"id"`
	Name      string     `json:"name"`
	Icon      string     `json:"icon"`
	Color     string     `json:"color"`
	IsWants   bool       `json:"is_wants"`
	CreatedAt time.Time  `json:"created_at"`
	UpdatedAt time.Time  `json:"updated_at"`
	DeletedAt *time.Time `json:"deleted_at,omitempty"`
}

type UserPreference struct {
	ID               [16]byte        `json:"id"`
	Theme            ThemePreference `json:"theme"`
	FontFamily       FontFamilyType  `json:"font_family"`
	BaseCurrency     string          `json:"base_currency"`
	MonthlyWorkHours int             `json:"monthly_work_hours"`
	MonthlyIncomeNet decimal.Decimal `json:"monthly_income_net"`
	UpdatedAt        time.Time       `json:"updated_at"`
}
