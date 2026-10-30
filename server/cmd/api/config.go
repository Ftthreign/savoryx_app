package main

import (
	"fmt"

	"github.com/caarlos0/env/v10"
)

// Config holds all runtime application configuration.
type Config struct {
	AppEnv      string `env:"APP_ENV" envDefault:"development"`
	Port        int    `env:"PORT" envDefault:"8080"`
	DatabaseURL string `env:"DATABASE_URL" envDefault:"postgres://savoryx_user:savoryx_secret@localhost:5432/savoryx_db?sslmode=disable"`
}

// LoadConfig parses environment variables into Config.
func LoadConfig() (*Config, error) {
	cfg := &Config{}
	if err := env.Parse(cfg); err != nil {
		return nil, fmt.Errorf("failed to parse environment config: %w", err)
	}
	return cfg, nil
}
