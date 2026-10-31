package domain

import (
	"time"
)

type Category struct {
	ID        UUID       `json:"id"`
	Name      string     `json:"name"`
	Icon      string     `json:"icon"`
	Color     string     `json:"color"`
	IsWants   bool       `json:"is_wants"`
	CreatedAt time.Time  `json:"created_at"`
	UpdatedAt time.Time  `json:"updated_at"`
	DeletedAt *time.Time `json:"deleted_at,omitempty"`
}
