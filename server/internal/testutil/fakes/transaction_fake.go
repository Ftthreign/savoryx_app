package fakes

import (
	"context"
	"sync"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
)

type InMemoryTransactionRepository struct {
	mu           sync.RWMutex
	transactions map[domain.UUID]*domain.Transaction
}

func NewInMemoryTransactionRepository() *InMemoryTransactionRepository {
	return &InMemoryTransactionRepository{
		transactions: make(map[domain.UUID]*domain.Transaction),
	}
}

func (r *InMemoryTransactionRepository) Create(ctx context.Context, tx *domain.Transaction) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	if _, exists := r.transactions[tx.ID]; exists {
		return domain.ErrConflict
	}

	clone := cloneTransaction(tx)
	r.transactions[tx.ID] = clone
	return nil
}

func (r *InMemoryTransactionRepository) Upsert(ctx context.Context, tx *domain.Transaction) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	existing, exists := r.transactions[tx.ID]
	if !exists {
		clone := cloneTransaction(tx)
		r.transactions[tx.ID] = clone
		return nil
	}

	// Append-Only Ledger: existing non-deleted transactions can only transition to tombstone (deleted_at != nil)
	if existing.DeletedAt == nil && tx.DeletedAt != nil {
		del := *tx.DeletedAt
		existing.DeletedAt = &del
		existing.UpdatedAt = tx.UpdatedAt
	}
	return nil
}

func (r *InMemoryTransactionRepository) GetByID(ctx context.Context, id domain.UUID) (*domain.Transaction, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	tx, exists := r.transactions[id]
	if !exists || tx.DeletedAt != nil {
		return nil, domain.ErrTransactionNotFound
	}
	return cloneTransaction(tx), nil
}

func (r *InMemoryTransactionRepository) List(ctx context.Context, limit, offset int) ([]*domain.Transaction, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []*domain.Transaction
	for _, tx := range r.transactions {
		if tx.DeletedAt == nil {
			result = append(result, cloneTransaction(tx))
		}
	}

	return paginateTransactions(result, limit, offset), nil
}

func (r *InMemoryTransactionRepository) ListByAccount(ctx context.Context, accountID domain.UUID, limit, offset int) ([]*domain.Transaction, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []*domain.Transaction
	for _, tx := range r.transactions {
		if tx.DeletedAt == nil && matchesAccount(tx, accountID) {
			result = append(result, cloneTransaction(tx))
		}
	}

	return paginateTransactions(result, limit, offset), nil
}

func (r *InMemoryTransactionRepository) Count(ctx context.Context) (int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	count := 0
	for _, tx := range r.transactions {
		if tx.DeletedAt == nil {
			count++
		}
	}
	return count, nil
}

func (r *InMemoryTransactionRepository) CountByAccount(ctx context.Context, accountID domain.UUID) (int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	count := 0
	for _, tx := range r.transactions {
		if tx.DeletedAt == nil && matchesAccount(tx, accountID) {
			count++
		}
	}
	return count, nil
}

func (r *InMemoryTransactionRepository) ListUpdatedAfter(ctx context.Context, since time.Time) ([]*domain.Transaction, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []*domain.Transaction
	for _, tx := range r.transactions {
		if tx.UpdatedAt.After(since) {
			result = append(result, cloneTransaction(tx))
		}
	}
	return result, nil
}

func (r *InMemoryTransactionRepository) Delete(ctx context.Context, id domain.UUID) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	existing, exists := r.transactions[id]
	if !exists || existing.DeletedAt != nil {
		return domain.ErrTransactionNotFound
	}

	now := time.Now().UTC()
	existing.DeletedAt = &now
	existing.UpdatedAt = now
	return nil
}

func matchesAccount(tx *domain.Transaction, accountID domain.UUID) bool {
	if tx.AccountID == accountID {
		return true
	}
	return tx.DestinationAccountID != nil && *tx.DestinationAccountID == accountID
}

func paginateTransactions(items []*domain.Transaction, limit, offset int) []*domain.Transaction {
	if offset < 0 {
		offset = 0
	}
	if offset >= len(items) {
		return []*domain.Transaction{}
	}
	end := offset + limit
	if limit <= 0 || end > len(items) {
		end = len(items)
	}
	return items[offset:end]
}

func cloneTransaction(tx *domain.Transaction) *domain.Transaction {
	clone := *tx
	if tx.CategoryID != nil {
		c := *tx.CategoryID
		clone.CategoryID = &c
	}
	if tx.DestinationAccountID != nil {
		d := *tx.DestinationAccountID
		clone.DestinationAccountID = &d
	}
	if tx.DeletedAt != nil {
		del := *tx.DeletedAt
		clone.DeletedAt = &del
	}
	return &clone
}

var _ port.TransactionRepository = (*InMemoryTransactionRepository)(nil)
