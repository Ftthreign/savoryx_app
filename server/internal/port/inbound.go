package port

import (
	"context"
)

type HealthService interface {
	CheckHealth(ctx context.Context) (status string, err error)
}
