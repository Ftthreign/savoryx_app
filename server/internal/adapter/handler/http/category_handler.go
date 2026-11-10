package http

import (
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
	if err := DecodeJSON(w, r, &req); err != nil {
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
	limit, offset := ParsePaginationParams(r)

	categories, total, err := h.categoryService.ListCategories(r.Context(), limit, offset)
	if err != nil {
		WriteDomainError(w, err)
		return
	}

	resList := dto.ToCategoryResponseList(categories)
	meta := PaginationMeta{
		Total:  total,
		Limit:  limit,
		Offset: offset,
	}
	WriteJSONWithMeta(w, http.StatusOK, resList, meta)
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
	if err := DecodeJSON(w, r, &req); err != nil {
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
