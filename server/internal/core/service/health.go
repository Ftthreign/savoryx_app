package service

import (
	"context"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/samber/oops"
)

type healthService struct {
	dbPinger port.DatabasePinger
}

// NewHealthService instantiates a new HealthService implementation.
func NewHealthService(dbPinger port.DatabasePinger) port.HealthService {
	return &healthService{
		dbPinger: dbPinger,
	}
}

// CheckHealth verifies overall system health including database ping.
func (s *healthService) CheckHealth(ctx context.Context) (string, error) {
	if s.dbPinger != nil {
		if err := s.dbPinger.Ping(ctx); err != nil {
			return "degraded", oops.
				Code("ERR_DATABASE_UNAVAILABLE").
				In("health_service").
				Wrapf(err, "database connectivity ping failed")
		}
	}

	return "healthy", nil
}

// Ensure interface compliance
var _ port.HealthService = (*healthService)(nil)
var _ = domain.ErrInternal
