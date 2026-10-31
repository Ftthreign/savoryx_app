-- name: RegisterDevice :one
INSERT INTO devices (
    id, device_name, platform, app_version, device_secret_hash, created_at, last_active_at
) VALUES (
    $1, $2, $3, $4, $5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
)
RETURNING id, device_name, platform, app_version, device_secret_hash, created_at, last_active_at, revoked_at;

-- name: GetDeviceByID :one
SELECT id, device_name, platform, app_version, device_secret_hash, created_at, last_active_at, revoked_at
FROM devices
WHERE id = $1 AND revoked_at IS NULL LIMIT 1;

-- name: UpdateDeviceLastActive :exec
UPDATE devices
SET last_active_at = CURRENT_TIMESTAMP
WHERE id = $1 AND revoked_at IS NULL;

-- name: RevokeDevice :exec
UPDATE devices
SET revoked_at = CURRENT_TIMESTAMP
WHERE id = $1 AND revoked_at IS NULL;
