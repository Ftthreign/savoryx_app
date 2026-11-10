-- name: CreateTransaction :one
INSERT INTO transactions (
    id,
    account_id,
    category_id,
    destination_account_id,
    type,
    amount,
    currency,
    exchange_rate_to_base,
    base_amount,
    note,
    is_talangan,
    transaction_date,
    created_at,
    updated_at
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
)
RETURNING id, account_id, category_id, destination_account_id, type, amount, currency, exchange_rate_to_base, base_amount, note, is_talangan, transaction_date, created_at, updated_at, deleted_at;

-- name: UpsertTransaction :one
INSERT INTO transactions (
    id,
    account_id,
    category_id,
    destination_account_id,
    type,
    amount,
    currency,
    exchange_rate_to_base,
    base_amount,
    note,
    is_talangan,
    transaction_date,
    created_at,
    updated_at,
    deleted_at
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15
)
ON CONFLICT (id) DO UPDATE SET
    account_id = EXCLUDED.account_id,
    category_id = EXCLUDED.category_id,
    destination_account_id = EXCLUDED.destination_account_id,
    type = EXCLUDED.type,
    amount = EXCLUDED.amount,
    currency = EXCLUDED.currency,
    exchange_rate_to_base = EXCLUDED.exchange_rate_to_base,
    base_amount = EXCLUDED.base_amount,
    note = EXCLUDED.note,
    is_talangan = EXCLUDED.is_talangan,
    transaction_date = EXCLUDED.transaction_date,
    updated_at = EXCLUDED.updated_at,
    deleted_at = EXCLUDED.deleted_at
WHERE transactions.updated_at <= EXCLUDED.updated_at
RETURNING id, account_id, category_id, destination_account_id, type, amount, currency, exchange_rate_to_base, base_amount, note, is_talangan, transaction_date, created_at, updated_at, deleted_at;

-- name: GetTransactionByID :one
SELECT id, account_id, category_id, destination_account_id, type, amount, currency, exchange_rate_to_base, base_amount, note, is_talangan, transaction_date, created_at, updated_at, deleted_at
FROM transactions
WHERE id = $1 AND deleted_at IS NULL
LIMIT 1;

-- name: ListTransactions :many
SELECT id, account_id, category_id, destination_account_id, type, amount, currency, exchange_rate_to_base, base_amount, note, is_talangan, transaction_date, created_at, updated_at, deleted_at
FROM transactions
WHERE deleted_at IS NULL
ORDER BY transaction_date DESC, created_at DESC
LIMIT $1 OFFSET $2;

-- name: ListTransactionsByAccount :many
SELECT id, account_id, category_id, destination_account_id, type, amount, currency, exchange_rate_to_base, base_amount, note, is_talangan, transaction_date, created_at, updated_at, deleted_at
FROM transactions
WHERE (account_id = $1 OR destination_account_id = $1) AND deleted_at IS NULL
ORDER BY transaction_date DESC, created_at DESC
LIMIT $2 OFFSET $3;

-- name: CountTransactions :one
SELECT COUNT(*)
FROM transactions
WHERE deleted_at IS NULL;

-- name: CountTransactionsByAccount :one
SELECT COUNT(*)
FROM transactions
WHERE (account_id = $1 OR destination_account_id = $1) AND deleted_at IS NULL;

-- name: ListTransactionsUpdatedAfter :many
SELECT id, account_id, category_id, destination_account_id, type, amount, currency, exchange_rate_to_base, base_amount, note, is_talangan, transaction_date, created_at, updated_at, deleted_at
FROM transactions
WHERE updated_at > $1
ORDER BY updated_at ASC;

-- name: SoftDeleteTransaction :exec
UPDATE transactions
SET deleted_at = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP
WHERE id = $1 AND deleted_at IS NULL;
