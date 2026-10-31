package fakes

import (
	"context"
	"fmt"
	"strings"
	"sync"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/shopspring/decimal"
)

// InMemoryAccountRepository provides a thread-safe, in-memory implementation of port.AccountRepository.
type InMemoryAccountRepository struct {
	mu       sync.RWMutex
	accounts map[domain.UUID]*domain.Account
}

// NewInMemoryAccountRepository initializes a new in-memory account store.
func NewInMemoryAccountRepository() *InMemoryAccountRepository {
	return &InMemoryAccountRepository{
		accounts: make(map[domain.UUID]*domain.Account),
	}
}

func (r *InMemoryAccountRepository) Create(ctx context.Context, acc *domain.Account) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	for _, existing := range r.accounts {
		if existing.DeletedAt == nil && strings.EqualFold(existing.Name, acc.Name) {
			return fmt.Errorf("%w: account name already exists", domain.ErrConflict)
		}
	}

	clone := *acc
	if clone.CreatedAt.IsZero() {
		clone.CreatedAt = time.Now().UTC()
	}
	clone.UpdatedAt = time.Now().UTC()
	r.accounts[acc.ID] = &clone
	return nil
}

func (r *InMemoryAccountRepository) GetByID(ctx context.Context, id domain.UUID) (*domain.Account, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	acc, exists := r.accounts[id]
	if !exists || acc.DeletedAt != nil {
		return nil, domain.ErrNotFound
	}
	clone := *acc
	return &clone, nil
}

func (r *InMemoryAccountRepository) GetByIDForUpdate(ctx context.Context, id domain.UUID) (*domain.Account, error) {
	return r.GetByID(ctx, id)
}

func (r *InMemoryAccountRepository) List(ctx context.Context) ([]*domain.Account, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []*domain.Account
	for _, acc := range r.accounts {
		if acc.DeletedAt == nil {
			clone := *acc
			result = append(result, &clone)
		}
	}
	return result, nil
}

func (r *InMemoryAccountRepository) Update(ctx context.Context, acc *domain.Account) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	existing, exists := r.accounts[acc.ID]
	if !exists || existing.DeletedAt != nil {
		return domain.ErrNotFound
	}

	for _, other := range r.accounts {
		if other.ID != acc.ID && other.DeletedAt == nil && strings.EqualFold(other.Name, acc.Name) {
			return fmt.Errorf("%w: account name already exists", domain.ErrConflict)
		}
	}

	existing.Name = acc.Name
	existing.Type = acc.Type
	existing.UpdatedAt = time.Now().UTC()
	return nil
}

func (r *InMemoryAccountRepository) UpdateBalance(ctx context.Context, id domain.UUID, balance decimal.Decimal) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	existing, exists := r.accounts[id]
	if !exists || existing.DeletedAt != nil {
		return domain.ErrNotFound
	}

	existing.Balance = balance
	existing.UpdatedAt = time.Now().UTC()
	return nil
}

func (r *InMemoryAccountRepository) Delete(ctx context.Context, id domain.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	existing, exists := r.accounts[id]
	if !exists || existing.DeletedAt != nil {
		return domain.ErrNotFound
	}

	now := time.Now().UTC()
	existing.DeletedAt = &now
	existing.UpdatedAt = now
	return nil
}

var _ port.AccountRepository = (*InMemoryAccountRepository)(nil)
