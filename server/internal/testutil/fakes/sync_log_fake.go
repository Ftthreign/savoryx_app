package fakes

import (
	"context"
	"sort"
	"sync"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
)

// InMemorySyncLogRepository provides a thread-safe, in-memory implementation of port.SyncLogRepository.
type InMemorySyncLogRepository struct {
	mu   sync.RWMutex
	logs map[domain.UUID]*domain.SyncLog
}

// NewInMemorySyncLogRepository initializes a new in-memory sync audit log store.
func NewInMemorySyncLogRepository() *InMemorySyncLogRepository {
	return &InMemorySyncLogRepository{
		logs: make(map[domain.UUID]*domain.SyncLog),
	}
}

func (r *InMemorySyncLogRepository) Record(ctx context.Context, log *domain.SyncLog) error {
	if err := log.Validate(); err != nil {
		return err
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	clone := *log
	r.logs[log.ID] = &clone
	return nil
}

func (r *InMemorySyncLogRepository) GetByID(ctx context.Context, id domain.UUID) (*domain.SyncLog, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	log, ok := r.logs[id]
	if !ok {
		return nil, domain.ErrNotFound
	}
	clone := *log
	return &clone, nil
}

func (r *InMemorySyncLogRepository) ListByDevice(ctx context.Context, deviceID domain.UUID, limit, offset int) ([]*domain.SyncLog, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	filtered := make([]*domain.SyncLog, 0)
	for _, entry := range r.logs {
		if entry.DeviceID == deviceID {
			clone := *entry
			filtered = append(filtered, &clone)
		}
	}

	sort.Slice(filtered, func(i, j int) bool {
		return filtered[i].CreatedAt.After(filtered[j].CreatedAt)
	})

	if offset < 0 {
		offset = 0
	}
	if offset >= len(filtered) {
		return []*domain.SyncLog{}, nil
	}
	end := len(filtered)
	if limit > 0 && offset+limit < end {
		end = offset + limit
	}
	return filtered[offset:end], nil
}

func (r *InMemorySyncLogRepository) CountByDevice(ctx context.Context, deviceID domain.UUID) (int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	count := 0
	for _, entry := range r.logs {
		if entry.DeviceID == deviceID {
			count++
		}
	}
	return count, nil
}

var _ port.SyncLogRepository = (*InMemorySyncLogRepository)(nil)
