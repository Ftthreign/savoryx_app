-- name: GetUserPreferences :one
SELECT id, theme, font_family, base_currency, monthly_work_hours, monthly_income_net, updated_at
FROM user_preferences
WHERE id = $1 LIMIT 1;

-- name: UpsertUserPreferences :one
INSERT INTO user_preferences (
    id, theme, font_family, base_currency, monthly_work_hours, monthly_income_net, updated_at
) VALUES (
    $1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP
)
ON CONFLICT (id) DO UPDATE SET
    theme = EXCLUDED.theme,
    font_family = EXCLUDED.font_family,
    base_currency = EXCLUDED.base_currency,
    monthly_work_hours = EXCLUDED.monthly_work_hours,
    monthly_income_net = EXCLUDED.monthly_income_net,
    updated_at = CURRENT_TIMESTAMP
RETURNING id, theme, font_family, base_currency, monthly_work_hours, monthly_income_net, updated_at;
