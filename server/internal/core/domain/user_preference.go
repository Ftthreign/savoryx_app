package domain

import (
	"time"

	"github.com/shopspring/decimal"
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

type UserPreference struct {
	ID               UUID            `json:"id"`
	Theme            ThemePreference `json:"theme"`
	FontFamily       FontFamilyType  `json:"font_family"`
	BaseCurrency     string          `json:"base_currency"`
	MonthlyWorkHours int             `json:"monthly_work_hours"`
	MonthlyIncomeNet decimal.Decimal `json:"monthly_income_net"`
	UpdatedAt        time.Time       `json:"updated_at"`
}
