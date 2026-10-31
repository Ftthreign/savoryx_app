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
ORDER BY name ASC;

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
