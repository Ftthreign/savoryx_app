package dto

import (
	"fmt"
	"strings"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/shopspring/decimal"
)

type SyncPullRequest struct {
	LastPulledAt string `json:"last_pulled_at"`
}

func (r *SyncPullRequest) Validate() (time.Time, error) {
	trimmed := strings.TrimSpace(r.LastPulledAt)
	if trimmed == "" || trimmed == "0" {
		return time.Unix(0, 0).UTC(), nil
	}
	t, err := parseRFC3339Time(trimmed)
	if err != nil {
		return time.Time{}, fmt.Errorf("invalid last_pulled_at format (expected RFC3339 timestamp): %w", err)
	}
	return t, nil
}

type SyncAccountDTO struct {
	ID        string     `json:"id"`
	Name      string     `json:"name"`
	Type      string     `json:"type"`
	Currency  string     `json:"currency"`
	Balance   string     `json:"balance"`
	CreatedAt string     `json:"created_at,omitempty"`
	UpdatedAt string     `json:"updated_at,omitempty"`
	DeletedAt *string    `json:"deleted_at,omitempty"`
}

type SyncCategoryDTO struct {
	ID        string  `json:"id"`
	Name      string  `json:"name"`
	Icon      string  `json:"icon"`
	Color     string  `json:"color"`
	IsWants   bool    `json:"is_wants"`
	CreatedAt string  `json:"created_at,omitempty"`
	UpdatedAt string  `json:"updated_at,omitempty"`
	DeletedAt *string `json:"deleted_at,omitempty"`
}

type SyncTransactionDTO struct {
	ID                   string  `json:"id"`
	AccountID            string  `json:"account_id"`
	CategoryID           string  `json:"category_id,omitempty"`
	DestinationAccountID string  `json:"destination_account_id,omitempty"`
	Type                 string  `json:"type"`
	Amount               string  `json:"amount"`
	Currency             string  `json:"currency,omitempty"`
	ExchangeRateToBase   string  `json:"exchange_rate_to_base,omitempty"`
	BaseAmount           string  `json:"base_amount,omitempty"`
	Note                 string  `json:"note,omitempty"`
	IsTalangan           bool    `json:"is_talangan,omitempty"`
	TransactionDate      string  `json:"transaction_date"`
	CreatedAt            string  `json:"created_at,omitempty"`
	UpdatedAt            string  `json:"updated_at,omitempty"`
	DeletedAt            *string `json:"deleted_at,omitempty"`
}

type SyncAccountResponse struct {
	ID        string     `json:"id"`
	Name      string     `json:"name"`
	Type      string     `json:"type"`
	Currency  string     `json:"currency"`
	Balance   string     `json:"balance"`
	CreatedAt time.Time  `json:"created_at"`
	UpdatedAt time.Time  `json:"updated_at"`
	DeletedAt *time.Time `json:"deleted_at,omitempty"`
}

type SyncCategoryResponse struct {
	ID        string     `json:"id"`
	Name      string     `json:"name"`
	Icon      string     `json:"icon"`
	Color     string     `json:"color"`
	IsWants   bool       `json:"is_wants"`
	CreatedAt time.Time  `json:"created_at"`
	UpdatedAt time.Time  `json:"updated_at"`
	DeletedAt *time.Time `json:"deleted_at,omitempty"`
}

type SyncPullResponse struct {
	Accounts     []SyncAccountResponse  `json:"accounts"`
	Categories   []SyncCategoryResponse `json:"categories"`
	Transactions []TransactionResponse  `json:"transactions"`
	PulledAt     time.Time              `json:"pulled_at"`
	ServerTime   string                 `json:"server_time"`
}

func ToSyncPullResponse(res *port.SyncPullResult) SyncPullResponse {
	accounts := make([]SyncAccountResponse, len(res.Accounts))
	for i, acc := range res.Accounts {
		accounts[i] = SyncAccountResponse{
			ID:        acc.ID.String(),
			Name:      acc.Name,
			Type:      string(acc.Type),
			Currency:  acc.Currency,
			Balance:   acc.Balance.StringFixed(2),
			CreatedAt: acc.CreatedAt,
			UpdatedAt: acc.UpdatedAt,
			DeletedAt: acc.DeletedAt,
		}
	}

	categories := make([]SyncCategoryResponse, len(res.Categories))
	for i, cat := range res.Categories {
		categories[i] = SyncCategoryResponse{
			ID:        cat.ID.String(),
			Name:      cat.Name,
			Icon:      cat.Icon,
			Color:     cat.Color,
			IsWants:   cat.IsWants,
			CreatedAt: cat.CreatedAt,
			UpdatedAt: cat.UpdatedAt,
			DeletedAt: cat.DeletedAt,
		}
	}

	pulledAt := res.PulledAt.UTC().Truncate(time.Microsecond)

	return SyncPullResponse{
		Accounts:     accounts,
		Categories:   categories,
		Transactions: ToTransactionResponseList(res.Transactions),
		PulledAt:     pulledAt,
		ServerTime:   pulledAt.Format(time.RFC3339Nano),
	}
}

type SyncPushRequest struct {
	Accounts     []SyncAccountDTO     `json:"accounts"`
	Categories   []SyncCategoryDTO    `json:"categories"`
	Transactions []SyncTransactionDTO `json:"transactions"`
}

func (r *SyncPushRequest) Validate() (*port.SyncPushPayload, error) {
	now := time.Now().UTC()

	accounts := make([]*domain.Account, len(r.Accounts))
	for i, item := range r.Accounts {
		id, err := domain.ParseUUID(strings.TrimSpace(item.ID))
		if err != nil {
			return nil, fmt.Errorf("accounts[%d]: invalid id: %w", i, err)
		}
		accType := domain.AccountType(strings.ToUpper(strings.TrimSpace(item.Type)))
		if !accType.IsValid() {
			return nil, fmt.Errorf("accounts[%d]: invalid type %q", i, item.Type)
		}
		balStr := strings.TrimSpace(item.Balance)
		if balStr == "" {
			balStr = "0"
		}
		bal, err := decimal.NewFromString(balStr)
		if err != nil {
			return nil, fmt.Errorf("accounts[%d]: invalid balance: %w", i, err)
		}
		createdAt, err := parseOptionalTimestamp(item.CreatedAt, now)
		if err != nil {
			return nil, fmt.Errorf("accounts[%d]: invalid created_at: %w", i, err)
		}
		updatedAt, err := parseOptionalTimestamp(item.UpdatedAt, now)
		if err != nil {
			return nil, fmt.Errorf("accounts[%d]: invalid updated_at: %w", i, err)
		}
		deletedAt, err := parseNullableTimestamp(item.DeletedAt)
		if err != nil {
			return nil, fmt.Errorf("accounts[%d]: invalid deleted_at: %w", i, err)
		}

		currency := strings.ToUpper(strings.TrimSpace(item.Currency))
		if currency == "" {
			currency = "IDR"
		}

		accounts[i] = &domain.Account{
			ID:        id,
			Name:      strings.TrimSpace(item.Name),
			Type:      accType,
			Currency:  currency,
			Balance:   bal,
			CreatedAt: createdAt,
			UpdatedAt: updatedAt,
			DeletedAt: deletedAt,
		}
	}

	categories := make([]*domain.Category, len(r.Categories))
	for i, item := range r.Categories {
		id, err := domain.ParseUUID(strings.TrimSpace(item.ID))
		if err != nil {
			return nil, fmt.Errorf("categories[%d]: invalid id: %w", i, err)
		}
		createdAt, err := parseOptionalTimestamp(item.CreatedAt, now)
		if err != nil {
			return nil, fmt.Errorf("categories[%d]: invalid created_at: %w", i, err)
		}
		updatedAt, err := parseOptionalTimestamp(item.UpdatedAt, now)
		if err != nil {
			return nil, fmt.Errorf("categories[%d]: invalid updated_at: %w", i, err)
		}
		deletedAt, err := parseNullableTimestamp(item.DeletedAt)
		if err != nil {
			return nil, fmt.Errorf("categories[%d]: invalid deleted_at: %w", i, err)
		}

		categories[i] = &domain.Category{
			ID:        id,
			Name:      strings.TrimSpace(item.Name),
			Icon:      strings.TrimSpace(item.Icon),
			Color:     strings.ToUpper(strings.TrimSpace(item.Color)),
			IsWants:   item.IsWants,
			CreatedAt: createdAt,
			UpdatedAt: updatedAt,
			DeletedAt: deletedAt,
		}
	}

	transactions := make([]*domain.Transaction, len(r.Transactions))
	for i, item := range r.Transactions {
		createReq := CreateTransactionRequest{
			ID:                   item.ID,
			AccountID:            item.AccountID,
			CategoryID:           item.CategoryID,
			DestinationAccountID: item.DestinationAccountID,
			Type:                 item.Type,
			Amount:               item.Amount,
			Currency:             item.Currency,
			ExchangeRateToBase:   item.ExchangeRateToBase,
			BaseAmount:           item.BaseAmount,
			Note:                 item.Note,
			IsTalangan:           item.IsTalangan,
			TransactionDate:      item.TransactionDate,
		}
		tx, err := createReq.Validate()
		if err != nil {
			return nil, fmt.Errorf("transactions[%d]: %w", i, err)
		}
		createdAt, err := parseOptionalTimestamp(item.CreatedAt, now)
		if err != nil {
			return nil, fmt.Errorf("transactions[%d]: invalid created_at: %w", i, err)
		}
		updatedAt, err := parseOptionalTimestamp(item.UpdatedAt, now)
		if err != nil {
			return nil, fmt.Errorf("transactions[%d]: invalid updated_at: %w", i, err)
		}
		deletedAt, err := parseNullableTimestamp(item.DeletedAt)
		if err != nil {
			return nil, fmt.Errorf("transactions[%d]: invalid deleted_at: %w", i, err)
		}
		tx.CreatedAt = createdAt
		tx.UpdatedAt = updatedAt
		tx.DeletedAt = deletedAt
		transactions[i] = tx
	}

	return &port.SyncPushPayload{
		Accounts:     accounts,
		Categories:   categories,
		Transactions: transactions,
	}, nil
}

type SyncPushResponse struct {
	AccountsApplied     int       `json:"accounts_applied"`
	CategoriesApplied   int       `json:"categories_applied"`
	TransactionsApplied int       `json:"transactions_applied"`
	SyncedAt            time.Time `json:"synced_at"`
}

func ToSyncPushResponse(res *port.SyncPushResult) SyncPushResponse {
	return SyncPushResponse{
		AccountsApplied:     res.AccountsApplied,
		CategoriesApplied:   res.CategoriesApplied,
		TransactionsApplied: res.TransactionsApplied,
		SyncedAt:            res.SyncedAt,
	}
}

func parseOptionalTimestamp(s string, fallback time.Time) (time.Time, error) {
	trimmed := strings.TrimSpace(s)
	if trimmed == "" {
		return fallback, nil
	}
	return parseRFC3339Time(trimmed)
}

func parseNullableTimestamp(s *string) (*time.Time, error) {
	if s == nil {
		return nil, nil
	}
	trimmed := strings.TrimSpace(*s)
	if trimmed == "" {
		return nil, nil
	}
	t, err := parseRFC3339Time(trimmed)
	if err != nil {
		return nil, err
	}
	return &t, nil
}
