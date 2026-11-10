package http

import (
	"fmt"
	"net/http"
	"strings"

	"github.com/ftthreign/savoryx_app/server/internal/adapter/handler/http/dto"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/go-chi/chi/v5"
)

type TransactionHandler struct {
	txService port.TransactionService
}

func NewTransactionHandler(txService port.TransactionService) *TransactionHandler {
	return &TransactionHandler{
		txService: txService,
	}
}

func (h *TransactionHandler) CreateTransaction(w http.ResponseWriter, r *http.Request) {
	var req dto.CreateTransactionRequest
	if err := DecodeJSON(w, r, &req); err != nil {
		return
	}

	tx, err := req.Validate()
	if err != nil {
		WriteError(w, http.StatusBadRequest, "validation_error", err.Error())
		return
	}

	if err := h.txService.CreateTransaction(r.Context(), tx); err != nil {
		WriteDomainError(w, err)
		return
	}

	w.Header().Set("Location", fmt.Sprintf("/api/v1/transactions/%s", tx.ID.String()))
	WriteJSON(w, http.StatusCreated, dto.ToTransactionResponse(tx))
}

func (h *TransactionHandler) ListTransactions(w http.ResponseWriter, r *http.Request) {
	limit, offset := ParsePaginationParams(r)

	var accountID *domain.UUID
	if rawAccountID := strings.TrimSpace(r.URL.Query().Get("account_id")); rawAccountID != "" {
		parsedID, err := domain.ParseUUID(rawAccountID)
		if err != nil {
			WriteError(w, http.StatusBadRequest, "invalid_account_id", "Query parameter account_id must be a valid UUID")
			return
		}
		accountID = &parsedID
	}

	items, total, err := h.txService.ListTransactions(r.Context(), accountID, limit, offset)
	if err != nil {
		WriteDomainError(w, err)
		return
	}

	resList := dto.ToTransactionResponseList(items)
	meta := PaginationMeta{
		Total:  total,
		Limit:  limit,
		Offset: offset,
	}
	WriteJSONWithMeta(w, http.StatusOK, resList, meta)
}

func (h *TransactionHandler) GetTransaction(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := domain.ParseUUID(idStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_id", "Transaction ID must be a valid UUID")
		return
	}

	tx, err := h.txService.GetTransaction(r.Context(), id)
	if err != nil {
		WriteDomainError(w, err)
		return
	}

	WriteJSON(w, http.StatusOK, dto.ToTransactionResponse(tx))
}

func (h *TransactionHandler) DeleteTransaction(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := domain.ParseUUID(idStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_id", "Transaction ID must be a valid UUID")
		return
	}

	if err := h.txService.DeleteTransaction(r.Context(), id); err != nil {
		WriteDomainError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
