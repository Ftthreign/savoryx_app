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

type AccountHandler struct {
	accountService port.AccountService
}

func NewAccountHandler(accountService port.AccountService) *AccountHandler {
	return &AccountHandler{
		accountService: accountService,
	}
}

func (h *AccountHandler) CreateAccount(w http.ResponseWriter, r *http.Request) {
	var req dto.CreateAccountRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_json", "Failed to parse request JSON body")
		return
	}

	acc, err := req.Validate()
	if err != nil {
		WriteError(w, http.StatusBadRequest, "validation_error", err.Error())
		return
	}

	if err := h.accountService.CreateAccount(r.Context(), acc); err != nil {
		WriteDomainError(w, err)
		return
	}

	w.Header().Set("Location", fmt.Sprintf("/api/v1/accounts/%s", acc.ID.String()))
	WriteJSON(w, http.StatusCreated, dto.ToAccountResponse(acc))
}

func (h *AccountHandler) ListAccounts(w http.ResponseWriter, r *http.Request) {
	accounts, err := h.accountService.ListAccounts(r.Context())
	if err != nil {
		WriteDomainError(w, err)
		return
	}

	WriteJSON(w, http.StatusOK, dto.ToAccountResponseList(accounts))
}

func (h *AccountHandler) GetAccount(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := domain.ParseUUID(idStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_id", "Account ID must be a valid UUID")
		return
	}

	acc, err := h.accountService.GetAccount(r.Context(), id)
	if err != nil {
		WriteDomainError(w, err)
		return
	}

	WriteJSON(w, http.StatusOK, dto.ToAccountResponse(acc))
}

func (h *AccountHandler) UpdateAccount(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := domain.ParseUUID(idStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_id", "Account ID must be a valid UUID")
		return
	}

	var req dto.UpdateAccountRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_json", "Failed to parse request JSON body")
		return
	}

	name, accType, err := req.Validate()
	if err != nil {
		WriteError(w, http.StatusBadRequest, "validation_error", err.Error())
		return
	}

	updatedAcc, err := h.accountService.UpdateAccount(r.Context(), id, name, accType)
	if err != nil {
		WriteDomainError(w, err)
		return
	}

	WriteJSON(w, http.StatusOK, dto.ToAccountResponse(updatedAcc))
}

func (h *AccountHandler) UpdateBalance(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := domain.ParseUUID(idStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_id", "Account ID must be a valid UUID")
		return
	}

	var req dto.UpdateBalanceRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_json", "Failed to parse request JSON body")
		return
	}

	newBalance, err := req.Validate()
	if err != nil {
		WriteError(w, http.StatusBadRequest, "validation_error", err.Error())
		return
	}

	if err := h.accountService.UpdateBalance(r.Context(), id, newBalance); err != nil {
		WriteDomainError(w, err)
		return
	}

	updatedAcc, err := h.accountService.GetAccount(r.Context(), id)
	if err != nil {
		WriteDomainError(w, err)
		return
	}

	WriteJSON(w, http.StatusOK, dto.ToAccountResponse(updatedAcc))
}

func (h *AccountHandler) DeleteAccount(w http.ResponseWriter, r *http.Request) {
	idStr := chi.URLParam(r, "id")
	id, err := domain.ParseUUID(idStr)
	if err != nil {
		WriteError(w, http.StatusBadRequest, "invalid_id", "Account ID must be a valid UUID")
		return
	}

	if err := h.accountService.DeleteAccount(r.Context(), id); err != nil {
		WriteDomainError(w, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
