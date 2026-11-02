package fx

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/samber/oops"
	"github.com/shopspring/decimal"
)

const (
	DefaultBaseURL     = "https://api.frankfurter.app"
	DefaultHTTPTimeout = 10 * time.Second
	MaxRetries         = 3
	InitialBackoff     = 200 * time.Millisecond
)

type frankfurterResponse struct {
	Base  string                     `json:"base"`
	Date  string                     `json:"date"`
	Rates map[string]decimal.Decimal `json:"rates"`
}

type FrankfurterFXClient struct {
	baseURL    string
	httpClient *http.Client
}

type ClientOption func(*FrankfurterFXClient)

func WithBaseURL(url string) ClientOption {
	return func(c *FrankfurterFXClient) {
		c.baseURL = strings.TrimRight(url, "/")
	}
}

func WithHTTPClient(client *http.Client) ClientOption {
	return func(c *FrankfurterFXClient) {
		c.httpClient = client
	}
}

func NewFrankfurterClient(opts ...ClientOption) *FrankfurterFXClient {
	client := &FrankfurterFXClient{
		baseURL: DefaultBaseURL,
		httpClient: &http.Client{
			Timeout: DefaultHTTPTimeout,
		},
	}

	for _, opt := range opts {
		opt(client)
	}

	return client
}

func (c *FrankfurterFXClient) FetchLatestRates(ctx context.Context, base string) ([]*domain.ExchangeRate, error) {
	base = strings.ToUpper(strings.TrimSpace(base))
	if len(base) != 3 {
		return nil, oops.
			In("frankfurter_client").
			Code("ERR_INVALID_CURRENCY").
			Wrapf(domain.ErrInvalidInput, "base currency must be 3-letter ISO code: %s", base)
	}

	endpoint := fmt.Sprintf("%s/latest?from=%s", c.baseURL, url.QueryEscape(base))
	return c.executeRequest(ctx, endpoint, base)
}

func (c *FrankfurterFXClient) FetchHistoricalRates(ctx context.Context, base string, date time.Time) ([]*domain.ExchangeRate, error) {
	base = strings.ToUpper(strings.TrimSpace(base))
	if len(base) != 3 {
		return nil, oops.
			In("frankfurter_client").
			Code("ERR_INVALID_CURRENCY").
			Wrapf(domain.ErrInvalidInput, "base currency must be 3-letter ISO code: %s", base)
	}

	if date.IsZero() {
		return nil, oops.
			In("frankfurter_client").
			Code("ERR_INVALID_DATE").
			Wrapf(domain.ErrInvalidInput, "effective date cannot be zero")
	}

	dateStr := date.Format("2006-01-02")
	endpoint := fmt.Sprintf("%s/%s?from=%s", c.baseURL, dateStr, url.QueryEscape(base))
	return c.executeRequest(ctx, endpoint, base)
}

func (c *FrankfurterFXClient) executeRequest(ctx context.Context, endpoint, base string) ([]*domain.ExchangeRate, error) {
	var resp *http.Response
	var err error

	backoff := InitialBackoff

	for attempt := 0; attempt <= MaxRetries; attempt++ {
		if attempt > 0 {
			select {
			case <-ctx.Done():
				return nil, oops.
					In("frankfurter_client").
					Code("ERR_CONTEXT_CANCELLED").
					Wrap(ctx.Err())
			case <-time.After(backoff):
				backoff *= 2
			}
		}

		req, reqErr := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
		if reqErr != nil {
			return nil, oops.
				In("frankfurter_client").
				Code("ERR_CREATE_REQUEST").
				Wrapf(reqErr, "failed to create http request")
		}
		req.Header.Set("User-Agent", "Savoryx-API/1.0")
		req.Header.Set("Accept", "application/json")

		resp, err = c.httpClient.Do(req)
		if err == nil && resp.StatusCode < 500 {
			break
		}
	}

	if err != nil {
		return nil, oops.
			In("frankfurter_client").
			Code("ERR_HTTP_REQUEST_FAILED").
			Wrapf(err, "failed to execute fx request after retries")
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, oops.
			In("frankfurter_client").
			Code("ERR_UPSTREAM_STATUS").
			With("status_code", resp.StatusCode).
			Errorf("upstream Frankfurter API returned status %d", resp.StatusCode)
	}

	var frankfurterData frankfurterResponse
	if decodeErr := json.NewDecoder(resp.Body).Decode(&frankfurterData); decodeErr != nil {
		return nil, oops.
			In("frankfurter_client").
			Code("ERR_DECODE_JSON").
			Wrapf(decodeErr, "failed to decode frankfurter response json")
	}

	effectiveDate, parseErr := time.Parse("2006-01-02", frankfurterData.Date)
	if parseErr != nil {
		effectiveDate = time.Now().UTC().Truncate(24 * time.Hour)
	}

	results := make([]*domain.ExchangeRate, 0, len(frankfurterData.Rates)+1)

	// Inisialisasi identitas kurs dasar (1 base = 1 base)
	selfRate, selfErr := domain.NewExchangeRate(base, base, decimal.NewFromInt(1), effectiveDate)
	if selfErr != nil {
		return nil, oops.
			In("frankfurter_client").
			Code("ERR_INVALID_BASE_CURRENCY").
			With("base", base).
			Wrap(selfErr)
	}
	results = append(results, selfRate)

	for target, rate := range frankfurterData.Rates {
		fxRate, err := domain.NewExchangeRate(base, target, rate, effectiveDate)
		if err != nil {
			continue
		}
		results = append(results, fxRate)
	}

	return results, nil
}

var _ port.FXProvider = (*FrankfurterFXClient)(nil)
