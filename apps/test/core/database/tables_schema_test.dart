import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('LocalAccounts & LocalCategories Drift Schema Tests', () {
    late AppDatabase database;
    const uuid = Uuid();

    setUp(() {
      // In-memory database with onCreate lifecycle triggering seedDefaultData
      database = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('fresh database initialization runs seedDefaultData correctly', () async {
      // Trigger database opening
      final accounts = await database.select(database.localAccounts).get();
      final categories = await database.select(database.localCategories).get();

      // Verify 4 default accounts seeded
      expect(accounts.length, equals(4));
      final accountNames = accounts.map((a) => a.name).toList();
      expect(accountNames, containsAll(['Kas Tunai', 'Rekening BCA', 'Dompet GoPay', 'Rekening Mandiri']));

      // Verify 8 default categories seeded
      expect(categories.length, equals(8));
      final needsCategories = categories.where((c) => !c.isWants).map((c) => c.name).toList();
      final wantsCategories = categories.where((c) => c.isWants).map((c) => c.name).toList();

      expect(needsCategories, containsAll(['Makan Pokok', 'Transportasi', 'Tagihan & Utilitas', 'Kesehatan']));
      expect(wantsCategories, containsAll(['Ngopi & Kafe', 'Hiburan & Streaming', 'Belanja & Hobi', 'Liburan & Healing']));
    });

    test('LocalAccounts enforces integer minor units and deterministic balance math', () async {
      final now = DateTime.now().toUtc();
      final accountId = uuid.v7();

      // Insert account with balance 2,500,000 IDR (in minor units: 2500000)
      final initialBalance = BigInt.from(250000000); // 2.500.000,00
      await database.into(database.localAccounts).insert(
            LocalAccountsCompanion.insert(
              id: accountId,
              name: 'Tabungan Darurat',
              type: 'BANK',
              balance: Value(initialBalance),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final inserted = await (database.select(database.localAccounts)..where((t) => t.id.equals(accountId))).getSingle();
      expect(inserted.name, equals('Tabungan Darurat'));
      expect(inserted.balance, equals(initialBalance));
      expect(inserted.currency, equals('IDR'));
      expect(inserted.isSynced, isFalse);
      expect(inserted.deletedAt, isNull);

      // Perform deterministic integer addition (+ 500,000 IDR)
      final depositAmount = BigInt.from(50000000);
      final newBalance = inserted.balance + depositAmount;

      await (database.update(database.localAccounts)..where((t) => t.id.equals(accountId))).write(
        LocalAccountsCompanion(
          balance: Value(newBalance),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );

      final updated = await (database.select(database.localAccounts)..where((t) => t.id.equals(accountId))).getSingle();
      expect(updated.balance, equals(BigInt.from(300000000)));
    });

    test('LocalCategories correctly preserves is_wants budget classification', () async {
      final now = DateTime.now().toUtc();
      final categoryId = uuid.v7();

      await database.into(database.localCategories).insert(
            LocalCategoriesCompanion.insert(
              id: categoryId,
              name: 'Gamer Subscriptions',
              icon: 'gamepad',
              color: '#BD10E0',
              isWants: const Value(true), // Explicitly a Want
              createdAt: now,
              updatedAt: now,
            ),
          );

      final cat = await (database.select(database.localCategories)..where((t) => t.id.equals(categoryId))).getSingle();
      expect(cat.name, equals('Gamer Subscriptions'));
      expect(cat.icon, equals('gamepad'));
      expect(cat.color, equals('#BD10E0'));
      expect(cat.isWants, isTrue);
      expect(cat.isSynced, isFalse);
    });

    test('Soft delete (tombstone pattern) flags deleted_at and filters active items', () async {
      final accountsBefore = await database.select(database.localAccounts).get();
      final targetAccount = accountsBefore.first;

      // Soft delete by setting deletedAt
      final deletedTimestamp = DateTime.now().toUtc();
      await (database.update(database.localAccounts)..where((t) => t.id.equals(targetAccount.id))).write(
        LocalAccountsCompanion(
          deletedAt: Value(deletedTimestamp),
          updatedAt: Value(deletedTimestamp),
        ),
      );

      // Query active accounts (where deletedAt is null)
      final activeAccounts = await (database.select(database.localAccounts)..where((t) => t.deletedAt.isNull())).get();
      expect(activeAccounts.length, equals(accountsBefore.length - 1));
      expect(activeAccounts.any((a) => a.id == targetAccount.id), isFalse);

      // Query raw database directly includes the tombstoned record for sync engines
      final rawAccount = await (database.select(database.localAccounts)..where((t) => t.id.equals(targetAccount.id))).getSingle();
      expect(rawAccount.deletedAt, isNotNull);
    });
  });
}
