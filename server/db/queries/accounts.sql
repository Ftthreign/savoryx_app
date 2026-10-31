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
ORDER BY created_at ASC;

-- name: UpdateAccountBalance :one
UPDATE accounts
SET balance = $2,
    updated_at = CURRENT_TIMESTAMP
WHERE id = $1 AND deleted_at IS NULL
RETURNING id, name, type, currency, balance, created_at, updated_at, deleted_at;

-- name: SoftDeleteAccount :exec
UPDATE accounts
SET deleted_at = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP
WHERE id = $1 AND deleted_at IS NULL;
