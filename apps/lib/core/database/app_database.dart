// ignore_for_file: unused_field

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import 'package:savoryx/core/database/connection/native.dart' as impl;
import 'package:savoryx/core/database/daos/account_dao.dart';
import 'package:savoryx/core/database/daos/category_dao.dart';
import 'package:savoryx/core/database/daos/transaction_dao.dart';
import 'package:savoryx/core/database/tables/accounts_table.dart';
import 'package:savoryx/core/database/tables/categories_table.dart';
import 'package:savoryx/core/database/tables/transactions_table.dart';

part 'app_database.g.dart';

@lazySingleton
@DriftDatabase(
  tables: [LocalAccounts, LocalCategories, LocalTransactions],
  daos: [AccountDao, CategoryDao, TransactionDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(impl.connect());
  AppDatabase.executor(super.executor);
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await seedDefaultData();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Migration strategies for future schema increments
      },
      beforeOpen: (OpeningDetails details) async {
        // Additional hook before queries are allowed
      },
    );
  }

  Future<void> seedDefaultData() async {
    final now = DateTime.now().toUtc();
    const uuid = Uuid();

    final defaultAccounts = [
      LocalAccountsCompanion.insert(
        id: uuid.v7(),
        name: 'Kas Tunai',
        type: 'CASH',
        balance: Value(BigInt.zero),
        currency: const Value('IDR'),
        createdAt: now,
        updatedAt: now,
        isSynced: const Value(false),
      ),
      LocalAccountsCompanion.insert(
        id: uuid.v7(),
        name: 'Rekening BCA',
        type: 'BANK',
        balance: Value(BigInt.zero),
        currency: const Value('IDR'),
        createdAt: now,
        updatedAt: now,
        isSynced: const Value(false),
      ),
      LocalAccountsCompanion.insert(
        id: uuid.v7(),
        name: 'Dompet GoPay',
        type: 'E_WALLET',
        balance: Value(BigInt.zero),
        currency: const Value('IDR'),
        createdAt: now,
        updatedAt: now,
        isSynced: const Value(false),
      ),
      LocalAccountsCompanion.insert(
        id: uuid.v7(),
        name: 'Rekening Mandiri',
        type: 'BANK',
        balance: Value(BigInt.zero),
        currency: const Value('IDR'),
        createdAt: now,
        updatedAt: now,
        isSynced: const Value(false),
      ),
    ];

    final defaultCategories = [
      LocalCategoriesCompanion.insert(
        id: uuid.v7(),
        name: 'Makan Pokok',
        icon: 'utensils',
        color: '#8DB355',
        isWants: const Value(false),
        createdAt: now,
        updatedAt: now,
        isSynced: const Value(false),
      ),
      LocalCategoriesCompanion.insert(
        id: uuid.v7(),
        name: 'Transportasi',
        icon: 'bus',
        color: '#4A90E2',
        isWants: const Value(false),
        createdAt: now,
        updatedAt: now,
        isSynced: const Value(false),
      ),
      LocalCategoriesCompanion.insert(
        id: uuid.v7(),
        name: 'Tagihan & Utilitas',
        icon: 'receipt',
        color: '#F5A623',
        isWants: const Value(false),
        createdAt: now,
        updatedAt: now,
        isSynced: const Value(false),
      ),
      LocalCategoriesCompanion.insert(
        id: uuid.v7(),
        name: 'Kesehatan',
        icon: 'heart-pulse',
        color: '#D90000',
        isWants: const Value(false),
        createdAt: now,
        updatedAt: now,
        isSynced: const Value(false),
      ),
      LocalCategoriesCompanion.insert(
        id: uuid.v7(),
        name: 'Ngopi & Kafe',
        icon: 'coffee',
        color: '#FFEA93',
        isWants: const Value(true),
        createdAt: now,
        updatedAt: now,
        isSynced: const Value(false),
      ),
      LocalCategoriesCompanion.insert(
        id: uuid.v7(),
        name: 'Hiburan & Streaming',
        icon: 'film',
        color: '#BD10E0',
        isWants: const Value(true),
        createdAt: now,
        updatedAt: now,
        isSynced: const Value(false),
      ),
      LocalCategoriesCompanion.insert(
        id: uuid.v7(),
        name: 'Belanja & Hobi',
        icon: 'bag-shopping',
        color: '#50E3C2',
        isWants: const Value(true),
        createdAt: now,
        updatedAt: now,
        isSynced: const Value(false),
      ),
      LocalCategoriesCompanion.insert(
        id: uuid.v7(),
        name: 'Liburan & Healing',
        icon: 'plane',
        color: '#9013FE',
        isWants: const Value(true),
        createdAt: now,
        updatedAt: now,
        isSynced: const Value(false),
      ),
    ];

    await batch((b) {
      b.insertAll(localAccounts, defaultAccounts);
      b.insertAll(localCategories, defaultCategories);
    });
  }
}
