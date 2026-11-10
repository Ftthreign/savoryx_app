package postgres

import (
	"context"
	"errors"
	"math"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/adapter/repository/postgres/db"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/samber/oops"
)

type TransactionRepository struct {
	q *db.Queries
}

func NewTransactionRepository(d *DB) *TransactionRepository {
	return &TransactionRepository{
		q: db.New(d.Pool),
	}
}

func (r *TransactionRepository) queries(ctx context.Context) *db.Queries {
	if tx := ExtractTx(ctx); tx != nil {
		return r.q.WithTx(tx)
	}
	return r.q
}

func repoTxErr() oops.OopsErrorBuilder {
	return oops.In("transaction_repository").Tags("database", "postgres")
}

func (r *TransactionRepository) Create(ctx context.Context, tx *domain.Transaction) error {
	if tx == nil {
		return repoTxErr().
			Code("ERR_TRANSACTION_NIL").
			Wrap(domain.ErrInvalidInput)
	}

	params := db.CreateTransactionParams{
		ID:                   toPgUUID(tx.ID),
		AccountID:            toPgUUID(tx.AccountID),
		CategoryID:           toPgNullableUUID(tx.CategoryID),
		DestinationAccountID: toPgNullableUUID(tx.DestinationAccountID),
		Type:                 db.TransactionType(tx.Type),
		Amount:               tx.Amount,
		Currency:             tx.Currency,
		ExchangeRateToBase:   tx.ExchangeRateToBase,
		BaseAmount:           tx.BaseAmount,
		Note:                 tx.Note,
		IsTalangan:           tx.IsTalangan,
		TransactionDate:      toPgTimestamptz(tx.TransactionDate),
	}

	created, err := r.queries(ctx).CreateTransaction(ctx, params)
	if err != nil {
		return repoTxErr().
			Code("ERR_TRANSACTION_CREATE").
			With("transaction_id", tx.ID.String()).
			Wrapf(err, "failed to insert transaction record")
	}

	populateDomainTransaction(tx, created)
	return nil
}

func (r *TransactionRepository) Upsert(ctx context.Context, tx *domain.Transaction) error {
	if tx == nil {
		return repoTxErr().
			Code("ERR_TRANSACTION_NIL").
			Wrap(domain.ErrInvalidInput)
	}

	now := time.Now().UTC()
	createdAt := tx.CreatedAt
	if createdAt.IsZero() {
		createdAt = now
	}
	updatedAt := tx.UpdatedAt
	if updatedAt.IsZero() {
		updatedAt = now
	}

	params := db.UpsertTransactionParams{
		ID:                   toPgUUID(tx.ID),
		AccountID:            toPgUUID(tx.AccountID),
		CategoryID:           toPgNullableUUID(tx.CategoryID),
		DestinationAccountID: toPgNullableUUID(tx.DestinationAccountID),
		Type:                 db.TransactionType(tx.Type),
		Amount:               tx.Amount,
		Currency:             tx.Currency,
		ExchangeRateToBase:   tx.ExchangeRateToBase,
		BaseAmount:           tx.BaseAmount,
		Note:                 tx.Note,
		IsTalangan:           tx.IsTalangan,
		TransactionDate:      toPgTimestamptz(tx.TransactionDate),
		CreatedAt:            toPgTimestamptz(createdAt),
		UpdatedAt:            toPgTimestamptz(updatedAt),
		DeletedAt:            toPgNullableTimestamptz(tx.DeletedAt),
	}

	upserted, err := r.queries(ctx).UpsertTransaction(ctx, params)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			// Ignored when incoming updated_at is older than existing record (LWW guard)
			return nil
		}
		return repoTxErr().
			Code("ERR_TRANSACTION_UPSERT").
			With("transaction_id", tx.ID.String()).
			Wrapf(err, "failed to upsert transaction record")
	}

	populateDomainTransaction(tx, upserted)
	return nil
}

func (r *TransactionRepository) GetByID(ctx context.Context, id domain.UUID) (*domain.Transaction, error) {
	row, err := r.queries(ctx).GetTransactionByID(ctx, toPgUUID(id))
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, repoTxErr().
				Code("ERR_TRANSACTION_NOT_FOUND").
				With("transaction_id", id.String()).
				Wrap(domain.ErrTransactionNotFound)
		}
		return nil, repoTxErr().
			Code("ERR_TRANSACTION_GET").
			With("transaction_id", id.String()).
			Wrapf(err, "failed to get transaction by id")
	}

	var out domain.Transaction
	populateDomainTransaction(&out, row)
	return &out, nil
}

func (r *TransactionRepository) List(ctx context.Context, limit, offset int) ([]*domain.Transaction, error) {
	safeLimit, safeOffset := clampPaginationInt32(limit, offset)
	rows, err := r.queries(ctx).ListTransactions(ctx, db.ListTransactionsParams{
		Limit:  safeLimit,
		Offset: safeOffset,
	})
	if err != nil {
		return nil, repoTxErr().
			Code("ERR_TRANSACTION_LIST").
			Wrapf(err, "failed to list transactions")
	}

	return toDomainTransactions(rows), nil
}

func (r *TransactionRepository) ListByAccount(ctx context.Context, accountID domain.UUID, limit, offset int) ([]*domain.Transaction, error) {
	safeLimit, safeOffset := clampPaginationInt32(limit, offset)
	rows, err := r.queries(ctx).ListTransactionsByAccount(ctx, db.ListTransactionsByAccountParams{
		AccountID: toPgUUID(accountID),
		Limit:     safeLimit,
		Offset:    safeOffset,
	})
	if err != nil {
		return nil, repoTxErr().
			Code("ERR_TRANSACTION_LIST_BY_ACCOUNT").
			With("account_id", accountID.String()).
			Wrapf(err, "failed to list transactions by account")
	}

	return toDomainTransactions(rows), nil
}

func (r *TransactionRepository) Count(ctx context.Context) (int, error) {
	total, err := r.queries(ctx).CountTransactions(ctx)
	if err != nil {
		return 0, repoTxErr().
			Code("ERR_TRANSACTION_COUNT").
			Wrapf(err, "failed to count transactions")
	}
	return int(total), nil
}

func (r *TransactionRepository) CountByAccount(ctx context.Context, accountID domain.UUID) (int, error) {
	total, err := r.queries(ctx).CountTransactionsByAccount(ctx, toPgUUID(accountID))
	if err != nil {
		return 0, repoTxErr().
			Code("ERR_TRANSACTION_COUNT_BY_ACCOUNT").
			With("account_id", accountID.String()).
			Wrapf(err, "failed to count transactions by account")
	}
	return int(total), nil
}

func (r *TransactionRepository) ListUpdatedAfter(ctx context.Context, since time.Time) ([]*domain.Transaction, error) {
	rows, err := r.queries(ctx).ListTransactionsUpdatedAfter(ctx, toPgTimestamptz(since))
	if err != nil {
		return nil, repoTxErr().
			Code("ERR_TRANSACTION_LIST_UPDATED_AFTER").
			Wrapf(err, "failed to list transactions updated after timestamp")
	}

	return toDomainTransactions(rows), nil
}

func (r *TransactionRepository) Delete(ctx context.Context, id domain.UUID) error {
	if err := r.queries(ctx).SoftDeleteTransaction(ctx, toPgUUID(id)); err != nil {
		return repoTxErr().
			Code("ERR_TRANSACTION_DELETE").
			With("transaction_id", id.String()).
			Wrapf(err, "failed to soft delete transaction")
	}
	return nil
}

// clampPaginationInt32 safely converts pagination parameters to int32 without silent overflow truncation.
func clampPaginationInt32(limit, offset int) (int32, int32) {
	if limit <= 0 {
		limit = 20
	} else if limit > math.MaxInt32 {
		limit = math.MaxInt32
	}
	if offset < 0 {
		offset = 0
	} else if offset > math.MaxInt32 {
		offset = math.MaxInt32
	}
	return int32(limit), int32(offset)
}

func toPgUUID(id domain.UUID) pgtype.UUID {
	return pgtype.UUID{Bytes: id.Bytes(), Valid: true}
}

func toPgNullableUUID(id *domain.UUID) pgtype.UUID {
	if id == nil || id.IsZero() {
		return pgtype.UUID{Valid: false}
	}
	return pgtype.UUID{Bytes: id.Bytes(), Valid: true}
}

func fromPgNullableUUID(pgID pgtype.UUID) *domain.UUID {
	if !pgID.Valid {
		return nil
	}
	u := domain.FromBytes(pgID.Bytes)
	return &u
}

func toPgTimestamptz(t time.Time) pgtype.Timestamptz {
	return pgtype.Timestamptz{Time: t.UTC(), Valid: true}
}

func toPgNullableTimestamptz(t *time.Time) pgtype.Timestamptz {
	if t == nil {
		return pgtype.Timestamptz{Valid: false}
	}
	return pgtype.Timestamptz{Time: t.UTC(), Valid: true}
}

// toDomainTransactions converts a slice of sqlc rows to domain pointers in O(N) time
// using a single contiguous backing slice allocation to minimize GC heap pressure and prevent memory leaks.
func toDomainTransactions(rows []db.Transaction) []*domain.Transaction {
	n := len(rows)
	if n == 0 {
		return make([]*domain.Transaction, 0)
	}

	values := make([]domain.Transaction, n)
	ptrs := make([]*domain.Transaction, n)
	for i := range rows {
		populateDomainTransaction(&values[i], rows[i])
		ptrs[i] = &values[i]
	}
	return ptrs
}

func populateDomainTransaction(dst *domain.Transaction, row db.Transaction) {
	var deletedAt *time.Time
	if row.DeletedAt.Valid {
		t := row.DeletedAt.Time
		deletedAt = &t
	}

	*dst = domain.Transaction{
		ID:                   domain.FromBytes(row.ID.Bytes),
		AccountID:            domain.FromBytes(row.AccountID.Bytes),
		CategoryID:           fromPgNullableUUID(row.CategoryID),
		DestinationAccountID: fromPgNullableUUID(row.DestinationAccountID),
		Type:                 domain.TransactionType(row.Type),
		Amount:               row.Amount,
		Currency:             row.Currency,
		ExchangeRateToBase:   row.ExchangeRateToBase,
		BaseAmount:           row.BaseAmount,
		Note:                 row.Note,
		IsTalangan:           row.IsTalangan,
		TransactionDate:      row.TransactionDate.Time,
		CreatedAt:            row.CreatedAt.Time,
		UpdatedAt:            row.UpdatedAt.Time,
		DeletedAt:            deletedAt,
	}
}

var _ port.TransactionRepository = (*TransactionRepository)(nil)
