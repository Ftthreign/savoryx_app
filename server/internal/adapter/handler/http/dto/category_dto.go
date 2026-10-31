package dto

import (
	"fmt"
	"strings"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
)

type CreateCategoryRequest struct {
	ID      string `json:"id,omitempty"`
	Name    string `json:"name"`
	Icon    string `json:"icon"`
	Color   string `json:"color"`
	IsWants bool   `json:"is_wants"`
}

func (r *CreateCategoryRequest) Validate() (*domain.Category, error) {
	trimmedName := strings.TrimSpace(r.Name)
	if trimmedName == "" {
		return nil, fmt.Errorf("name is required")
	}
	if len(trimmedName) > 64 {
		return nil, fmt.Errorf("name exceeds 64 characters")
	}

	trimmedIcon := strings.TrimSpace(r.Icon)
	if trimmedIcon == "" {
		return nil, fmt.Errorf("icon is required")
	}
	if len(trimmedIcon) > 64 {
		return nil, fmt.Errorf("icon exceeds 64 characters")
	}

	trimmedColor := strings.TrimSpace(r.Color)
	if trimmedColor == "" {
		return nil, fmt.Errorf("color is required")
	}

	var categoryID domain.UUID
	trimmedID := strings.TrimSpace(r.ID)
	if trimmedID != "" {
		parsedID, err := domain.ParseUUID(trimmedID)
		if err != nil {
			return nil, fmt.Errorf("invalid id format: %w", err)
		}
		categoryID = parsedID
	} else {
		categoryID = domain.NewUUIDv7()
	}

	return &domain.Category{
		ID:      categoryID,
		Name:    trimmedName,
		Icon:    trimmedIcon,
		Color:   trimmedColor,
		IsWants: r.IsWants,
	}, nil
}

type UpdateCategoryRequest struct {
	Name    string `json:"name"`
	Icon    string `json:"icon"`
	Color   string `json:"color"`
	IsWants bool   `json:"is_wants"`
}

func (r *UpdateCategoryRequest) Validate() (string, string, string, bool, error) {
	trimmedName := strings.TrimSpace(r.Name)
	if trimmedName == "" {
		return "", "", "", false, fmt.Errorf("name is required")
	}
	if len(trimmedName) > 64 {
		return "", "", "", false, fmt.Errorf("name exceeds 64 characters")
	}

	trimmedIcon := strings.TrimSpace(r.Icon)
	if trimmedIcon == "" {
		return "", "", "", false, fmt.Errorf("icon is required")
	}
	if len(trimmedIcon) > 32 {
		return "", "", "", false, fmt.Errorf("icon exceeds 32 characters")
	}

	trimmedColor := strings.TrimSpace(r.Color)
	if trimmedColor == "" {
		return "", "", "", false, fmt.Errorf("color is required")
	}

	return trimmedName, trimmedIcon, trimmedColor, r.IsWants, nil
}

type CategoryResponse struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	Icon      string    `json:"icon"`
	Color     string    `json:"color"`
	IsWants   bool      `json:"is_wants"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

func ToCategoryResponse(cat *domain.Category) CategoryResponse {
	return CategoryResponse{
		ID:        cat.ID.String(),
		Name:      cat.Name,
		Icon:      cat.Icon,
		Color:     cat.Color,
		IsWants:   cat.IsWants,
		CreatedAt: cat.CreatedAt,
		UpdatedAt: cat.UpdatedAt,
	}
}

func ToCategoryResponseList(categories []*domain.Category) []CategoryResponse {
	result := make([]CategoryResponse, len(categories))
	for i, cat := range categories {
		result[i] = ToCategoryResponse(cat)
	}
	return result
}
