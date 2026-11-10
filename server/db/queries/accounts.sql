-- name: CreateAccount :one
INSERT INTO accounts (
    id, name, type, currency, balance, created_at, updated_at
) VALUES (
    $1, $2, $3, $4, $5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
)
RETURNING id, name, type, currency, balance, created_at, updated_at, deleted_at;

-- name: GetAccountByID :one
SELECT id, name, type, currency, balance, created_at, updated_at, deleted_at
FROM accounts
WHERE id = $1 AND deleted_at IS NULL LIMIT 1;

-- name: GetAccountByIDForUpdate :one
SELECT id, name, type, currency, balance, created_at, updated_at, deleted_at
FROM accounts
WHERE id = $1 AND deleted_at IS NULL LIMIT 1
FOR UPDATE;

-- name: ListAccounts :many
SELECT id, name, type, currency, balance, created_at, updated_at, deleted_at
FROM accounts
WHERE deleted_at IS NULL
ORDER BY created_at ASC
LIMIT $1 OFFSET $2;

-- name: CountAccounts :one
SELECT COUNT(*)
FROM accounts
WHERE deleted_at IS NULL;

-- name: UpdateAccountBalance :one
UPDATE accounts
SET balance = $2,
    updated_at = CURRENT_TIMESTAMP
WHERE id = $1 AND deleted_at IS NULL
RETURNING id, name, type, currency, balance, created_at, updated_at, deleted_at;

-- name: UpdateAccount :one
UPDATE accounts
SET name = $2,
    type = $3,
    updated_at = CURRENT_TIMESTAMP
WHERE id = $1 AND deleted_at IS NULL
RETURNING id, name, type, currency, balance, created_at, updated_at, deleted_at;

-- name: SoftDeleteAccount :exec
UPDATE accounts
SET deleted_at = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP
WHERE id = $1 AND deleted_at IS NULL;

-- name: ListAccountsUpdatedAfter :many
SELECT id, name, type, currency, balance, created_at, updated_at, deleted_at
FROM accounts
WHERE updated_at > $1
ORDER BY updated_at ASC;

-- name: UpsertAccountSync :one
INSERT INTO accounts (
    id, name, type, currency, balance, created_at, updated_at, deleted_at
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    type = EXCLUDED.type,
    currency = EXCLUDED.currency,
    balance = EXCLUDED.balance,
    updated_at = EXCLUDED.updated_at,
    deleted_at = EXCLUDED.deleted_at
WHERE accounts.updated_at < EXCLUDED.updated_at
RETURNING id, name, type, currency, balance, created_at, updated_at, deleted_at;
