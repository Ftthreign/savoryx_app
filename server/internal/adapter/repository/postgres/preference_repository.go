package postgres

import (
	"context"
	"errors"

	"github.com/ftthreign/savoryx_app/server/internal/adapter/repository/postgres/db"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/samber/oops"
)

type PreferenceRepository struct {
	q *db.Queries
}

func NewPreferenceRepository(d *DB) *PreferenceRepository {
	return &PreferenceRepository{
		q: db.New(d.Pool),
	}
}

func (r *PreferenceRepository) Get(ctx context.Context, id domain.UUID) (*domain.UserPreference, error) {
	pgID := pgtype.UUID{Bytes: id.Bytes(), Valid: true}
	row, err := r.q.GetUserPreferences(ctx, pgID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, oops.
				In("preference_repository").
				Tags("database", "postgres").
				Code("ERR_PREFERENCE_NOT_FOUND").
				With("user_id", id.String()).
				Wrap(domain.ErrPreferenceNotFound)
		}
		return nil, oops.
			In("preference_repository").
			Tags("database", "postgres").
			Code("ERR_PREFERENCE_GET").
			With("user_id", id.String()).
			Wrapf(err, "failed to get user preferences")
	}

	return toDomainPreference(row), nil
}

func (r *PreferenceRepository) Upsert(ctx context.Context, pref *domain.UserPreference) error {
	if pref == nil {
		return oops.
			In("preference_repository").
			Tags("database", "postgres").
			Code("ERR_PREFERENCE_NIL").
			Wrap(domain.ErrInvalidInput)
	}

	params := db.UpsertUserPreferencesParams{
		ID:               pgtype.UUID{Bytes: pref.ID.Bytes(), Valid: true},
		Theme:            db.ThemePreference(pref.Theme),
		FontFamily:       db.FontFamilyType(pref.FontFamily),
		BaseCurrency:     pref.BaseCurrency,
		MonthlyWorkHours: int32(pref.MonthlyWorkHours),
		MonthlyIncomeNet: pref.MonthlyIncomeNet,
	}

	upserted, err := r.q.UpsertUserPreferences(ctx, params)
	if err != nil {
		return oops.
			In("preference_repository").
			Tags("database", "postgres").
			Code("ERR_PREFERENCE_UPSERT").
			With("user_id", pref.ID.String()).
			Wrapf(err, "failed to upsert user preferences")
	}

	*pref = *toDomainPreference(upserted)
	return nil
}

func toDomainPreference(row db.UserPreference) *domain.UserPreference {
	return &domain.UserPreference{
		ID:               domain.FromBytes(row.ID.Bytes),
		Theme:            domain.ThemePreference(row.Theme),
		FontFamily:       domain.FontFamilyType(row.FontFamily),
		BaseCurrency:     row.BaseCurrency,
		MonthlyWorkHours: int(row.MonthlyWorkHours),
		MonthlyIncomeNet: row.MonthlyIncomeNet,
		UpdatedAt:        row.UpdatedAt.Time,
	}
}

var _ port.PreferenceRepository = (*PreferenceRepository)(nil)
