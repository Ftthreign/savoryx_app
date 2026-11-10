-- name: RecordSyncLog :one
INSERT INTO sync_logs (
    id,
    device_id,
    direction,
    batch_size,
    status,
    client_timestamp,
    server_timestamp,
    created_at
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8
)
RETURNING id, device_id, direction, batch_size, status, client_timestamp, server_timestamp, created_at;

-- name: GetSyncLogByID :one
SELECT id, device_id, direction, batch_size, status, client_timestamp, server_timestamp, created_at
FROM sync_logs
WHERE id = $1
LIMIT 1;

-- name: ListSyncLogsByDevice :many
SELECT id, device_id, direction, batch_size, status, client_timestamp, server_timestamp, created_at
FROM sync_logs
WHERE device_id = $1
ORDER BY created_at DESC
LIMIT $2 OFFSET $3;

-- name: CountSyncLogsByDevice :one
SELECT COUNT(*)
FROM sync_logs
WHERE device_id = $1;

-- name: GetAccountsUpdatedAfter :many
SELECT id, name, type, currency, balance, created_at, updated_at, deleted_at
FROM accounts
WHERE updated_at > $1
ORDER BY updated_at ASC;

-- name: GetCategoriesUpdatedAfter :many
SELECT id, name, icon, color, is_wants, created_at, updated_at, deleted_at
FROM categories
WHERE updated_at > $1
ORDER BY updated_at ASC;

-- name: GetTransactionsUpdatedAfter :many
SELECT id, account_id, category_id, destination_account_id, type, amount, currency, exchange_rate_to_base, base_amount, note, is_talangan, transaction_date, created_at, updated_at, deleted_at
FROM transactions
WHERE updated_at > $1
ORDER BY updated_at ASC;
