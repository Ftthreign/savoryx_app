package mocks

import (
	"context"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/shopspring/decimal"
)

// MockDatabasePinger implements port.DatabasePinger for unit testing.
type MockDatabasePinger struct {
	PingFunc func(ctx context.Context) error
	PingErr  error
}

func (m *MockDatabasePinger) Ping(ctx context.Context) error {
	if m.PingFunc != nil {
		return m.PingFunc(ctx)
	}
	return m.PingErr
}

var _ port.DatabasePinger = (*MockDatabasePinger)(nil)

// MockDeviceRepository implements port.DeviceRepository for unit testing.
type MockDeviceRepository struct {
	RegisterFunc         func(ctx context.Context, dev *domain.Device) error
	GetByIDFunc          func(ctx context.Context, id domain.UUID) (*domain.Device, error)
	UpdateLastActiveFunc func(ctx context.Context, id domain.UUID) error
	RevokeFunc           func(ctx context.Context, id domain.UUID) error
}

func (m *MockDeviceRepository) Register(ctx context.Context, dev *domain.Device) error {
	if m.RegisterFunc != nil {
		return m.RegisterFunc(ctx, dev)
	}
	return nil
}

func (m *MockDeviceRepository) GetByID(ctx context.Context, id domain.UUID) (*domain.Device, error) {
	if m.GetByIDFunc != nil {
		return m.GetByIDFunc(ctx, id)
	}
	return nil, nil
}

func (m *MockDeviceRepository) UpdateLastActive(ctx context.Context, id domain.UUID) error {
	if m.UpdateLastActiveFunc != nil {
		return m.UpdateLastActiveFunc(ctx, id)
	}
	return nil
}

func (m *MockDeviceRepository) Revoke(ctx context.Context, id domain.UUID) error {
	if m.RevokeFunc != nil {
		return m.RevokeFunc(ctx, id)
	}
	return nil
}

var _ port.DeviceRepository = (*MockDeviceRepository)(nil)

// MockAccountRepository implements port.AccountRepository for unit testing.
type MockAccountRepository struct {
	CreateFunc           func(ctx context.Context, acc *domain.Account) error
	GetByIDFunc          func(ctx context.Context, id domain.UUID) (*domain.Account, error)
	GetByIDForUpdateFunc func(ctx context.Context, id domain.UUID) (*domain.Account, error)
	ListFunc             func(ctx context.Context, limit, offset int) ([]*domain.Account, error)
	CountFunc            func(ctx context.Context) (int, error)
	UpdateFunc           func(ctx context.Context, acc *domain.Account) error
	UpdateBalanceFunc    func(ctx context.Context, id domain.UUID, balance decimal.Decimal) error
	DeleteFunc           func(ctx context.Context, id domain.UUID) error
	ListUpdatedAfterFunc func(ctx context.Context, since time.Time) ([]*domain.Account, error)
	UpsertSyncFunc       func(ctx context.Context, acc *domain.Account) error
}

func (m *MockAccountRepository) Create(ctx context.Context, acc *domain.Account) error {
	if m.CreateFunc != nil {
		return m.CreateFunc(ctx, acc)
	}
	return nil
}

func (m *MockAccountRepository) GetByID(ctx context.Context, id domain.UUID) (*domain.Account, error) {
	if m.GetByIDFunc != nil {
		return m.GetByIDFunc(ctx, id)
	}
	return nil, nil
}

func (m *MockAccountRepository) GetByIDForUpdate(ctx context.Context, id domain.UUID) (*domain.Account, error) {
	if m.GetByIDForUpdateFunc != nil {
		return m.GetByIDForUpdateFunc(ctx, id)
	}
	return nil, nil
}

func (m *MockAccountRepository) List(ctx context.Context, limit, offset int) ([]*domain.Account, error) {
	if m.ListFunc != nil {
		return m.ListFunc(ctx, limit, offset)
	}
	return nil, nil
}

func (m *MockAccountRepository) Count(ctx context.Context) (int, error) {
	if m.CountFunc != nil {
		return m.CountFunc(ctx)
	}
	return 0, nil
}

func (m *MockAccountRepository) Update(ctx context.Context, acc *domain.Account) error {
	if m.UpdateFunc != nil {
		return m.UpdateFunc(ctx, acc)
	}
	return nil
}

func (m *MockAccountRepository) UpdateBalance(ctx context.Context, id domain.UUID, balance decimal.Decimal) error {
	if m.UpdateBalanceFunc != nil {
		return m.UpdateBalanceFunc(ctx, id, balance)
	}
	return nil
}

func (m *MockAccountRepository) Delete(ctx context.Context, id domain.UUID) error {
	if m.DeleteFunc != nil {
		return m.DeleteFunc(ctx, id)
	}
	return nil
}

func (m *MockAccountRepository) ListUpdatedAfter(ctx context.Context, since time.Time) ([]*domain.Account, error) {
	if m.ListUpdatedAfterFunc != nil {
		return m.ListUpdatedAfterFunc(ctx, since)
	}
	return nil, nil
}

func (m *MockAccountRepository) UpsertSync(ctx context.Context, acc *domain.Account) error {
	if m.UpsertSyncFunc != nil {
		return m.UpsertSyncFunc(ctx, acc)
	}
	return nil
}

var _ port.AccountRepository = (*MockAccountRepository)(nil)

// MockCategoryRepository implements port.CategoryRepository for unit testing.
type MockCategoryRepository struct {
	CreateFunc           func(ctx context.Context, cat *domain.Category) error
	GetByIDFunc          func(ctx context.Context, id domain.UUID) (*domain.Category, error)
	ListFunc             func(ctx context.Context, limit, offset int) ([]*domain.Category, error)
	CountFunc            func(ctx context.Context) (int, error)
	UpdateFunc           func(ctx context.Context, cat *domain.Category) error
	DeleteFunc           func(ctx context.Context, id domain.UUID) error
	ListUpdatedAfterFunc func(ctx context.Context, since time.Time) ([]*domain.Category, error)
	UpsertSyncFunc       func(ctx context.Context, cat *domain.Category) error
}

func (m *MockCategoryRepository) Create(ctx context.Context, cat *domain.Category) error {
	if m.CreateFunc != nil {
		return m.CreateFunc(ctx, cat)
	}
	return nil
}

func (m *MockCategoryRepository) GetByID(ctx context.Context, id domain.UUID) (*domain.Category, error) {
	if m.GetByIDFunc != nil {
		return m.GetByIDFunc(ctx, id)
	}
	return nil, nil
}

func (m *MockCategoryRepository) List(ctx context.Context, limit, offset int) ([]*domain.Category, error) {
	if m.ListFunc != nil {
		return m.ListFunc(ctx, limit, offset)
	}
	return nil, nil
}

func (m *MockCategoryRepository) Count(ctx context.Context) (int, error) {
	if m.CountFunc != nil {
		return m.CountFunc(ctx)
	}
	return 0, nil
}

func (m *MockCategoryRepository) Update(ctx context.Context, cat *domain.Category) error {
	if m.UpdateFunc != nil {
		return m.UpdateFunc(ctx, cat)
	}
	return nil
}

func (m *MockCategoryRepository) Delete(ctx context.Context, id domain.UUID) error {
	if m.DeleteFunc != nil {
		return m.DeleteFunc(ctx, id)
	}
	return nil
}

func (m *MockCategoryRepository) ListUpdatedAfter(ctx context.Context, since time.Time) ([]*domain.Category, error) {
	if m.ListUpdatedAfterFunc != nil {
		return m.ListUpdatedAfterFunc(ctx, since)
	}
	return nil, nil
}

func (m *MockCategoryRepository) UpsertSync(ctx context.Context, cat *domain.Category) error {
	if m.UpsertSyncFunc != nil {
		return m.UpsertSyncFunc(ctx, cat)
	}
	return nil
}

var _ port.CategoryRepository = (*MockCategoryRepository)(nil)

// MockTransactionRepository implements port.TransactionRepository for unit testing.
type MockTransactionRepository struct {
	CreateFunc           func(ctx context.Context, tx *domain.Transaction) error
	UpsertFunc           func(ctx context.Context, tx *domain.Transaction) error
	GetByIDFunc          func(ctx context.Context, id domain.UUID) (*domain.Transaction, error)
	ListFunc             func(ctx context.Context, limit, offset int) ([]*domain.Transaction, error)
	ListByAccountFunc    func(ctx context.Context, accountID domain.UUID, limit, offset int) ([]*domain.Transaction, error)
	CountFunc            func(ctx context.Context) (int, error)
	CountByAccountFunc   func(ctx context.Context, accountID domain.UUID) (int, error)
	ListUpdatedAfterFunc func(ctx context.Context, since time.Time) ([]*domain.Transaction, error)
	DeleteFunc           func(ctx context.Context, id domain.UUID) error
}

func (m *MockTransactionRepository) Create(ctx context.Context, tx *domain.Transaction) error {
	if m.CreateFunc != nil {
		return m.CreateFunc(ctx, tx)
	}
	return nil
}

func (m *MockTransactionRepository) Upsert(ctx context.Context, tx *domain.Transaction) error {
	if m.UpsertFunc != nil {
		return m.UpsertFunc(ctx, tx)
	}
	return nil
}

func (m *MockTransactionRepository) GetByID(ctx context.Context, id domain.UUID) (*domain.Transaction, error) {
	if m.GetByIDFunc != nil {
		return m.GetByIDFunc(ctx, id)
	}
	return nil, nil
}

func (m *MockTransactionRepository) List(ctx context.Context, limit, offset int) ([]*domain.Transaction, error) {
	if m.ListFunc != nil {
		return m.ListFunc(ctx, limit, offset)
	}
	return nil, nil
}

func (m *MockTransactionRepository) ListByAccount(ctx context.Context, accountID domain.UUID, limit, offset int) ([]*domain.Transaction, error) {
	if m.ListByAccountFunc != nil {
		return m.ListByAccountFunc(ctx, accountID, limit, offset)
	}
	return nil, nil
}

func (m *MockTransactionRepository) Count(ctx context.Context) (int, error) {
	if m.CountFunc != nil {
		return m.CountFunc(ctx)
	}
	return 0, nil
}

func (m *MockTransactionRepository) CountByAccount(ctx context.Context, accountID domain.UUID) (int, error) {
	if m.CountByAccountFunc != nil {
		return m.CountByAccountFunc(ctx, accountID)
	}
	return 0, nil
}

func (m *MockTransactionRepository) ListUpdatedAfter(ctx context.Context, since time.Time) ([]*domain.Transaction, error) {
	if m.ListUpdatedAfterFunc != nil {
		return m.ListUpdatedAfterFunc(ctx, since)
	}
	return nil, nil
}

func (m *MockTransactionRepository) Delete(ctx context.Context, id domain.UUID) error {
	if m.DeleteFunc != nil {
		return m.DeleteFunc(ctx, id)
	}
	return nil
}

var _ port.TransactionRepository = (*MockTransactionRepository)(nil)

type MockTxManager struct {
	RunInTxFunc func(ctx context.Context, fn func(ctx context.Context) error) error
}

func (m *MockTxManager) RunInTx(ctx context.Context, fn func(ctx context.Context) error) error {
	if m.RunInTxFunc != nil {
		return m.RunInTxFunc(ctx, fn)
	}
	return fn(ctx)
}

var _ port.TxManager = (*MockTxManager)(nil)

// MockSyncLogRepository implements port.SyncLogRepository for unit testing.
type MockSyncLogRepository struct {
	RecordFunc        func(ctx context.Context, log *domain.SyncLog) error
	GetByIDFunc       func(ctx context.Context, id domain.UUID) (*domain.SyncLog, error)
	ListByDeviceFunc  func(ctx context.Context, deviceID domain.UUID, limit, offset int) ([]*domain.SyncLog, error)
	CountByDeviceFunc func(ctx context.Context, deviceID domain.UUID) (int, error)
}

func (m *MockSyncLogRepository) Record(ctx context.Context, log *domain.SyncLog) error {
	if m.RecordFunc != nil {
		return m.RecordFunc(ctx, log)
	}
	return nil
}

func (m *MockSyncLogRepository) GetByID(ctx context.Context, id domain.UUID) (*domain.SyncLog, error) {
	if m.GetByIDFunc != nil {
		return m.GetByIDFunc(ctx, id)
	}
	return nil, nil
}

func (m *MockSyncLogRepository) ListByDevice(ctx context.Context, deviceID domain.UUID, limit, offset int) ([]*domain.SyncLog, error) {
	if m.ListByDeviceFunc != nil {
		return m.ListByDeviceFunc(ctx, deviceID, limit, offset)
	}
	return nil, nil
}

func (m *MockSyncLogRepository) CountByDevice(ctx context.Context, deviceID domain.UUID) (int, error) {
	if m.CountByDeviceFunc != nil {
		return m.CountByDeviceFunc(ctx, deviceID)
	}
	return 0, nil
}

var _ port.SyncLogRepository = (*MockSyncLogRepository)(nil)
