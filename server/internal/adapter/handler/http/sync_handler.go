package http

import (
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/adapter/handler/http/dto"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
)

type SyncHandler struct {
	syncService port.SyncService
	logger      *slog.Logger
}

// NewSyncHandler constructs a SyncHandler with an optional structured logger for non-sensitive audit metadata.
func NewSyncHandler(syncService port.SyncService, logger ...*slog.Logger) *SyncHandler {
	var l *slog.Logger
	if len(logger) > 0 {
		l = logger[0]
	}
	return &SyncHandler{
		syncService: syncService,
		logger:      l,
	}
}

func (h *SyncHandler) PullChanges(w http.ResponseWriter, r *http.Request) {
	start := time.Now()

	var req dto.SyncPullRequest
	if r.Method == http.MethodGet {
		since := strings.TrimSpace(r.URL.Query().Get("since"))
		if since == "" {
			since = strings.TrimSpace(r.URL.Query().Get("last_pulled_at"))
		}
		req.LastPulledAt = since
	} else {
		if err := DecodeJSON(w, r, &req); err != nil {
			return
		}
	}

	lastPulledAt, err := req.Validate()
	if err != nil {
		WriteError(w, http.StatusBadRequest, "validation_error", err.Error())
		return
	}

	ctx := r.Context()
	deviceID, devErr := DeviceIDFromContext(ctx)
	if devErr == nil {
		ctx = domain.WithSyncDeviceID(ctx, deviceID)
	}

	res, err := h.syncService.PullChanges(ctx, lastPulledAt)
	if err != nil {
		WriteDomainError(w, err)
		return
	}

	if h.logger != nil {
		batchSize := len(res.Accounts) + len(res.Categories) + len(res.Transactions)
		h.logger.Info("sync pull completed",
			slog.String("device_id", deviceID.String()),
			slog.String("direction", string(domain.SyncDirectionPull)),
			slog.Int("batch_size", batchSize),
			slog.Int64("duration_ms", time.Since(start).Milliseconds()),
		)
	}

	WriteJSON(w, http.StatusOK, dto.ToSyncPullResponse(res))
}

func (h *SyncHandler) PushChanges(w http.ResponseWriter, r *http.Request) {
	start := time.Now()

	var req dto.SyncPushRequest
	if err := DecodeJSON(w, r, &req); err != nil {
		return
	}

	payload, err := req.Validate()
	if err != nil {
		WriteError(w, http.StatusBadRequest, "validation_error", err.Error())
		return
	}

	deviceID, devErr := DeviceIDFromContext(r.Context())
	if devErr == nil {
		payload.DeviceID = deviceID
	}

	if tsHeader := strings.TrimSpace(r.Header.Get("X-Timestamp")); tsHeader != "" {
		if parsedTS, tsErr := parseSignatureTimestamp(tsHeader); tsErr == nil {
			payload.ClientTimestamp = parsedTS
		}
	}
	if payload.ClientTimestamp.IsZero() {
		payload.ClientTimestamp = time.Now().UTC()
	}

	res, err := h.syncService.PushChanges(r.Context(), payload)
	if err != nil {
		WriteDomainError(w, err)
		return
	}

	if h.logger != nil {
		batchSize := res.AccountsApplied + res.CategoriesApplied + res.TransactionsApplied
		h.logger.Info("sync push completed",
			slog.String("device_id", deviceID.String()),
			slog.String("direction", string(domain.SyncDirectionPush)),
			slog.Int("batch_size", batchSize),
			slog.Int64("duration_ms", time.Since(start).Milliseconds()),
		)
	}

	WriteJSON(w, http.StatusOK, dto.ToSyncPushResponse(res))
}
