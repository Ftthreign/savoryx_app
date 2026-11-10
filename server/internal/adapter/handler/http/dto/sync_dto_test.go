package dto_test

import (
	"testing"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/adapter/handler/http/dto"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestToSyncPullResponse_MicrosecondServerTimeCursor(t *testing.T) {
	t.Parallel()

	pulledAt := time.Date(2026, 11, 10, 5, 30, 45, 123456789, time.FixedZone("WIB", 7*3600))
	res := &port.SyncPullResult{
		Accounts:     []*domain.Account{},
		Categories:   []*domain.Category{},
		Transactions: []*domain.Transaction{},
		PulledAt:     pulledAt,
	}

	out := dto.ToSyncPullResponse(res)
	expectedMicro := pulledAt.UTC().Truncate(time.Microsecond)

	assert.Equal(t, expectedMicro, out.PulledAt)
	assert.Equal(t, expectedMicro.Format(time.RFC3339Nano), out.ServerTime)

	parsed, err := time.Parse(time.RFC3339Nano, out.ServerTime)
	require.NoError(t, err)
	assert.True(t, parsed.Equal(out.PulledAt))
}
