package service_test

import (
	"context"
	"errors"
	"testing"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/core/service"
	"github.com/ftthreign/savoryx_app/server/internal/testutil"
	"github.com/ftthreign/savoryx_app/server/internal/testutil/mocks"
	"github.com/shopspring/decimal"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestAccountService_CreateAccount(t *testing.T) {
	ctx := context.Background()
	validID := testutil.DefaultDeviceID

	t.Run("happy path - creates account and defaults currency to IDR", func(t *testing.T) {
		var captured *domain.Account
		repo := &mocks.MockAccountRepository{
			CreateFunc: func(ctx context.Context, acc *domain.Account) error {
				captured = acc
				return nil
			},
		}

		svc := service.NewAccountService(repo)
		acc := &domain.Account{
			ID:      validID,
			Name:    "Main BCA Account",
			Type:    domain.AccountTypeBank,
			Balance: decimal.NewFromInt(5000000),
		}

		err := svc.CreateAccount(ctx, acc)
		require.NoError(t, err)
		require.NotNil(t, captured)
		assert.Equal(t, "IDR", captured.Currency)
		assert.Equal(t, "Main BCA Account", captured.Name)
		assert.False(t, captured.CreatedAt.IsZero())
		assert.False(t, captured.UpdatedAt.IsZero())
	})

	t.Run("validation failure - nil account", func(t *testing.T) {
		repo := &mocks.MockAccountRepository{}
		svc := service.NewAccountService(repo)

		err := svc.CreateAccount(ctx, nil)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrInvalidInput))
	})

	t.Run("validation failure - zero ID", func(t *testing.T) {
		repo := &mocks.MockAccountRepository{}
		svc := service.NewAccountService(repo)

		acc := &domain.Account{
			ID:      domain.NilUUID,
			Name:    "Wallet",
			Type:    domain.AccountTypeCash,
			Balance: decimal.Zero,
		}

		err := svc.CreateAccount(ctx, acc)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrInvalidInput))
	})

	t.Run("validation failure - empty name", func(t *testing.T) {
		repo := &mocks.MockAccountRepository{}
		svc := service.NewAccountService(repo)

		acc := &domain.Account{
			ID:      validID,
			Name:    "   ",
			Type:    domain.AccountTypeCash,
			Balance: decimal.Zero,
		}

		err := svc.CreateAccount(ctx, acc)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrInvalidInput))
	})

	t.Run("validation failure - invalid account type", func(t *testing.T) {
		repo := &mocks.MockAccountRepository{}
		svc := service.NewAccountService(repo)

		acc := &domain.Account{
			ID:      validID,
			Name:    "Crypto Stash",
			Type:    domain.AccountType("UNKNOWN_CRYPTO"),
			Balance: decimal.Zero,
		}

		err := svc.CreateAccount(ctx, acc)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrInvalidInput))
	})

	t.Run("repository error on create", func(t *testing.T) {
		dbErr := errors.New("unique constraint violation")
		repo := &mocks.MockAccountRepository{
			CreateFunc: func(ctx context.Context, acc *domain.Account) error {
				return dbErr
			},
		}
		svc := service.NewAccountService(repo)

		acc := &domain.Account{
			ID:      validID,
			Name:    "Emergency Cash",
			Type:    domain.AccountTypeCash,
			Balance: decimal.NewFromInt(1000000),
		}

		err := svc.CreateAccount(ctx, acc)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, dbErr))
	})
}

func TestAccountService_GetAccount(t *testing.T) {
	ctx := context.Background()
	validID := testutil.DefaultDeviceID

	t.Run("happy path - returns account by id", func(t *testing.T) {
		expectedAcc := &domain.Account{
			ID:      validID,
			Name:    "Bank Jago",
			Type:    domain.AccountTypeBank,
			Balance: decimal.NewFromInt(2500000),
		}
		repo := &mocks.MockAccountRepository{
			GetByIDFunc: func(ctx context.Context, id domain.UUID) (*domain.Account, error) {
				assert.Equal(t, validID, id)
				return expectedAcc, nil
			},
		}
		svc := service.NewAccountService(repo)

		acc, err := svc.GetAccount(ctx, validID)
		require.NoError(t, err)
		assert.Equal(t, expectedAcc, acc)
	})

	t.Run("validation failure - zero ID", func(t *testing.T) {
		repo := &mocks.MockAccountRepository{}
		svc := service.NewAccountService(repo)

		_, err := svc.GetAccount(ctx, domain.NilUUID)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrInvalidInput))
	})

	t.Run("account not found", func(t *testing.T) {
		repo := &mocks.MockAccountRepository{
			GetByIDFunc: func(ctx context.Context, id domain.UUID) (*domain.Account, error) {
				return nil, nil
			},
		}
		svc := service.NewAccountService(repo)

		acc, err := svc.GetAccount(ctx, validID)
		assert.Nil(t, acc)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrAccountNotFound))
	})

	t.Run("repository error", func(t *testing.T) {
		dbErr := errors.New("connection timeout")
		repo := &mocks.MockAccountRepository{
			GetByIDFunc: func(ctx context.Context, id domain.UUID) (*domain.Account, error) {
				return nil, dbErr
			},
		}
		svc := service.NewAccountService(repo)

		_, err := svc.GetAccount(ctx, validID)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, dbErr))
	})
}

func TestAccountService_ListAccounts(t *testing.T) {
	ctx := context.Background()

	t.Run("happy path - returns list of accounts", func(t *testing.T) {
		expectedList := []*domain.Account{
			{ID: testutil.DefaultDeviceID, Name: "Cash", Type: domain.AccountTypeCash},
			{ID: domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000002"), Name: "Bank", Type: domain.AccountTypeBank},
		}
		repo := &mocks.MockAccountRepository{
			ListFunc: func(ctx context.Context) ([]*domain.Account, error) {
				return expectedList, nil
			},
		}
		svc := service.NewAccountService(repo)

		list, err := svc.ListAccounts(ctx)
		require.NoError(t, err)
		assert.Len(t, list, 2)
	})

	t.Run("empty list returns non-nil slice", func(t *testing.T) {
		repo := &mocks.MockAccountRepository{
			ListFunc: func(ctx context.Context) ([]*domain.Account, error) {
				return nil, nil
			},
		}
		svc := service.NewAccountService(repo)

		list, err := svc.ListAccounts(ctx)
		require.NoError(t, err)
		assert.NotNil(t, list)
		assert.Empty(t, list)
	})

	t.Run("repository error", func(t *testing.T) {
		dbErr := errors.New("read replica down")
		repo := &mocks.MockAccountRepository{
			ListFunc: func(ctx context.Context) ([]*domain.Account, error) {
				return nil, dbErr
			},
		}
		svc := service.NewAccountService(repo)

		_, err := svc.ListAccounts(ctx)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, dbErr))
	})
}

func TestAccountService_UpdateBalance(t *testing.T) {
	ctx := context.Background()
	validID := testutil.DefaultDeviceID
	newBal := decimal.NewFromInt(12500000)

	t.Run("happy path - acquires row lock and updates balance", func(t *testing.T) {
		lockAcquired := false
		balanceUpdated := false

		repo := &mocks.MockAccountRepository{
			GetByIDForUpdateFunc: func(ctx context.Context, id domain.UUID) (*domain.Account, error) {
				assert.Equal(t, validID, id)
				lockAcquired = true
				return &domain.Account{
					ID:      id,
					Name:    "Mandiri Checking",
					Balance: decimal.NewFromInt(10000000),
				}, nil
			},
			UpdateBalanceFunc: func(ctx context.Context, id domain.UUID, balance decimal.Decimal) error {
				assert.Equal(t, validID, id)
				assert.Equal(t, newBal, balance)
				balanceUpdated = true
				return nil
			},
		}
		svc := service.NewAccountService(repo)

		err := svc.UpdateBalance(ctx, validID, newBal)
		require.NoError(t, err)
		assert.True(t, lockAcquired, "must acquire pessimistic row lock")
		assert.True(t, balanceUpdated, "must update balance")
	})

	t.Run("validation failure - zero ID", func(t *testing.T) {
		repo := &mocks.MockAccountRepository{}
		svc := service.NewAccountService(repo)

		err := svc.UpdateBalance(ctx, domain.NilUUID, newBal)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrInvalidInput))
	})

	t.Run("account not found during row lock", func(t *testing.T) {
		repo := &mocks.MockAccountRepository{
			GetByIDForUpdateFunc: func(ctx context.Context, id domain.UUID) (*domain.Account, error) {
				return nil, nil
			},
		}
		svc := service.NewAccountService(repo)

		err := svc.UpdateBalance(ctx, validID, newBal)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrAccountNotFound))
	})

	t.Run("repository error during row lock", func(t *testing.T) {
		dbErr := errors.New("deadlock detected")
		repo := &mocks.MockAccountRepository{
			GetByIDForUpdateFunc: func(ctx context.Context, id domain.UUID) (*domain.Account, error) {
				return nil, dbErr
			},
		}
		svc := service.NewAccountService(repo)

		err := svc.UpdateBalance(ctx, validID, newBal)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, dbErr))
	})

	t.Run("repository error during update balance", func(t *testing.T) {
		dbErr := errors.New("disk full")
		repo := &mocks.MockAccountRepository{
			GetByIDForUpdateFunc: func(ctx context.Context, id domain.UUID) (*domain.Account, error) {
				return &domain.Account{ID: id}, nil
			},
			UpdateBalanceFunc: func(ctx context.Context, id domain.UUID, balance decimal.Decimal) error {
				return dbErr
			},
		}
		svc := service.NewAccountService(repo)

		err := svc.UpdateBalance(ctx, validID, newBal)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, dbErr))
	})
}

func TestAccountService_DeleteAccount(t *testing.T) {
	ctx := context.Background()
	validID := testutil.DefaultDeviceID

	t.Run("happy path - verifies existence and deletes", func(t *testing.T) {
		deleteCalled := false
		repo := &mocks.MockAccountRepository{
			GetByIDFunc: func(ctx context.Context, id domain.UUID) (*domain.Account, error) {
				assert.Equal(t, validID, id)
				return &domain.Account{ID: id, Name: "To Delete"}, nil
			},
			DeleteFunc: func(ctx context.Context, id domain.UUID) error {
				assert.Equal(t, validID, id)
				deleteCalled = true
				return nil
			},
		}
		svc := service.NewAccountService(repo)

		err := svc.DeleteAccount(ctx, validID)
		require.NoError(t, err)
		assert.True(t, deleteCalled)
	})

	t.Run("validation failure - zero ID", func(t *testing.T) {
		repo := &mocks.MockAccountRepository{}
		svc := service.NewAccountService(repo)

		err := svc.DeleteAccount(ctx, domain.NilUUID)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrInvalidInput))
	})

	t.Run("account not found", func(t *testing.T) {
		repo := &mocks.MockAccountRepository{
			GetByIDFunc: func(ctx context.Context, id domain.UUID) (*domain.Account, error) {
				return nil, nil
			},
		}
		svc := service.NewAccountService(repo)

		err := svc.DeleteAccount(ctx, validID)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, domain.ErrAccountNotFound))
	})

	t.Run("repository error on delete", func(t *testing.T) {
		dbErr := errors.New("foreign key constraint")
		repo := &mocks.MockAccountRepository{
			GetByIDFunc: func(ctx context.Context, id domain.UUID) (*domain.Account, error) {
				return &domain.Account{ID: id}, nil
			},
			DeleteFunc: func(ctx context.Context, id domain.UUID) error {
				return dbErr
			},
		}
		svc := service.NewAccountService(repo)

		err := svc.DeleteAccount(ctx, validID)
		assert.Error(t, err)
		assert.True(t, errors.Is(err, dbErr))
	})
}
