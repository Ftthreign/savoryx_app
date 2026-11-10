-- name: CreateCategory :one
INSERT INTO categories (
    id, name, icon, color, is_wants, created_at, updated_at
) VALUES (
    $1, $2, $3, $4, $5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
)
RETURNING id, name, icon, color, is_wants, created_at, updated_at, deleted_at;

-- name: GetCategoryByID :one
SELECT id, name, icon, color, is_wants, created_at, updated_at, deleted_at
FROM categories
WHERE id = $1 AND deleted_at IS NULL LIMIT 1;

-- name: ListCategories :many
SELECT id, name, icon, color, is_wants, created_at, updated_at, deleted_at
FROM categories
WHERE deleted_at IS NULL
ORDER BY name ASC
LIMIT $1 OFFSET $2;

-- name: CountCategories :one
SELECT COUNT(*)
FROM categories
WHERE deleted_at IS NULL;

-- name: UpdateCategory :one
UPDATE categories
SET name = $2,
    icon = $3,
    color = $4,
    is_wants = $5,
    updated_at = CURRENT_TIMESTAMP
WHERE id = $1 AND deleted_at IS NULL
RETURNING id, name, icon, color, is_wants, created_at, updated_at, deleted_at;

-- name: SoftDeleteCategory :exec
UPDATE categories
SET deleted_at = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP
WHERE id = $1 AND deleted_at IS NULL;

-- name: ListCategoriesUpdatedAfter :many
SELECT id, name, icon, color, is_wants, created_at, updated_at, deleted_at
FROM categories
WHERE updated_at > $1
ORDER BY updated_at ASC;

-- name: UpsertCategorySync :one
INSERT INTO categories (
    id, name, icon, color, is_wants, created_at, updated_at, deleted_at
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    icon = EXCLUDED.icon,
    color = EXCLUDED.color,
    is_wants = EXCLUDED.is_wants,
    updated_at = EXCLUDED.updated_at,
    deleted_at = EXCLUDED.deleted_at
WHERE categories.updated_at < EXCLUDED.updated_at
RETURNING id, name, icon, color, is_wants, created_at, updated_at, deleted_at;
