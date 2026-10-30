package main

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	httpAdapter "github.com/ftthreign/savoryx_app/server/internal/adapter/handler/http"
	"github.com/ftthreign/savoryx_app/server/internal/adapter/repository/postgres"
	"github.com/ftthreign/savoryx_app/server/internal/core/service"
)

const AppVersion = "1.0.0"

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	}))
	slog.SetDefault(logger)

	cfg, err := LoadConfig()
	if err != nil {
		logger.Error("failed to load configuration", "error", err)
		os.Exit(1)
	}

	logger.Info("starting Savoryx API server", "env", cfg.AppEnv, "port", cfg.Port)

	// Context for database initialization
	initCtx, initCancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer initCancel()

	// Initialize Database Connection Pool
	var dbConn *postgres.DB
	if cfg.DatabaseURL != "" {
		db, err := postgres.NewDB(initCtx, cfg.DatabaseURL)
		if err != nil {
			logger.Warn("database connection failed; continuing in degraded mode", "error", err.Error())
		} else {
			dbConn = db
			logger.Info("database connection pool successfully established")
		}
	}

	// Instantiate Domain Services
	healthService := service.NewHealthService(dbConn)

	// Configure Chi HTTP Router & Pipelines
	r := httpAdapter.SetupRouter(logger, healthService, AppVersion, cfg.AppEnv)

	serverAddr := fmt.Sprintf(":%d", cfg.Port)
	srv := &http.Server{
		Addr:         serverAddr,
		Handler:      r,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	serverErrors := make(chan error, 1)
	go func() {
		logger.Info("HTTP server is listening", "addr", serverAddr)
		serverErrors <- srv.ListenAndServe()
	}()

	shutdown := make(chan os.Signal, 1)
	signal.Notify(shutdown, os.Interrupt, syscall.SIGTERM)

	select {
	case err := <-serverErrors:
		if err != nil && err != http.ErrServerClosed {
			logger.Error("server encountered fatal error", "error", err)
			os.Exit(1)
		}
	case sig := <-shutdown:
		logger.Info("shutdown signal received, commencing graceful termination", "signal", sig.String())

		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()

		if err := srv.Shutdown(ctx); err != nil {
			logger.Error("graceful shutdown failed; forcing termination", "error", err)
			_ = srv.Close()
		}

		if dbConn != nil {
			logger.Info("closing database connection pool")
			dbConn.Close()
		}

		logger.Info("server shutdown completed successfully")
	}
}
