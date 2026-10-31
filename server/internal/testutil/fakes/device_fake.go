package fakes

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
)

// InMemoryDeviceRepository provides a thread-safe, in-memory implementation of port.DeviceRepository.
type InMemoryDeviceRepository struct {
	mu      sync.RWMutex
	devices map[domain.UUID]*domain.Device
}

// NewInMemoryDeviceRepository initializes a new in-memory device store.
func NewInMemoryDeviceRepository() *InMemoryDeviceRepository {
	return &InMemoryDeviceRepository{
		devices: make(map[domain.UUID]*domain.Device),
	}
}

func (r *InMemoryDeviceRepository) Register(ctx context.Context, dev *domain.Device) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.devices[dev.ID]; exists {
		return fmt.Errorf("%w: device id already registered", domain.ErrConflict)
	}
	clone := *dev
	if clone.CreatedAt.IsZero() {
		clone.CreatedAt = time.Now().UTC()
	}
	clone.LastActiveAt = clone.CreatedAt
	r.devices[dev.ID] = &clone
	return nil
}

func (r *InMemoryDeviceRepository) GetByID(ctx context.Context, id domain.UUID) (*domain.Device, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	dev, exists := r.devices[id]
	if !exists {
		return nil, domain.ErrNotFound
	}
	clone := *dev
	return &clone, nil
}

func (r *InMemoryDeviceRepository) UpdateLastActive(ctx context.Context, id domain.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	dev, exists := r.devices[id]
	if !exists {
		return domain.ErrNotFound
	}
	dev.LastActiveAt = time.Now().UTC()
	return nil
}

func (r *InMemoryDeviceRepository) Revoke(ctx context.Context, id domain.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	dev, exists := r.devices[id]
	if !exists {
		return domain.ErrNotFound
	}
	now := time.Now().UTC()
	dev.RevokedAt = &now
	return nil
}

var _ port.DeviceRepository = (*InMemoryDeviceRepository)(nil)
