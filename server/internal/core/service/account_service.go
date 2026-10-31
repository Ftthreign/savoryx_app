package service

import (
	"context"
	"strings"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/samber/oops"
	"github.com/shopspring/decimal"
)

type accountService struct {
	repo port.AccountRepository
}

// NewAccountService instantiates a new AccountService domain service implementation.
func NewAccountService(repo port.AccountRepository) port.AccountService {
	return &accountService{
		repo: repo,
	}
}

// CreateAccount validates domain rules and persists a new financial account.
func (s *accountService) CreateAccount(ctx context.Context, acc *domain.Account) error {
	if acc == nil {
		return oops.
			In("account_service").
			Code("ERR_INVALID_ACCOUNT").
			Wrapf(domain.ErrInvalidInput, "account entity cannot be nil")
	}

	if acc.ID.IsZero() {
		return oops.
			In("account_service").
			Code("ERR_INVALID_ACCOUNT_ID").
			Wrapf(domain.ErrInvalidInput, "account ID cannot be nil or zero")
	}

	trimmedName := strings.TrimSpace(acc.Name)
	if trimmedName == "" {
		return oops.
			In("account_service").
			Code("ERR_EMPTY_ACCOUNT_NAME").
			Wrapf(domain.ErrInvalidInput, "account name cannot be empty")
	}
	acc.Name = trimmedName

	if !acc.Type.IsValid() {
		return oops.
			In("account_service").
			Code("ERR_INVALID_ACCOUNT_TYPE").
			With("type", string(acc.Type)).
			Wrapf(domain.ErrInvalidInput, "invalid account type: %s", acc.Type)
	}

	trimmedCurrency := strings.ToUpper(strings.TrimSpace(acc.Currency))
	if trimmedCurrency == "" {
		trimmedCurrency = "IDR"
	}
	acc.Currency = trimmedCurrency

	now := time.Now().UTC()
	if acc.CreatedAt.IsZero() {
		acc.CreatedAt = now
	}
	if acc.UpdatedAt.IsZero() {
		acc.UpdatedAt = now
	}

	if err := s.repo.Create(ctx, acc); err != nil {
		return oops.
			In("account_service").
			Code("ERR_ACCOUNT_CREATE_FAILED").
			With("account_id", acc.ID.String()).
			Wrapf(err, "failed to persist account")
	}

	return nil
}

// GetAccount retrieves an account by its unique identifier.
func (s *accountService) GetAccount(ctx context.Context, id domain.UUID) (*domain.Account, error) {
	if id.IsZero() {
		return nil, oops.
			In("account_service").
			Code("ERR_INVALID_ACCOUNT_ID").
			Wrapf(domain.ErrInvalidInput, "account ID cannot be nil or zero")
	}

	acc, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if acc == nil {
		return nil, oops.
			In("account_service").
			Code("ERR_ACCOUNT_NOT_FOUND").
			With("account_id", id.String()).
			Wrap(domain.ErrAccountNotFound)
	}

	return acc, nil
}

// ListAccounts retrieves all non-deleted accounts.
func (s *accountService) ListAccounts(ctx context.Context) ([]*domain.Account, error) {
	accounts, err := s.repo.List(ctx)
	if err != nil {
		return nil, oops.
			In("account_service").
			Code("ERR_ACCOUNT_LIST_FAILED").
			Wrapf(err, "failed to retrieve accounts list")
	}

	if accounts == nil {
		accounts = make([]*domain.Account, 0)
	}
	return accounts, nil
}

// UpdateAccount updates account metadata (name and type) after verifying existence and input constraints.
func (s *accountService) UpdateAccount(
	ctx context.Context,
	id domain.UUID,
	name string,
	accType domain.AccountType,
) (*domain.Account, error) {
	if id.IsZero() {
		return nil, oops.
			In("account_service").
			Code("ERR_INVALID_ACCOUNT_ID").
			Wrapf(domain.ErrInvalidInput, "account ID cannot be nil or zero")
	}

	trimmedName := strings.TrimSpace(name)
	if trimmedName == "" {
		return nil, oops.
			In("account_service").
			Code("ERR_ACCOUNT_NAME_REQUIRED").
			Wrapf(domain.ErrInvalidInput, "account name cannot be empty")
	}
	if len(trimmedName) > 64 {
		return nil, oops.
			In("account_service").
			Code("ERR_ACCOUNT_NAME_TOO_LONG").
			Wrapf(domain.ErrInvalidInput, "account name exceeds maximum length of 64 characters")
	}

	if !accType.IsValid() {
		return nil, oops.
			In("account_service").
			Code("ERR_INVALID_ACCOUNT_TYPE").
			Wrapf(domain.ErrInvalidInput, "invalid account type: %s", accType)
	}

	existing, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if existing == nil {
		return nil, oops.
			In("account_service").
			Code("ERR_ACCOUNT_NOT_FOUND").
			With("account_id", id.String()).
			Wrap(domain.ErrAccountNotFound)
	}

	existing.Name = trimmedName
	existing.Type = accType

	if err := s.repo.Update(ctx, existing); err != nil {
		return nil, err
	}

	return existing, nil
}

// UpdateBalance applies a new balance to an account using pessimistic row locking to prevent race conditions.
func (s *accountService) UpdateBalance(ctx context.Context, id domain.UUID, newBalance decimal.Decimal) error {
	if id.IsZero() {
		return oops.
			In("account_service").
			Code("ERR_INVALID_ACCOUNT_ID").
			Wrapf(domain.ErrInvalidInput, "account ID cannot be nil or zero")
	}

	// Acquire pessimistic row-lock to avoid double-spending race condition
	acc, err := s.repo.GetByIDForUpdate(ctx, id)
	if err != nil {
		return err
	}
	if acc == nil {
		return oops.
			In("account_service").
			Code("ERR_ACCOUNT_NOT_FOUND").
			With("account_id", id.String()).
			Wrap(domain.ErrAccountNotFound)
	}

	if err := s.repo.UpdateBalance(ctx, id, newBalance); err != nil {
		return oops.
			In("account_service").
			Code("ERR_UPDATE_BALANCE_FAILED").
			With("account_id", id.String()).
			Wrapf(err, "failed to update account balance")
	}

	return nil
}

// DeleteAccount soft-deletes an account after verifying its existence.
func (s *accountService) DeleteAccount(ctx context.Context, id domain.UUID) error {
	if id.IsZero() {
		return oops.
			In("account_service").
			Code("ERR_INVALID_ACCOUNT_ID").
			Wrapf(domain.ErrInvalidInput, "account ID cannot be nil or zero")
	}

	acc, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return err
	}
	if acc == nil {
		return oops.
			In("account_service").
			Code("ERR_ACCOUNT_NOT_FOUND").
			With("account_id", id.String()).
			Wrap(domain.ErrAccountNotFound)
	}

	if err := s.repo.Delete(ctx, id); err != nil {
		return oops.
			In("account_service").
			Code("ERR_DELETE_ACCOUNT_FAILED").
			With("account_id", id.String()).
			Wrapf(err, "failed to delete account")
	}

	return nil
}

var _ port.AccountService = (*accountService)(nil)
