package postgres

import (
	"context"
	"errors"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/adapter/repository/postgres/db"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/samber/oops"
	"github.com/shopspring/decimal"
)

type AccountRepository struct {
	q *db.Queries
}

func NewAccountRepository(d *DB) *AccountRepository {
	return &AccountRepository{
		q: db.New(d.Pool),
	}
}

func (r *AccountRepository) queries(ctx context.Context) *db.Queries {
	if tx := ExtractTx(ctx); tx != nil {
		return r.q.WithTx(tx)
	}
	return r.q
}

func (r *AccountRepository) Create(ctx context.Context, acc *domain.Account) error {
	if acc == nil {
		return oops.
			In("account_repository").
			Tags("database", "postgres").
			Code("ERR_ACCOUNT_NIL").
			Wrap(domain.ErrInvalidInput)
	}

	params := db.CreateAccountParams{
		ID:       pgtype.UUID{Bytes: acc.ID.Bytes(), Valid: true},
		Name:     acc.Name,
		Type:     db.AccountType(acc.Type),
		Currency: acc.Currency,
		Balance:  acc.Balance,
	}

	created, err := r.queries(ctx).CreateAccount(ctx, params)
	if err != nil {
		return oops.
			In("account_repository").
			Tags("database", "postgres").
			Code("ERR_ACCOUNT_CREATE").
			With("account_name", acc.Name).
			Wrapf(err, "failed to insert account record")
	}

	*acc = *toDomainAccount(created)
	return nil
}

func (r *AccountRepository) GetByID(ctx context.Context, id domain.UUID) (*domain.Account, error) {
	pgID := pgtype.UUID{Bytes: id.Bytes(), Valid: true}
	row, err := r.queries(ctx).GetAccountByID(ctx, pgID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, oops.
				In("account_repository").
				Tags("database", "postgres").
				Code("ERR_ACCOUNT_NOT_FOUND").
				With("account_id", id.String()).
				Wrap(domain.ErrAccountNotFound)
		}
		return nil, oops.
			In("account_repository").
			Tags("database", "postgres").
			Code("ERR_ACCOUNT_GET").
			With("account_id", id.String()).
			Wrapf(err, "failed to get account by id")
	}

	return toDomainAccount(row), nil
}

func (r *AccountRepository) GetByIDForUpdate(ctx context.Context, id domain.UUID) (*domain.Account, error) {
	pgID := pgtype.UUID{Bytes: id.Bytes(), Valid: true}
	row, err := r.queries(ctx).GetAccountByIDForUpdate(ctx, pgID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, oops.
				In("account_repository").
				Tags("database", "postgres").
				Code("ERR_ACCOUNT_NOT_FOUND").
				With("account_id", id.String()).
				Wrap(domain.ErrAccountNotFound)
		}
		return nil, oops.
			In("account_repository").
			Tags("database", "postgres").
			Code("ERR_ACCOUNT_GET_FOR_UPDATE").
			With("account_id", id.String()).
			Wrapf(err, "failed to get account by id with row lock")
	}

	return toDomainAccount(row), nil
}

func (r *AccountRepository) List(ctx context.Context, limit, offset int) ([]*domain.Account, error) {
	params := db.ListAccountsParams{
		Limit:  int32(limit),
		Offset: int32(offset),
	}

	rows, err := r.queries(ctx).ListAccounts(ctx, params)
	if err != nil {
		return nil, oops.
			In("account_repository").
			Tags("database", "postgres").
			Code("ERR_ACCOUNT_LIST").
			Wrapf(err, "failed to list accounts")
	}

	result := make([]*domain.Account, len(rows))
	for i, row := range rows {
		result[i] = toDomainAccount(row)
	}
	return result, nil
}

func (r *AccountRepository) Count(ctx context.Context) (int, error) {
	total, err := r.queries(ctx).CountAccounts(ctx)
	if err != nil {
		return 0, oops.
			In("account_repository").
			Tags("database", "postgres").
			Code("ERR_ACCOUNT_COUNT").
			Wrapf(err, "failed to count accounts")
	}
	return int(total), nil
}

func (r *AccountRepository) UpdateBalance(ctx context.Context, id domain.UUID, balance decimal.Decimal) error {
	params := db.UpdateAccountBalanceParams{
		ID:      pgtype.UUID{Bytes: id.Bytes(), Valid: true},
		Balance: balance,
	}

	_, err := r.queries(ctx).UpdateAccountBalance(ctx, params)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return oops.
				In("account_repository").
				Tags("database", "postgres").
				Code("ERR_ACCOUNT_NOT_FOUND").
				With("account_id", id.String()).
				Wrap(domain.ErrAccountNotFound)
		}
		return oops.
			In("account_repository").
			Tags("database", "postgres").
			Code("ERR_ACCOUNT_UPDATE_BALANCE").
			With("account_id", id.String()).
			Wrapf(err, "failed to update account balance")
	}

	return nil
}

func (r *AccountRepository) Update(ctx context.Context, acc *domain.Account) error {
	if acc == nil {
		return oops.
			In("account_repository").
			Tags("database", "postgres").
			Code("ERR_ACCOUNT_INVALID_INPUT").
			Wrap(domain.ErrInvalidInput)
	}

	params := db.UpdateAccountParams{
		ID:   pgtype.UUID{Bytes: acc.ID.Bytes(), Valid: true},
		Name: acc.Name,
		Type: db.AccountType(acc.Type),
	}

	updated, err := r.queries(ctx).UpdateAccount(ctx, params)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return oops.
				In("account_repository").
				Tags("database", "postgres").
				Code("ERR_ACCOUNT_NOT_FOUND").
				With("account_id", acc.ID.String()).
				Wrap(domain.ErrAccountNotFound)
		}
		return oops.
			In("account_repository").
			Tags("database", "postgres").
			Code("ERR_ACCOUNT_UPDATE").
			With("account_id", acc.ID.String()).
			Wrapf(err, "failed to update account")
	}

	*acc = *toDomainAccount(updated)
	return nil
}

func (r *AccountRepository) Delete(ctx context.Context, id domain.UUID) error {
	pgID := pgtype.UUID{Bytes: id.Bytes(), Valid: true}
	err := r.queries(ctx).SoftDeleteAccount(ctx, pgID)
	if err != nil {
		return oops.
			In("account_repository").
			Tags("database", "postgres").
			Code("ERR_ACCOUNT_DELETE").
			With("account_id", id.String()).
			Wrapf(err, "failed to soft delete account")
	}

	return nil
}

func (r *AccountRepository) ListUpdatedAfter(ctx context.Context, since time.Time) ([]*domain.Account, error) {
	rows, err := r.queries(ctx).ListAccountsUpdatedAfter(ctx, toPgTimestamptz(since))
	if err != nil {
		return nil, oops.
			In("account_repository").
			Tags("database", "postgres").
			Code("ERR_ACCOUNT_LIST_UPDATED_AFTER").
			Wrapf(err, "failed to list accounts updated after timestamp")
	}

	result := make([]*domain.Account, len(rows))
	for i, row := range rows {
		result[i] = toDomainAccount(row)
	}
	return result, nil
}

func (r *AccountRepository) UpsertSync(ctx context.Context, acc *domain.Account) error {
	if acc == nil {
		return oops.
			In("account_repository").
			Tags("database", "postgres").
			Code("ERR_ACCOUNT_NIL").
			Wrap(domain.ErrInvalidInput)
	}

	now := time.Now().UTC()
	createdAt := acc.CreatedAt
	if createdAt.IsZero() {
		createdAt = now
	}
	updatedAt := acc.UpdatedAt
	if updatedAt.IsZero() {
		updatedAt = now
	}

	params := db.UpsertAccountSyncParams{
		ID:        toPgUUID(acc.ID),
		Name:      acc.Name,
		Type:      db.AccountType(acc.Type),
		Currency:  acc.Currency,
		Balance:   acc.Balance,
		CreatedAt: toPgTimestamptz(createdAt),
		UpdatedAt: toPgTimestamptz(updatedAt),
		DeletedAt: toPgNullableTimestamptz(acc.DeletedAt),
	}

	upserted, err := r.queries(ctx).UpsertAccountSync(ctx, params)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			// Ignored when incoming updated_at is not newer than existing record (LWW guard)
			return nil
		}
		return oops.
			In("account_repository").
			Tags("database", "postgres").
			Code("ERR_ACCOUNT_UPSERT_SYNC").
			With("account_id", acc.ID.String()).
			Wrapf(err, "failed to upsert account sync record")
	}

	*acc = *toDomainAccount(upserted)
	return nil
}

func toDomainAccount(row db.Account) *domain.Account {
	var deletedAt *time.Time
	if row.DeletedAt.Valid {
		t := row.DeletedAt.Time
		deletedAt = &t
	}

	return &domain.Account{
		ID:        domain.FromBytes(row.ID.Bytes),
		Name:      row.Name,
		Type:      domain.AccountType(row.Type),
		Currency:  row.Currency,
		Balance:   row.Balance,
		CreatedAt: row.CreatedAt.Time,
		UpdatedAt: row.UpdatedAt.Time,
		DeletedAt: deletedAt,
	}
}

var _ port.AccountRepository = (*AccountRepository)(nil)
