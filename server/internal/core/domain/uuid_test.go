package domain_test

import (
	"encoding/json"
	"testing"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/shopspring/decimal"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestParseUUID(t *testing.T) {
	validStr := "0192e4a1-8d2b-7abc-9f12-0123456789ab"
	compactStr := "0192e4a18d2b7abc9f120123456789ab"
	urnStr := "urn:uuid:0192e4a1-8d2b-7abc-9f12-0123456789ab"

	t.Run("Standard 36-char hyphenated UUID", func(t *testing.T) {
		u, err := domain.ParseUUID(validStr)
		require.NoError(t, err)
		assert.Equal(t, validStr, u.String())
		assert.False(t, u.IsZero())
	})

	t.Run("Compact 32-char hex UUID", func(t *testing.T) {
		u, err := domain.ParseUUID(compactStr)
		require.NoError(t, err)
		assert.Equal(t, validStr, u.String())
	})

	t.Run("URN format UUID", func(t *testing.T) {
		u, err := domain.ParseUUID(urnStr)
		require.NoError(t, err)
		assert.Equal(t, validStr, u.String())
	})

	t.Run("Nil / Zero UUID", func(t *testing.T) {
		u, err := domain.ParseUUID("00000000-0000-0000-0000-000000000000")
		require.NoError(t, err)
		assert.True(t, u.IsZero())
		assert.Equal(t, domain.NilUUID, u)
	})

	t.Run("Invalid length", func(t *testing.T) {
		_, err := domain.ParseUUID("0192e4a1-8d2b-7abc")
		require.Error(t, err)
		assert.ErrorIs(t, err, domain.ErrInvalidUUIDLength)
	})

	t.Run("Misplaced hyphens", func(t *testing.T) {
		_, err := domain.ParseUUID("0192e4a1-8d2b7-abc-9f12-0123456789ab")
		require.Error(t, err)
		assert.ErrorIs(t, err, domain.ErrInvalidUUIDFormat)
	})

	t.Run("Non-hex characters", func(t *testing.T) {
		_, err := domain.ParseUUID("0192e4a1-8d2b-7abc-9f12-0123456789zz")
		require.Error(t, err)
		assert.ErrorIs(t, err, domain.ErrInvalidUUIDFormat)
	})
}

func TestUUID_JSONMarshaling(t *testing.T) {
	rawUUID := "0192e4a1-8d2b-7abc-9f12-0123456789ab"
	u, err := domain.ParseUUID(rawUUID)
	require.NoError(t, err)

	t.Run("Direct UUID JSON marshal", func(t *testing.T) {
		data, err := json.Marshal(u)
		require.NoError(t, err)
		assert.Equal(t, `"`+rawUUID+`"`, string(data))

		var unmarshaled domain.UUID
		err = json.Unmarshal(data, &unmarshaled)
		require.NoError(t, err)
		assert.Equal(t, u, unmarshaled)
	})

	t.Run("Null JSON unmarshal", func(t *testing.T) {
		var unmarshaled domain.UUID
		err := json.Unmarshal([]byte("null"), &unmarshaled)
		require.NoError(t, err)
		assert.True(t, unmarshaled.IsZero())
	})

	t.Run("Account model JSON roundtrip", func(t *testing.T) {
		now := time.Now().UTC().Truncate(time.Second)
		acc := domain.Account{
			ID:        u,
			Name:      "BCA Main Checking",
			Type:      domain.AccountTypeBank,
			Currency:  "IDR",
			Balance:   decimal.NewFromInt(15000000),
			CreatedAt: now,
			UpdatedAt: now,
		}

		data, err := json.Marshal(acc)
		require.NoError(t, err)

		// Assert standard string representation in JSON (not byte array)
		assert.Contains(t, string(data), `"id":"`+rawUUID+`"`)
		assert.NotContains(t, string(data), `[1,`)

		var roundtrip domain.Account
		err = json.Unmarshal(data, &roundtrip)
		require.NoError(t, err)
		assert.Equal(t, acc.ID, roundtrip.ID)
		assert.Equal(t, acc.Name, roundtrip.Name)
		assert.Equal(t, acc.Type, roundtrip.Type)
		assert.True(t, acc.Balance.Equal(roundtrip.Balance))
	})

	t.Run("Category and Preference JSON roundtrip", func(t *testing.T) {
		cat := domain.Category{
			ID:      u,
			Name:    "Dining",
			Icon:    "restaurant",
			Color:   "#8DB355",
			IsWants: true,
		}
		dataCat, err := json.Marshal(cat)
		require.NoError(t, err)
		assert.Contains(t, string(dataCat), `"id":"`+rawUUID+`"`)

		pref := domain.UserPreference{
			ID:               u,
			Theme:            domain.ThemePreferenceClayLight,
			FontFamily:       domain.FontFamilyNunitoSans,
			BaseCurrency:     "IDR",
			MonthlyWorkHours: 160,
			MonthlyIncomeNet: decimal.NewFromInt(30000000),
		}
		dataPref, err := json.Marshal(pref)
		require.NoError(t, err)
		assert.Contains(t, string(dataPref), `"id":"`+rawUUID+`"`)
	})
}

func TestUUID_TextMarshaling(t *testing.T) {
	rawUUID := "0192e4a1-8d2b-7abc-9f12-0123456789ab"
	u, err := domain.ParseUUID(rawUUID)
	require.NoError(t, err)

	text, err := u.MarshalText()
	require.NoError(t, err)
	assert.Equal(t, rawUUID, string(text))

	var unmarshaled domain.UUID
	err = unmarshaled.UnmarshalText(text)
	require.NoError(t, err)
	assert.Equal(t, u, unmarshaled)

	// Empty text unmarshals to zero UUID
	err = unmarshaled.UnmarshalText([]byte(""))
	require.NoError(t, err)
	assert.True(t, unmarshaled.IsZero())
}

func TestUUID_SQLDriver(t *testing.T) {
	rawUUID := "0192e4a1-8d2b-7abc-9f12-0123456789ab"
	u, err := domain.ParseUUID(rawUUID)
	require.NoError(t, err)

	t.Run("Driver Value", func(t *testing.T) {
		val, err := u.Value()
		require.NoError(t, err)
		assert.Equal(t, rawUUID, val)
	})

	t.Run("Scan string", func(t *testing.T) {
		var scanned domain.UUID
		err := scanned.Scan(rawUUID)
		require.NoError(t, err)
		assert.Equal(t, u, scanned)
	})

	t.Run("Scan 16-byte slice", func(t *testing.T) {
		rawBytes := u.Bytes()
		var scanned domain.UUID
		err := scanned.Scan(rawBytes[:])
		require.NoError(t, err)
		assert.Equal(t, u, scanned)
	})

	t.Run("Scan [16]byte", func(t *testing.T) {
		rawBytes := u.Bytes()
		var scanned domain.UUID
		err := scanned.Scan(rawBytes)
		require.NoError(t, err)
		assert.Equal(t, u, scanned)
	})

	t.Run("Scan nil", func(t *testing.T) {
		var scanned domain.UUID
		err := scanned.Scan(nil)
		require.NoError(t, err)
		assert.True(t, scanned.IsZero())
	})

	t.Run("Scan invalid type", func(t *testing.T) {
		var scanned domain.UUID
		err := scanned.Scan(12345)
		require.Error(t, err)
	})
}
