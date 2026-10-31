package http

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/ftthreign/savoryx_app/server/internal/adapter/handler/http/dto"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/go-chi/chi/v5"
)

type CategoryHandler struct {
	categoryService port.CategoryService
}

func NewCategoryHandler(categoryService port.CategoryService) *CategoryHandler {
	return &CategoryHandler{
		categoryService: categoryService,
	}
}

func (h *CategoryHandler) CreateCategory(w http.ResponseWriter, r *http.Request) {
	var req dto.CreateCategoryRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_json", "Failed to parse request JSON body")
		return
	}

	cat, err := req.Validate()
	if err != nil {
		WriteError(w, http.StatusBadRequest, "validation_error", err.Error())
		return
	}

	if err := h.categoryService.CreateCategory(r.Context(), cat); err != nil {
		WriteDomainError(w, err)
		return
	}

	w.Header().Set("Location", fmt.Sprintf("/api/v1/categories/%s", cat.ID.String()))
	WriteJSON(w, http.StatusCreated, dto.ToCategoryResponse(cat))
}

func (h *CategoryHandler) ListCategories(w http.ResponseWriter, r *http.Request) {
	categories, err := h.categoryService.ListCategories(r.Context())
	if err != nil {
		WriteDomainError(w, err)
		return
	}

	WriteJSON(w, http.StatusOK, dto.ToCategoryResponseList(categories))
}

func (h *CategoryHandler) GetCategory(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := domain.ParseUUID(idStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_id", "Category ID must be a valid UUID")
		return
	}

	cat, err := h.categoryService.GetCategory(r.Context(), id)
	if err != nil {
		WriteDomainError(w, err)
		return
	}

	WriteJSON(w, http.StatusOK, dto.ToCategoryResponse(cat))
}

func (h *CategoryHandler) UpdateCategory(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := domain.ParseUUID(idStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_id", "Category ID must be a valid UUID")
		return
	}

	var req dto.UpdateCategoryRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_json", "Failed to parse request JSON body")
		return
	}

	name, icon, color, isWants, err := req.Validate()
	if err != nil {
		WriteError(w, http.StatusBadRequest, "validation_error", err.Error())
		return
	}

	updatedCat, err := h.categoryService.UpdateCategory(r.Context(), id, name, icon, color, isWants)
	if err != nil {
		WriteDomainError(w, err)
		return
	}

	WriteJSON(w, http.StatusOK, dto.ToCategoryResponse(updatedCat))
}

func (h *CategoryHandler) DeleteCategory(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := domain.ParseUUID(idStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_id", "Category ID must be a valid UUID")
		return
	}

	if err := h.categoryService.DeleteCategory(r.Context(), id); err != nil {
		WriteDomainError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
