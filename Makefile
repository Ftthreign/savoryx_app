SERVER_DIR   := server
MOBILE_DIR   := apps
COMPOSE_FILE := deployments/docker-compose.yml

DOCKER       := docker
GO           := go
FLUTTER      := flutter

.PHONY: help dev-db dev-stack stop-db clean-db migrate-up migrate-down seed-db dev-server swagger gen-sqlc test-server lint-server dev-mobile gen-mobile test-mobile lint-mobile build-sub10mb check-all

all: help

help:
	@echo ""
	@echo " SAVORYX MONOREPO WORKFLOW SHORTCUTS"
	@echo ""
	@echo " [Database / Infrastructure]"
	@echo "   make dev-db          - Jalankan PostgreSQL 16 di background"
	@echo "   make dev-stack       - Jalankan PostgreSQL + API container di Docker"
	@echo "   make stop-db         - Hentikan container PostgreSQL"
	@echo "   make clean-db        - Hentikan container dan HAPUS volume data"
	@echo "   make migrate-up      - Jalankan migrasi schema via golang-migrate"
	@echo "   make migrate-down    - Rollback 1 langkah migrasi schema"
	@echo "   make seed-db         - Jalankan database seeder (user prefs, accounts, categories, device)"
	@echo ""
	@echo " [Backend (Go)]"
	@echo "   make dev-server      - Jalankan server API (port :8080)"
	@echo "   make swagger         - Generate OpenAPI / Swagger docs dari Go annotations"
	@echo "   make gen-sqlc        - Generate Go database code dari queries SQL"
	@echo "   make test-server     - Jalankan unit testing backend"
	@echo "   make lint-server     - Jalankan golangci-lint"
	@echo ""
	@echo " [Mobile (Flutter)]"
	@echo "   make dev-mobile      - Jalankan aplikasi Flutter di emulator/device"
	@echo "   make gen-mobile      - Jalankan build_runner (Freezed, Drift, Injectable)"
	@echo "   make test-mobile     - Jalankan test Flutter unit & widget"
	@echo "   make lint-mobile     - Jalankan flutter analyze"
	@echo "   make build-sub10mb   - Build release APK arm64-v8a target sub-10 MB"
	@echo ""
	@echo " [Quality & Full Check]"
	@echo "   make check-all       - Jalankan linter dan test untuk Go & Flutter"
	@echo ""

dev-db:
	@echo "Menyalakan PostgreSQL lokal..."
	$(DOCKER) compose -f $(COMPOSE_FILE) up -d postgres
	@echo "PostgreSQL aktif di localhost:5433"

dev-stack:
	@echo "Menyalakan seluruh stack (API + PostgreSQL) via Docker..."
	$(DOCKER) compose -f $(COMPOSE_FILE) up -d --build

stop-db:
	@echo "Menghentikan container PostgreSQL..."
	$(DOCKER) compose -f $(COMPOSE_FILE) stop

clean-db:
	@echo "Menghapus container dan volume data lokal..."
	$(DOCKER) compose -f $(COMPOSE_FILE) down -v

migrate-up:
	@echo "Menerapkan migrasi database via golang-migrate..."
	migrate -path $(SERVER_DIR)/db/migrations -database "postgres://savoryx_user:savoryx_secret@localhost:5433/savoryx_db?sslmode=disable" up

migrate-down:
	@echo "Rollback 1 langkah migrasi schema via golang-migrate..."
	migrate -path $(SERVER_DIR)/db/migrations -database "postgres://savoryx_user:savoryx_secret@localhost:5433/savoryx_db?sslmode=disable" down 1

seed-db:
	@echo "Menjalankan database seeder Savoryx..."
	cd $(SERVER_DIR) && $(GO) run ./cmd/seed

dev-server:
	@echo "Memulai Savoryx Go Backend..."
	cd $(SERVER_DIR) && $(GO) run ./cmd/api

swagger:
	@echo "OpenAPI 3.0 specification berlokasi di: $(SERVER_DIR)/docs/openapi.yaml"
	@echo "Swagger UI dapat diakses langsung pada: http://localhost:8080/swagger atau /docs"

gen-sqlc:
	@echo "Kompilasi query SQL ke Go code via sqlc..."
	cd $(SERVER_DIR) && (sqlc generate 2>/dev/null || "$(HOME)/go/bin/sqlc" generate 2>/dev/null || "C:/Users/fadhi/go/bin/sqlc.exe" generate)

test-server:
	@echo "Menjalankan Go unit tests..."
	cd $(SERVER_DIR) && $(GO) test -v ./...

lint-server:
	@echo "Memeriksa kode Go dengan golangci-lint..."
	cd $(SERVER_DIR) && golangci-lint run ./...

dev-mobile:
	@echo "Meluncurkan Flutter App (Debug Mode)..."
	cd $(MOBILE_DIR) && $(FLUTTER) run

gen-mobile:
	@echo "Menjalankan Dart build_runner..."
	cd $(MOBILE_DIR) && dart run build_runner build --delete-conflicting-outputs

test-mobile:
	@echo "Menjalankan Flutter tests..."
	cd $(MOBILE_DIR) && $(FLUTTER) test

lint-mobile:
	@echo "Menjalankan flutter analyze..."
	cd $(MOBILE_DIR) && $(FLUTTER) analyze

build-sub10mb:
	@echo "Mengompilasi Release APK (Split-per-ABI & Obfuscated)..."
	cd $(MOBILE_DIR) && $(FLUTTER) build apk --release --split-per-abi --obfuscate --split-debug-info=build/app/outputs/symbols
	@echo "Build selesai! Periksa ukuran file di:"
	@echo " $(MOBILE_DIR)/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"

check-all: lint-server test-server lint-mobile test-mobile
	@echo "Semua verifikasi linting dan testing lolos!"
