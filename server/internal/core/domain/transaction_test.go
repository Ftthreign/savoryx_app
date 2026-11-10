package domain_test

import (
	"errors"
	"testing"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/shopspring/decimal"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestTransactionType_IsValid(t *testing.T) {
	assert.True(t, domain.TransactionTypeIncome.IsValid())
	assert.True(t, domain.TransactionTypeExpense.IsValid())
	assert.True(t, domain.TransactionTypeTransfer.IsValid())
	assert.False(t, domain.TransactionType("REFUND").IsValid())
	assert.False(t, domain.TransactionType("").IsValid())
}

func TestTransaction_Validate(t *testing.T) {
	now := time.Now().UTC()
	txID := domain.NewUUIDv7()
	accID := domain.NewUUIDv7()
	destAccID := domain.NewUUIDv7()
	catID := domain.NewUUIDv7()

	validExpense := func() *domain.Transaction {
		c := catID
		return &domain.Transaction{
			ID:                 txID,
			AccountID:          accID,
			CategoryID:         &c,
			Type:               domain.TransactionTypeExpense,
			Amount:             decimal.NewFromInt(75000),
			Currency:           "IDR",
			ExchangeRateToBase: decimal.NewFromInt(1),
			BaseAmount:         decimal.NewFromInt(75000),
			Note:               "Lunch at Warung",
			IsTalangan:         false,
			TransactionDate:    now,
			CreatedAt:          now,
			UpdatedAt:          now,
		}
	}

	t.Run("valid expense transaction passes validation", func(t *testing.T) {
		tx := validExpense()
		require.NoError(t, tx.Validate())
	})

	t.Run("valid transfer transaction passes validation", func(t *testing.T) {
		d := destAccID
		tx := &domain.Transaction{
			ID:                   txID,
			AccountID:            accID,
			DestinationAccountID: &d,
			Type:                 domain.TransactionTypeTransfer,
			Amount:               decimal.NewFromInt(250000),
			Currency:             "IDR",
			ExchangeRateToBase:   decimal.NewFromInt(1),
			BaseAmount:           decimal.NewFromInt(250000),
			TransactionDate:      now,
		}
		require.NoError(t, tx.Validate())
	})

	t.Run("nil transaction fails validation", func(t *testing.T) {
		var tx *domain.Transaction
		err := tx.Validate()
		require.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrInvalidInput))
	})

	t.Run("zero ID or account ID fails validation", func(t *testing.T) {
		tx := validExpense()
		tx.ID = domain.NilUUID
		assert.ErrorIs(t, tx.Validate(), domain.ErrInvalidInput)

		tx = validExpense()
		tx.AccountID = domain.NilUUID
		assert.ErrorIs(t, tx.Validate(), domain.ErrInvalidInput)
	})

	t.Run("non-positive amount or rate fails validation", func(t *testing.T) {
		tx := validExpense()
		tx.Amount = decimal.Zero
		assert.ErrorIs(t, tx.Validate(), domain.ErrInvalidInput)

		tx = validExpense()
		tx.Amount = decimal.NewFromInt(-100)
		assert.ErrorIs(t, tx.Validate(), domain.ErrInvalidInput)

		tx = validExpense()
		tx.ExchangeRateToBase = decimal.Zero
		assert.ErrorIs(t, tx.Validate(), domain.ErrInvalidInput)

		tx = validExpense()
		tx.BaseAmount = decimal.Zero
		assert.ErrorIs(t, tx.Validate(), domain.ErrInvalidInput)
	})

	t.Run("expense without category fails validation", func(t *testing.T) {
		tx := validExpense()
		tx.CategoryID = nil
		assert.ErrorIs(t, tx.Validate(), domain.ErrInvalidInput)
	})

	t.Run("transfer without destination account or same account fails validation", func(t *testing.T) {
		tx := validExpense()
		tx.Type = domain.TransactionTypeTransfer
		tx.DestinationAccountID = nil
		assert.ErrorIs(t, tx.Validate(), domain.ErrInvalidInput)

		sameAcc := accID
		tx.DestinationAccountID = &sameAcc
		assert.ErrorIs(t, tx.Validate(), domain.ErrInvalidInput)
	})
}
