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
)

type CategoryRepository struct {
	q *db.Queries
}

func NewCategoryRepository(d *DB) *CategoryRepository {
	return &CategoryRepository{
		q: db.New(d.Pool),
	}
}

func (r *CategoryRepository) Create(ctx context.Context, cat *domain.Category) error {
	if cat == nil {
		return oops.
			In("category_repository").
			Tags("database", "postgres").
			Code("ERR_CATEGORY_NIL").
			Wrap(domain.ErrInvalidInput)
	}

	params := db.CreateCategoryParams{
		ID:      pgtype.UUID{Bytes: cat.ID.Bytes(), Valid: true},
		Name:    cat.Name,
		Icon:    cat.Icon,
		Color:   cat.Color,
		IsWants: cat.IsWants,
	}

	created, err := r.q.CreateCategory(ctx, params)
	if err != nil {
		return oops.
			In("category_repository").
			Tags("database", "postgres").
			Code("ERR_CATEGORY_CREATE").
			With("category_name", cat.Name).
			Wrapf(err, "failed to insert category record")
	}

	*cat = *toDomainCategory(created)
	return nil
}

func (r *CategoryRepository) GetByID(ctx context.Context, id domain.UUID) (*domain.Category, error) {
	pgID := pgtype.UUID{Bytes: id.Bytes(), Valid: true}
	row, err := r.q.GetCategoryByID(ctx, pgID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, oops.
				In("category_repository").
				Tags("database", "postgres").
				Code("ERR_CATEGORY_NOT_FOUND").
				With("category_id", id.String()).
				Wrap(domain.ErrCategoryNotFound)
		}
		return nil, oops.
			In("category_repository").
			Tags("database", "postgres").
			Code("ERR_CATEGORY_GET").
			With("category_id", id.String()).
			Wrapf(err, "failed to get category by id")
	}

	return toDomainCategory(row), nil
}

func (r *CategoryRepository) List(ctx context.Context) ([]*domain.Category, error) {
	rows, err := r.q.ListCategories(ctx)
	if err != nil {
		return nil, oops.
			In("category_repository").
			Tags("database", "postgres").
			Code("ERR_CATEGORY_LIST").
			Wrapf(err, "failed to list categories")
	}

	result := make([]*domain.Category, len(rows))
	for i, row := range rows {
		result[i] = toDomainCategory(row)
	}
	return result, nil
}

func (r *CategoryRepository) Update(ctx context.Context, cat *domain.Category) error {
	if cat == nil {
		return oops.
			In("category_repository").
			Tags("database", "postgres").
			Code("ERR_CATEGORY_INVALID_INPUT").
			Wrap(domain.ErrInvalidInput)
	}

	params := db.UpdateCategoryParams{
		ID:      pgtype.UUID{Bytes: cat.ID.Bytes(), Valid: true},
		Name:    cat.Name,
		Icon:    cat.Icon,
		Color:   cat.Color,
		IsWants: cat.IsWants,
	}

	updated, err := r.q.UpdateCategory(ctx, params)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return oops.
				In("category_repository").
				Tags("database", "postgres").
				Code("ERR_CATEGORY_NOT_FOUND").
				With("category_id", cat.ID.String()).
				Wrap(domain.ErrCategoryNotFound)
		}
		return oops.
			In("category_repository").
			Tags("database", "postgres").
			Code("ERR_CATEGORY_UPDATE").
			With("category_id", cat.ID.String()).
			Wrapf(err, "failed to update category")
	}

	*cat = *toDomainCategory(updated)
	return nil
}

func (r *CategoryRepository) Delete(ctx context.Context, id domain.UUID) error {
	pgID := pgtype.UUID{Bytes: id.Bytes(), Valid: true}
	err := r.q.SoftDeleteCategory(ctx, pgID)
	if err != nil {
		return oops.
			In("category_repository").
			Tags("database", "postgres").
			Code("ERR_CATEGORY_DELETE").
			With("category_id", id.String()).
			Wrapf(err, "failed to soft delete category")
	}

	return nil
}

func toDomainCategory(row db.Category) *domain.Category {
	var deletedAt *time.Time
	if row.DeletedAt.Valid {
		t := row.DeletedAt.Time
		deletedAt = &t
	}

	return &domain.Category{
		ID:        domain.FromBytes(row.ID.Bytes),
		Name:      row.Name,
		Icon:      row.Icon,
		Color:     row.Color,
		IsWants:   row.IsWants,
		CreatedAt: row.CreatedAt.Time,
		UpdatedAt: row.UpdatedAt.Time,
		DeletedAt: deletedAt,
	}
}

var _ port.CategoryRepository = (*CategoryRepository)(nil)
