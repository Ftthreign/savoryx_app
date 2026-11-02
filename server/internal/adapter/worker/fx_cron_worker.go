package worker

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"sync"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/port"
	"github.com/robfig/cron/v3"
	"github.com/samber/oops"
)

const (
	DefaultFXSchedule  = "5 0 * * *"
	DefaultSyncTimeout = 2 * time.Minute
)

var defaultBaseCurrencies = []string{"USD", "EUR"}

type FXCronWorker struct {
	repo           port.ExchangeRateRepository
	provider       port.FXProvider
	cache          port.FXCache
	logger         *slog.Logger
	schedule       string
	baseCurrencies []string
	syncTimeout    time.Duration
	loc            *time.Location

	cron    *cron.Cron
	entryID cron.EntryID
	mu      sync.Mutex
	running bool
}

type WorkerOption func(*FXCronWorker)

func WithCache(cache port.FXCache) WorkerOption {
	return func(w *FXCronWorker) {
		w.cache = cache
	}
}

func WithSchedule(schedule string) WorkerOption {
	return func(w *FXCronWorker) {
		w.schedule = schedule
	}
}

func WithBaseCurrencies(currencies ...string) WorkerOption {
	return func(w *FXCronWorker) {
		if len(currencies) > 0 {
			w.baseCurrencies = currencies
		}
	}
}

func WithSyncTimeout(timeout time.Duration) WorkerOption {
	return func(w *FXCronWorker) {
		if timeout > 0 {
			w.syncTimeout = timeout
		}
	}
}

func WithLocation(loc *time.Location) WorkerOption {
	return func(w *FXCronWorker) {
		if loc != nil {
			w.loc = loc
		}
	}
}

func NewFXCronWorker(
	repo port.ExchangeRateRepository,
	provider port.FXProvider,
	logger *slog.Logger,
	opts ...WorkerOption,
) *FXCronWorker {
	if logger == nil {
		logger = slog.Default()
	}

	w := &FXCronWorker{
		repo:           repo,
		provider:       provider,
		logger:         logger,
		schedule:       DefaultFXSchedule,
		baseCurrencies: defaultBaseCurrencies,
		syncTimeout:    DefaultSyncTimeout,
		loc:            time.UTC,
	}

	for _, opt := range opts {
		opt(w)
	}

	if w.cron == nil {
		w.cron = cron.New(cron.WithLocation(w.loc))
	}

	return w
}

func (w *FXCronWorker) SyncRates(ctx context.Context) error {
	w.logger.Info("starting fx rate synchronization job", "base_currencies", w.baseCurrencies)

	var errs []error
	totalUpserted := 0

	for _, base := range w.baseCurrencies {
		select {
		case <-ctx.Done():
			return oops.
				In("fx_cron_worker").
				Code("ERR_SYNC_CANCELLED").
				Wrap(ctx.Err())
		default:
		}

		rates, err := w.provider.FetchLatestRates(ctx, base)
		if err != nil {
			w.logger.Error("failed to fetch latest fx rates for base currency",
				"base", base,
				"error", err,
			)
			errs = append(errs, fmt.Errorf("failed to fetch rates for %s: %w", base, err))
			continue
		}

		upsertCount := 0
		for _, rate := range rates {
			if upsertErr := w.repo.UpsertRate(ctx, rate); upsertErr != nil {
				w.logger.Warn("failed to upsert exchange rate",
					"base", rate.BaseCurrency,
					"target", rate.TargetCurrency,
					"error", upsertErr,
				)
				errs = append(errs, fmt.Errorf("upsert error for %s/%s: %w", rate.BaseCurrency, rate.TargetCurrency, upsertErr))
			} else {
				upsertCount++
			}
		}

		totalUpserted += upsertCount
		if w.cache != nil {
			w.cache.Invalidate(ctx, base)
		}
		w.logger.Info("synchronized fx rates for base currency",
			"base", base,
			"rates_count", upsertCount,
		)
	}

	if len(errs) > 0 {
		return oops.
			In("fx_cron_worker").
			Code("ERR_SYNC_PARTIAL_FAILURE").
			With("total_upserted", totalUpserted).
			Wrap(errors.Join(errs...))
	}

	w.logger.Info("fx rate synchronization completed successfully",
		"total_upserted", totalUpserted,
	)
	return nil
}

func (w *FXCronWorker) Start(ctx context.Context) error {
	w.mu.Lock()
	defer w.mu.Unlock()

	if w.running {
		return nil
	}

	entryID, err := w.cron.AddFunc(w.schedule, func() {
		syncCtx, cancel := context.WithTimeout(context.Background(), w.syncTimeout)
		defer cancel()

		if syncErr := w.SyncRates(syncCtx); syncErr != nil {
			w.logger.Error("fx cron worker sync job failed", "error", syncErr)
		}
	})
	if err != nil {
		return oops.
			In("fx_cron_worker").
			Code("ERR_INVALID_CRON_SCHEDULE").
			With("schedule", w.schedule).
			Wrapf(err, "failed to schedule fx cron job")
	}

	w.entryID = entryID
	w.cron.Start()
	w.running = true
	w.logger.Info("fx cron worker started successfully",
		"schedule", w.schedule,
		"timezone", w.loc.String(),
	)
	return nil
}

func (w *FXCronWorker) Stop() context.Context {
	w.mu.Lock()
	defer w.mu.Unlock()

	if !w.running {
		closedCtx, cancel := context.WithCancel(context.Background())
		cancel()
		return closedCtx
	}

	stopCtx := w.cron.Stop()
	w.running = false
	w.logger.Info("fx cron worker stopped")
	return stopCtx
}

func (w *FXCronWorker) IsRunning() bool {
	w.mu.Lock()
	defer w.mu.Unlock()
	return w.running
}
