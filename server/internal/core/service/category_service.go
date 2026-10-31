package service

import (
	"context"
	"regexp"
	"strings"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/samber/oops"
)

var hexColorRegex = regexp.MustCompile(`^#(?:[0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$`)

type categoryService struct {
	repo port.CategoryRepository
}

func NewCategoryService(repo port.CategoryRepository) port.CategoryService {
	return &categoryService{
		repo: repo,
	}
}

func (s *categoryService) CreateCategory(ctx context.Context, cat *domain.Category) error {
	if cat == nil {
		return oops.
			In("category_service").
			Code("ERR_INVALID_CATEGORY").
			Wrapf(domain.ErrInvalidInput, "category entity cannot be nil")
	}

	if cat.ID.IsZero() {
		return oops.
			In("category_service").
			Code("ERR_INVALID_CATEGORY_ID").
			Wrapf(domain.ErrInvalidInput, "category ID cannot be nil or zero")
	}

	trimmedName := strings.TrimSpace(cat.Name)
	if len(trimmedName) == 0 || len(trimmedName) > 64 {
		return oops.
			In("category_service").
			Code("ERR_INVALID_CATEGORY_NAME").
			Wrapf(domain.ErrInvalidInput, "category name must be between 1 and 64 characters")
	}
	cat.Name = trimmedName

	trimmedIcon := strings.TrimSpace(cat.Icon)
	if len(trimmedIcon) == 0 || len(trimmedIcon) > 32 {
		return oops.
			In("category_service").
			Code("ERR_INVALID_CATEGORY_ICON").
			Wrapf(domain.ErrInvalidInput, "category icon must be between 1 and 32 characters")
	}
	cat.Icon = trimmedIcon

	trimmedColor := strings.ToUpper(strings.TrimSpace(cat.Color))
	if !hexColorRegex.MatchString(trimmedColor) {
		return oops.
			In("category_service").
			Code("ERR_INVALID_HEX_COLOR").
			With("color", cat.Color).
			Wrapf(domain.ErrInvalidInput, "invalid hex color format, expected #RGB or #RRGGBB")
	}
	cat.Color = trimmedColor

	now := time.Now().UTC()
	if cat.CreatedAt.IsZero() {
		cat.CreatedAt = now
	}
	if cat.UpdatedAt.IsZero() {
		cat.UpdatedAt = now
	}

	if err := s.repo.Create(ctx, cat); err != nil {
		return oops.
			In("category_service").
			Code("ERR_CATEGORY_CREATE_FAILED").
			With("category_id", cat.ID.String()).
			Wrapf(err, "failed to persist category")
	}

	return nil
}

func (s *categoryService) GetCategory(ctx context.Context, id domain.UUID) (*domain.Category, error) {
	if id.IsZero() {
		return nil, oops.
			In("category_service").
			Code("ERR_INVALID_CATEGORY_ID").
			Wrapf(domain.ErrInvalidInput, "category ID cannot be nil or zero")
	}

	cat, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if cat == nil {
		return nil, oops.
			In("category_service").
			Code("ERR_CATEGORY_NOT_FOUND").
			With("category_id", id.String()).
			Wrap(domain.ErrCategoryNotFound)
	}

	return cat, nil
}

func (s *categoryService) ListCategories(ctx context.Context) ([]*domain.Category, error) {
	categories, err := s.repo.List(ctx)
	if err != nil {
		return nil, oops.
			In("category_service").
			Code("ERR_CATEGORY_LIST_FAILED").
			Wrapf(err, "failed to list categories")
	}

	if categories == nil {
		categories = make([]*domain.Category, 0)
	}
	return categories, nil
}

// DeleteCategory soft-deletes a category after verifying its existence.
func (s *categoryService) DeleteCategory(ctx context.Context, id domain.UUID) error {
	if id.IsZero() {
		return oops.
			In("category_service").
			Code("ERR_INVALID_CATEGORY_ID").
			Wrapf(domain.ErrInvalidInput, "category ID cannot be nil or zero")
	}

	cat, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return err
	}
	if cat == nil {
		return oops.
			In("category_service").
			Code("ERR_CATEGORY_NOT_FOUND").
			With("category_id", id.String()).
			Wrap(domain.ErrCategoryNotFound)
	}

	if err := s.repo.Delete(ctx, id); err != nil {
		return oops.
			In("category_service").
			Code("ERR_CATEGORY_DELETE_FAILED").
			With("category_id", id.String()).
			Wrapf(err, "failed to delete category")
	}

	return nil
}

var _ port.CategoryService = (*categoryService)(nil)
