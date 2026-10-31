package main

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"time"

	"github.com/ftthreign/savoryx_app/server/internal/adapter/repository/postgres"
	"github.com/ftthreign/savoryx_app/server/internal/adapter/security"
	"github.com/ftthreign/savoryx_app/server/internal/core/domain"
	"github.com/shopspring/decimal"
)

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	}))
	slog.SetDefault(logger)

	databaseURL := os.Getenv("DATABASE_URL")
	if databaseURL == "" {
		databaseURL = "postgres://savoryx_user:savoryx_secret@127.0.0.1:5433/savoryx_db?sslmode=disable"
	}

	logger.Info("connecting to database for seeding...")
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	db, err := postgres.NewDB(ctx, databaseURL)
	if err != nil {
		logger.Error("failed to connect to postgres", "error", err)
		os.Exit(1)
	}
	defer db.Close()

	logger.Info("database connected. Starting seed operation...")

	prefRepo := postgres.NewPreferenceRepository(db)
	accRepo := postgres.NewAccountRepository(db)
	catRepo := postgres.NewCategoryRepository(db)
	devRepo := postgres.NewDeviceRepository(db)

	tokenManager, err := security.NewPasetoTokenManager("")
	if err != nil {
		logger.Error("failed to init paseto token manager", "error", err)
		os.Exit(1)
	}

	// 1. Seed User Preferences
	userPrefID := domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000000")
	pref := &domain.UserPreference{
		ID:               userPrefID,
		Theme:            domain.ThemePreferenceClayLight,
		FontFamily:       domain.FontFamilyNunitoSans,
		BaseCurrency:     "IDR",
		MonthlyWorkHours: 160,
		MonthlyIncomeNet: decimal.NewFromInt(15000000), // Rp 15.000.000,00
		UpdatedAt:        time.Now().UTC(),
	}
	if err := prefRepo.Upsert(ctx, pref); err != nil {
		logger.Error("failed to seed user preferences", "error", err)
	} else {
		logger.Info("seeded user preferences", "id", userPrefID.String())
	}

	// 2. Seed Accounts
	accounts := []*domain.Account{
		{
			ID:       domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000011"),
			Name:     "Dompet Tunai (Cash)",
			Type:     domain.AccountTypeCash,
			Currency: "IDR",
			Balance:  decimal.NewFromInt(500000),
		},
		{
			ID:       domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000012"),
			Name:     "BCA Prioritas",
			Type:     domain.AccountTypeBank,
			Currency: "IDR",
			Balance:  decimal.NewFromInt(12500000),
		},
		{
			ID:       domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000013"),
			Name:     "GoPay / OVO",
			Type:     domain.AccountTypeEWallet,
			Currency: "IDR",
			Balance:  decimal.NewFromInt(350000),
		},
		{
			ID:       domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000014"),
			Name:     "BCA Everyday Card",
			Type:     domain.AccountTypeCreditCard,
			Currency: "IDR",
			Balance:  decimal.Zero,
		},
		{
			ID:       domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000015"),
			Name:     "Bibit Reksadana & Saham",
			Type:     domain.AccountTypeInvestment,
			Currency: "IDR",
			Balance:  decimal.NewFromInt(25000000),
		},
	}

	for _, acc := range accounts {
		existing, _ := accRepo.GetByID(ctx, acc.ID)
		if existing == nil {
			if err := accRepo.Create(ctx, acc); err != nil {
				logger.Warn("account already exists or failed to create", "name", acc.Name, "error", err)
			} else {
				logger.Info("seeded account", "name", acc.Name, "balance", acc.Balance.String())
			}
		} else {
			logger.Info("account already exists, skipping", "name", acc.Name)
		}
	}

	// 3. Seed Categories (Needs vs Wants classification)
	categories := []*domain.Category{
		// Needs (is_wants = false)
		{
			ID:      domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000021"),
			Name:    "Makanan & Minuman",
			Icon:    "fastfood",
			Color:   "#8DB355",
			IsWants: false,
		},
		{
			ID:      domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000022"),
			Name:    "Transportasi",
			Icon:    "directions_car",
			Color:   "#4A90E2",
			IsWants: false,
		},
		{
			ID:      domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000023"),
			Name:    "Tagihan & Listrik",
			Icon:    "receipt_long",
			Color:   "#F5A623",
			IsWants: false,
		},
		{
			ID:      domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000024"),
			Name:    "Belanja Bulanan",
			Icon:    "shopping_cart",
			Color:   "#7ED321",
			IsWants: false,
		},
		{
			ID:      domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000025"),
			Name:    "Kesehatan & Obat",
			Icon:    "medical_services",
			Color:   "#D0021B",
			IsWants: false,
		},
		// Wants (is_wants = true)
		{
			ID:      domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000031"),
			Name:    "Kafe & Nongkrong",
			Icon:    "local_cafe",
			Color:   "#D90000",
			IsWants: true,
		},
		{
			ID:      domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000032"),
			Name:    "Hiburan & Netflix",
			Icon:    "movie",
			Color:   "#9013FE",
			IsWants: true,
		},
		{
			ID:      domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000033"),
			Name:    "Belanja Keinginan",
			Icon:    "shopping_bag",
			Color:   "#FFEA93",
			IsWants: true,
		},
		{
			ID:      domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000034"),
			Name:    "Hobi & Gaming",
			Icon:    "sports_esports",
			Color:   "#50E3C2",
			IsWants: true,
		},
	}

	for _, cat := range categories {
		existing, _ := catRepo.GetByID(ctx, cat.ID)
		if existing == nil {
			if err := catRepo.Create(ctx, cat); err != nil {
				logger.Warn("category already exists or failed to create", "name", cat.Name, "error", err)
			} else {
				logger.Info("seeded category", "name", cat.Name, "is_wants", cat.IsWants)
			}
		} else {
			logger.Info("category already exists, skipping", "name", cat.Name)
		}
	}

	// 4. Seed Development Device & Generate PASETO Auth Token
	devID := domain.MustParseUUID("0192d6e2-5b9c-7000-8000-000000000001")
	existingDev, _ := devRepo.GetByID(ctx, devID)
	if existingDev == nil {
		rawSecret, _ := tokenManager.GenerateDeviceSecret()
		secretHash := tokenManager.HashDeviceSecret(rawSecret)

		dev := &domain.Device{
			ID:               devID,
			DeviceName:       "Pixel 8 Pro (Dev)",
			Platform:         "android",
			AppVersion:       "1.0.0",
			DeviceSecretHash: secretHash,
			CreatedAt:        time.Now().UTC(),
			LastActiveAt:     time.Now().UTC(),
		}
		if err := devRepo.Register(ctx, dev); err != nil {
			logger.Warn("device already exists or failed to register", "error", err)
		} else {
			logger.Info("seeded development device", "name", dev.DeviceName, "id", devID.String())
		}
	} else {
		logger.Info("development device already exists, skipping", "id", devID.String())
	}

	// Generate and print a valid PASETO test token for API calls
	token, err := tokenManager.GenerateDeviceToken(devID, 30*24*time.Hour)
	if err == nil {
		fmt.Println("")
		fmt.Println("================================================================================")
		fmt.Println("SEED COMPLETED SUCCESSFULLY!")
		fmt.Println("Use the following PASETO Bearer token for authorized API testing:")
		fmt.Printf("Authorization: Bearer %s\n", token)
		fmt.Println("================================================================================")
		fmt.Println("")
	}
}
