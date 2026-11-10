package http

import (
	"net/http"

	"github.com/ftthreign/savoryx_app/server/internal/adapter/handler/http/dto"
	"github.com/ftthreign/savoryx_app/server/internal/port"
)

type SyncHandler struct {
	syncService port.SyncService
}

func NewSyncHandler(syncService port.SyncService) *SyncHandler {
	return &SyncHandler{
		syncService: syncService,
	}
}

func (h *SyncHandler) PullChanges(w http.ResponseWriter, r *http.Request) {
	var req dto.SyncPullRequest
	if err := DecodeJSON(w, r, &req); err != nil {
		return
	}

	lastPulledAt, err := req.Validate()
	if err != nil {
		WriteError(w, http.StatusBadRequest, "validation_error", err.Error())
		return
	}

	res, err := h.syncService.PullChanges(r.Context(), lastPulledAt)
	if err != nil {
		WriteDomainError(w, err)
		return
	}

	WriteJSON(w, http.StatusOK, dto.ToSyncPullResponse(res))
}

func (h *SyncHandler) PushChanges(w http.ResponseWriter, r *http.Request) {
	var req dto.SyncPushRequest
	if err := DecodeJSON(w, r, &req); err != nil {
		return
	}

	payload, err := req.Validate()
	if err != nil {
		WriteError(w, http.StatusBadRequest, "validation_error", err.Error())
		return
	}

	res, err := h.syncService.PushChanges(r.Context(), payload)
	if err != nil {
		WriteDomainError(w, err)
		return
	}

	WriteJSON(w, http.StatusOK, dto.ToSyncPushResponse(res))
}
