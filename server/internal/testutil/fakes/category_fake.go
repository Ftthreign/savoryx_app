package fakes

import (
	"context"
	"fmt"
	"strings"
	"sync"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
)

// InMemoryCategoryRepository provides a thread-safe, in-memory implementation of port.CategoryRepository.
type InMemoryCategoryRepository struct {
	mu         sync.RWMutex
	categories map[domain.UUID]*domain.Category
}

// NewInMemoryCategoryRepository initializes a new in-memory category store.
func NewInMemoryCategoryRepository() *InMemoryCategoryRepository {
	return &InMemoryCategoryRepository{
		categories: make(map[domain.UUID]*domain.Category),
	}
}

func (r *InMemoryCategoryRepository) Create(ctx context.Context, cat *domain.Category) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	for _, existing := range r.categories {
		if existing.DeletedAt == nil && strings.EqualFold(existing.Name, cat.Name) {
			return fmt.Errorf("%w: category name already exists", domain.ErrConflict)
		}
	}

	clone := *cat
	if clone.CreatedAt.IsZero() {
		clone.CreatedAt = time.Now().UTC()
	}
	clone.UpdatedAt = time.Now().UTC()
	r.categories[cat.ID] = &clone
	return nil
}

func (r *InMemoryCategoryRepository) GetByID(ctx context.Context, id domain.UUID) (*domain.Category, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	cat, exists := r.categories[id]
	if !exists || cat.DeletedAt != nil {
		return nil, domain.ErrNotFound
	}
	clone := *cat
	return &clone, nil
}

func (r *InMemoryCategoryRepository) List(ctx context.Context) ([]*domain.Category, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []*domain.Category
	for _, cat := range r.categories {
		if cat.DeletedAt == nil {
			clone := *cat
			result = append(result, &clone)
		}
	}
	return result, nil
}

func (r *InMemoryCategoryRepository) Update(ctx context.Context, cat *domain.Category) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	existing, exists := r.categories[cat.ID]
	if !exists || existing.DeletedAt != nil {
		return domain.ErrNotFound
	}

	for _, other := range r.categories {
		if other.ID != cat.ID && other.DeletedAt == nil && strings.EqualFold(other.Name, cat.Name) {
			return fmt.Errorf("%w: category name already exists", domain.ErrConflict)
		}
	}

	existing.Name = cat.Name
	existing.Icon = cat.Icon
	existing.Color = cat.Color
	existing.IsWants = cat.IsWants
	existing.UpdatedAt = time.Now().UTC()
	return nil
}

func (r *InMemoryCategoryRepository) Delete(ctx context.Context, id domain.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	existing, exists := r.categories[id]
	if !exists || existing.DeletedAt != nil {
		return domain.ErrNotFound
	}

	now := time.Now().UTC()
	existing.DeletedAt = &now
	existing.UpdatedAt = now
	return nil
}

var _ port.CategoryRepository = (*InMemoryCategoryRepository)(nil)
