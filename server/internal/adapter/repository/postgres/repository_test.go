package postgres

import (
	"testing"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/adapter/repository/postgres/db"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shopspring/decimal"
	"github.com/stretchr/testify/assert"
)

func TestToDomainAccount(t *testing.T) {
	now := time.Now().UTC()
	var testUUID [16]byte
	copy(testUUID[:], []byte("1234567890123456"))

	dbAcc := db.Account{
		ID:        pgtype.UUID{Bytes: testUUID, Valid: true},
		Name:      "BCA Primary Checking",
		Type:      db.AccountTypeBANK,
		Currency:  "IDR",
		Balance:   decimal.NewFromInt(15000000),
		CreatedAt: pgtype.Timestamptz{Time: now, Valid: true},
		UpdatedAt: pgtype.Timestamptz{Time: now, Valid: true},
		DeletedAt: pgtype.Timestamptz{Valid: false},
	}

	domainAcc := toDomainAccount(dbAcc)

	assert.NotNil(t, domainAcc)
	assert.Equal(t, testUUID, domainAcc.ID)
	assert.Equal(t, "BCA Primary Checking", domainAcc.Name)
	assert.Equal(t, domain.AccountTypeBank, domainAcc.Type)
	assert.Equal(t, "IDR", domainAcc.Currency)
	assert.True(t, domainAcc.Balance.Equal(decimal.NewFromInt(15000000)))
	assert.Equal(t, now, domainAcc.CreatedAt)
	assert.Nil(t, domainAcc.DeletedAt)

	// Test soft-deleted mapping
	dbAcc.DeletedAt = pgtype.Timestamptz{Time: now, Valid: true}
	deletedDomainAcc := toDomainAccount(dbAcc)
	assert.NotNil(t, deletedDomainAcc.DeletedAt)
	assert.Equal(t, now, *deletedDomainAcc.DeletedAt)
}

func TestToDomainCategory(t *testing.T) {
	now := time.Now().UTC()
	var testUUID [16]byte
	copy(testUUID[:], []byte("category12345678"))

	dbCat := db.Category{
		ID:        pgtype.UUID{Bytes: testUUID, Valid: true},
		Name:      "Food and Dining",
		Icon:      "fastfood",
		Color:     "#8DB355",
		IsWants:   false,
		CreatedAt: pgtype.Timestamptz{Time: now, Valid: true},
		UpdatedAt: pgtype.Timestamptz{Time: now, Valid: true},
		DeletedAt: pgtype.Timestamptz{Valid: false},
	}

	domainCat := toDomainCategory(dbCat)

	assert.NotNil(t, domainCat)
	assert.Equal(t, testUUID, domainCat.ID)
	assert.Equal(t, "Food and Dining", domainCat.Name)
	assert.Equal(t, "fastfood", domainCat.Icon)
	assert.Equal(t, "#8DB355", domainCat.Color)
	assert.False(t, domainCat.IsWants)
	assert.Nil(t, domainCat.DeletedAt)
}

func TestToDomainPreference(t *testing.T) {
	now := time.Now().UTC()
	var testUUID [16]byte
	copy(testUUID[:], []byte("pref123456789012"))

	dbPref := db.UserPreference{
		ID:               pgtype.UUID{Bytes: testUUID, Valid: true},
		Theme:            db.ThemePreferenceCLAYLIGHT,
		FontFamily:       db.FontFamilyTypeNUNITOSANS,
		BaseCurrency:     "IDR",
		MonthlyWorkHours: 160,
		MonthlyIncomeNet: decimal.NewFromInt(25000000),
		UpdatedAt:        pgtype.Timestamptz{Time: now, Valid: true},
	}

	domainPref := toDomainPreference(dbPref)

	assert.NotNil(t, domainPref)
	assert.Equal(t, testUUID, domainPref.ID)
	assert.Equal(t, domain.ThemePreferenceClayLight, domainPref.Theme)
	assert.Equal(t, domain.FontFamilyNunitoSans, domainPref.FontFamily)
	assert.Equal(t, "IDR", domainPref.BaseCurrency)
	assert.Equal(t, 160, domainPref.MonthlyWorkHours)
	assert.True(t, domainPref.MonthlyIncomeNet.Equal(decimal.NewFromInt(25000000)))
}
