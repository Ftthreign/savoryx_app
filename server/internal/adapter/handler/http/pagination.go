package http

import (
	"net/http"
	"strconv"
)

const (
	DefaultPaginationLimit = 20
	MaxPaginationLimit     = 100
)

// ParsePaginationParams extracts and sanitizes limit and offset query parameters.
// Defaults: limit=20 (bounded between 1 and 100), offset=0 (bounded >= 0).
func ParsePaginationParams(r *http.Request) (limit, offset int) {
	limit = DefaultPaginationLimit
	offset = 0

	query := r.URL.Query()

	if limitStr := query.Get("limit"); limitStr != "" {
		if val, err := strconv.Atoi(limitStr); err == nil {
			if val <= 0 {
				limit = DefaultPaginationLimit
			} else if val > MaxPaginationLimit {
				limit = MaxPaginationLimit
			} else {
				limit = val
			}
		}
	}

	if offsetStr := query.Get("offset"); offsetStr != "" {
		if val, err := strconv.Atoi(offsetStr); err == nil {
			if val < 0 {
				offset = 0
			} else {
				offset = val
			}
		}
	}

	return limit, offset
}
