package main

import (
	"fmt"

	"github.com/caarlos0/env/v10"
)

type Config struct {
	AppEnv      string `env:"APP_ENV" envDefault:"development"`
	Port        int    `env:"PORT" envDefault:"8080"`
	DatabaseURL string `env:"DATABASE_URL" envDefault:"postgres://savoryx_user:savoryx_secret@127.0.0.1:5433/savoryx_db?sslmode=disable"`
}

func LoadConfig() (*Config, error) {
	cfg := &Config{}
	if err := env.Parse(cfg); err != nil {
		return nil, fmt.Errorf("failed to parse environment config: %w", err)
	}
	return cfg, nil
}
