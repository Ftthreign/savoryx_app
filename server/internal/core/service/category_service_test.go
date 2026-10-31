package service_test

import (
	"context"
	"errors"
	"strings"
	"testing"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/core/service"
	"github.com/ftthreign/savoryx_app/server/internal/testutil"
	"github.com/ftthreign/savoryx_app/server/internal/testutil/mocks"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestCategoryService_CreateCategory(t *testing.T) {
	ctx := context.Background()
	validID := testutil.DefaultDeviceID

	t.Run("happy path - creates needs category with 6-digit hex color", func(t *testing.T) {
		var captured *domain.Category
		repo := &mocks.MockCategoryRepository{
			CreateFunc: func(ctx context.Context, cat *domain.Category) error {
				captured = cat
				return nil
			},
		}
		svc := service.NewCategoryService(repo)

		cat := &domain.Category{
			ID:      validID,
			Name:    " Groceries ",
			Icon:    "shopping_cart",
			Color:   "#8db355",
			IsWants: false,
		}

		err := svc.CreateCategory(ctx, cat)
		require.NoError(t, err)
		require.NotNil(t, captured)
		assert.Equal(t, "Groceries", captured.Name)
		assert.Equal(t, "shopping_cart", captured.Icon)
		assert.Equal(t, "#8DB355", captured.Color)
		assert.False(t, captured.IsWants)
		assert.False(t, captured.CreatedAt.IsZero())
		assert.False(t, captured.UpdatedAt.IsZero())
	})

	t.Run("happy path - creates wants category with 3-digit hex color", func(t *testing.T) {
		var captured *domain.Category
		repo := &mocks.MockCategoryRepository{
			CreateFunc: func(ctx context.Context, cat *domain.Category) error {
				captured = cat
				return nil
			},
		}
		svc := service.NewCategoryService(repo)

		cat := &domain.Category{
			ID:      validID,
			Name:    "Netflix & Chill",
			Icon:    "movie",
			Color:   "#abc",
			IsWants: true,
		}

		err := svc.CreateCategory(ctx, cat)
		require.NoError(t, err)
		require.NotNil(t, captured)
		assert.Equal(t, "#ABC", captured.Color)
		assert.True(t, captured.IsWants)
	})

	t.Run("validation failure - nil category", func(t *testing.T) {
		repo := &mocks.MockCategoryRepository{}
		svc := service.NewCategoryService(repo)

		err := svc.CreateCategory(ctx, nil)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrInvalidInput))
	})

	t.Run("validation failure - zero ID", func(t *testing.T) {
		repo := &mocks.MockCategoryRepository{}
		svc := service.NewCategoryService(repo)

		cat := &domain.Category{
			ID:      domain.NilUUID,
			Name:    "Food",
			Icon:    "fastfood",
			Color:   "#FFFFFF",
			IsWants: false,
		}

		err := svc.CreateCategory(ctx, cat)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrInvalidInput))
	})

	t.Run("validation failure - empty name", func(t *testing.T) {
		repo := &mocks.MockCategoryRepository{}
		svc := service.NewCategoryService(repo)

		cat := &domain.Category{
			ID:      validID,
			Name:    "   ",
			Icon:    "fastfood",
			Color:   "#FFFFFF",
			IsWants: false,
		}

		err := svc.CreateCategory(ctx, cat)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrInvalidInput))
	})

	t.Run("validation failure - name exceeds 64 characters", func(t *testing.T) {
		repo := &mocks.MockCategoryRepository{}
		svc := service.NewCategoryService(repo)

		cat := &domain.Category{
			ID:      validID,
			Name:    strings.Repeat("a", 65),
			Icon:    "fastfood",
			Color:   "#FFFFFF",
			IsWants: false,
		}

		err := svc.CreateCategory(ctx, cat)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrInvalidInput))
	})

	t.Run("validation failure - empty icon", func(t *testing.T) {
		repo := &mocks.MockCategoryRepository{}
		svc := service.NewCategoryService(repo)

		cat := &domain.Category{
			ID:      validID,
			Name:    "Food",
			Icon:    "   ",
			Color:   "#FFFFFF",
			IsWants: false,
		}

		err := svc.CreateCategory(ctx, cat)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrInvalidInput))
	})

	t.Run("validation failure - icon exceeds 32 characters", func(t *testing.T) {
		repo := &mocks.MockCategoryRepository{}
		svc := service.NewCategoryService(repo)

		cat := &domain.Category{
			ID:      validID,
			Name:    "Food",
			Icon:    strings.Repeat("i", 33),
			Color:   "#FFFFFF",
			IsWants: false,
		}

		err := svc.CreateCategory(ctx, cat)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrInvalidInput))
	})

	t.Run("validation failure - invalid hex colors", func(t *testing.T) {
		invalidColors := []string{
			"red",
			"#12",
			"#1234",
			"#12345",
			"#1234567",
			"123456",
			"#GGGGGG",
			"",
		}

		for _, color := range invalidColors {
			t.Run("color: "+color, func(t *testing.T) {
				repo := &mocks.MockCategoryRepository{}
				svc := service.NewCategoryService(repo)

				cat := &domain.Category{
					ID:      validID,
					Name:    "Valid Name",
					Icon:    "valid_icon",
					Color:   color,
					IsWants: false,
				}

				err := svc.CreateCategory(ctx, cat)
				assert.Error(t, err)
				assert.True(t, errors.Is(err, domain.ErrInvalidInput))
			})
		}
	})

	t.Run("repository error on create", func(t *testing.T) {
		dbErr := errors.New("duplicate key violates unique constraint")
		repo := &mocks.MockCategoryRepository{
			CreateFunc: func(ctx context.Context, cat *domain.Category) error {
				return dbErr
			},
		}
		svc := service.NewCategoryService(repo)

		cat := &domain.Category{
			ID:      validID,
			Name:    "Food",
			Icon:    "fastfood",
			Color:   "#FFFFFF",
			IsWants: false,
		}

		err := svc.CreateCategory(ctx, cat)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, dbErr))
	})
}

func TestCategoryService_GetCategory(t *testing.T) {
	ctx := context.Background()
	validID := testutil.DefaultDeviceID

	t.Run("happy path - returns category by ID", func(t *testing.T) {
		expectedCat := &domain.Category{
			ID:      validID,
			Name:    "Transport",
			Icon:    "directions_car",
			Color:   "#4A90E2",
			IsWants: false,
		}
		repo := &mocks.MockCategoryRepository{
			GetByIDFunc: func(ctx context.Context, id domain.UUID) (*domain.Category, error) {
				assert.Equal(t, validID, id)
				return expectedCat, nil
			},
		}
		svc := service.NewCategoryService(repo)

		cat, err := svc.GetCategory(ctx, validID)
		require.NoError(t, err)
		assert.Equal(t, expectedCat, cat)
	})

	t.Run("validation failure - zero ID", func(t *testing.T) {
		repo := &mocks.MockCategoryRepository{}
		svc := service.NewCategoryService(repo)

		_, err := svc.GetCategory(ctx, domain.NilUUID)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrInvalidInput))
	})

	t.Run("category not found", func(t *testing.T) {
		repo := &mocks.MockCategoryRepository{
			GetByIDFunc: func(ctx context.Context, id domain.UUID) (*domain.Category, error) {
				return nil, nil
			},
		}
		svc := service.NewCategoryService(repo)

		cat, err := svc.GetCategory(ctx, validID)
		assert.Nil(t, cat)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrCategoryNotFound))
	})

	t.Run("repository error", func(t *testing.T) {
		dbErr := errors.New("database connection refused")
		repo := &mocks.MockCategoryRepository{
			GetByIDFunc: func(ctx context.Context, id domain.UUID) (*domain.Category, error) {
				return nil, dbErr
			},
		}
		svc := service.NewCategoryService(repo)

		_, err := svc.GetCategory(ctx, validID)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, dbErr))
	})
}

func TestCategoryService_ListCategories(t *testing.T) {
	ctx := context.Background()

	t.Run("happy path - returns list of categories", func(t *testing.T) {
		expected := []*domain.Category{
			{ID: testutil.DefaultDeviceID, Name: "Needs", IsWants: false},
			{ID: domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000002"), Name: "Wants", IsWants: true},
		}
		repo := &mocks.MockCategoryRepository{
			ListFunc: func(ctx context.Context) ([]*domain.Category, error) {
				return expected, nil
			},
		}
		svc := service.NewCategoryService(repo)

		list, err := svc.ListCategories(ctx)
		require.NoError(t, err)
		assert.Len(t, list, 2)
	})

	t.Run("empty list returns non-nil empty slice", func(t *testing.T) {
		repo := &mocks.MockCategoryRepository{
			ListFunc: func(ctx context.Context) ([]*domain.Category, error) {
				return nil, nil
			},
		}
		svc := service.NewCategoryService(repo)

		list, err := svc.ListCategories(ctx)
		require.NoError(t, err)
		assert.NotNil(t, list)
		assert.Empty(t, list)
	})

	t.Run("repository error", func(t *testing.T) {
		dbErr := errors.New("query failed")
		repo := &mocks.MockCategoryRepository{
			ListFunc: func(ctx context.Context) ([]*domain.Category, error) {
				return nil, dbErr
			},
		}
		svc := service.NewCategoryService(repo)

		_, err := svc.ListCategories(ctx)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, dbErr))
	})
}

func TestCategoryService_DeleteCategory(t *testing.T) {
	ctx := context.Background()
	validID := testutil.DefaultDeviceID

	t.Run("happy path - verifies existence and deletes", func(t *testing.T) {
		deleteCalled := false
		repo := &mocks.MockCategoryRepository{
			GetByIDFunc: func(ctx context.Context, id domain.UUID) (*domain.Category, error) {
				assert.Equal(t, validID, id)
				return &domain.Category{ID: id, Name: "Old Category"}, nil
			},
			DeleteFunc: func(ctx context.Context, id domain.UUID) error {
				assert.Equal(t, validID, id)
				deleteCalled = true
				return nil
			},
		}
		svc := service.NewCategoryService(repo)

		err := svc.DeleteCategory(ctx, validID)
		require.NoError(t, err)
		assert.True(t, deleteCalled)
	})

	t.Run("validation failure - zero ID", func(t *testing.T) {
		repo := &mocks.MockCategoryRepository{}
		svc := service.NewCategoryService(repo)

		err := svc.DeleteCategory(ctx, domain.NilUUID)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrInvalidInput))
	})

	t.Run("category not found", func(t *testing.T) {
		repo := &mocks.MockCategoryRepository{
			GetByIDFunc: func(ctx context.Context, id domain.UUID) (*domain.Category, error) {
				return nil, nil
			},
		}
		svc := service.NewCategoryService(repo)

		err := svc.DeleteCategory(ctx, validID)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrCategoryNotFound))
	})

	t.Run("repository error on delete", func(t *testing.T) {
		dbErr := errors.New("foreign key reference constraint")
		repo := &mocks.MockCategoryRepository{
			GetByIDFunc: func(ctx context.Context, id domain.UUID) (*domain.Category, error) {
				return &domain.Category{ID: id}, nil
			},
			DeleteFunc: func(ctx context.Context, id domain.UUID) error {
				return dbErr
			},
		}
		svc := service.NewCategoryService(repo)

		err := svc.DeleteCategory(ctx, validID)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, dbErr))
	})
}

func TestCategoryService_UpdateCategory(t *testing.T) {
	ctx := context.Background()
	validID := testutil.DefaultDeviceID

	t.Run("happy path - updates category properties", func(t *testing.T) {
		repo := &mocks.MockCategoryRepository{
			GetByIDFunc: func(ctx context.Context, id domain.UUID) (*domain.Category, error) {
				return &domain.Category{
					ID:      id,
					Name:    "Old Name",
					Icon:    "old_icon",
					Color:   "#111111",
					IsWants: false,
				}, nil
			},
			UpdateFunc: func(ctx context.Context, cat *domain.Category) error {
				assert.Equal(t, "New Name", cat.Name)
				assert.Equal(t, "new_icon", cat.Icon)
				assert.Equal(t, "#222222", cat.Color)
				assert.Equal(t, true, cat.IsWants)
				return nil
			},
		}
		svc := service.NewCategoryService(repo)

		updated, err := svc.UpdateCategory(ctx, validID, "New Name", "new_icon", "#222222", true)
		assert.NoError(t, err)
		assert.NotNil(t, updated)
		assert.Equal(t, "New Name", updated.Name)
		assert.Equal(t, true, updated.IsWants)
	})

	t.Run("validation failure - zero ID", func(t *testing.T) {
		repo := &mocks.MockCategoryRepository{}
		svc := service.NewCategoryService(repo)

		_, err := svc.UpdateCategory(ctx, domain.NilUUID, "Name", "icon", "#FFFFFF", false)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrInvalidInput))
	})

	t.Run("validation failure - empty name", func(t *testing.T) {
		repo := &mocks.MockCategoryRepository{}
		svc := service.NewCategoryService(repo)

		_, err := svc.UpdateCategory(ctx, validID, "   ", "icon", "#FFFFFF", false)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrInvalidInput))
	})

	t.Run("validation failure - invalid hex color", func(t *testing.T) {
		repo := &mocks.MockCategoryRepository{}
		svc := service.NewCategoryService(repo)

		_, err := svc.UpdateCategory(ctx, validID, "Name", "icon", "red", false)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrInvalidInput))
	})

	t.Run("category not found", func(t *testing.T) {
		repo := &mocks.MockCategoryRepository{
			GetByIDFunc: func(ctx context.Context, id domain.UUID) (*domain.Category, error) {
				return nil, nil
			},
		}
		svc := service.NewCategoryService(repo)

		_, err := svc.UpdateCategory(ctx, validID, "Name", "icon", "#FFFFFF", false)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrCategoryNotFound))
	})
}

