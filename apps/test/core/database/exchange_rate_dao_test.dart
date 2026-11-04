// ignore: unused_import
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/core/database/daos/exchange_rate_dao.dart';

void main() {
  group('ExchangeRateDao & LocalExchangeRates SQLite Tests (Task #30)', () {
    late AppDatabase database;
    late ExchangeRateDao dao;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      dao = database.exchangeRateDao;
    });

    tearDown(() async {
      await database.close();
    });

    test('upsertRate and getRate stores and retrieves currency rate by date',
        () async {
      final date = DateTime.utc(2026, 11, 4);
      final rateUSD = BigInt.from(16250750000); // 16,250.75 scaled by 10^6

      await dao.upsertRate(
        LocalExchangeRatesCompanion.insert(
          baseCurrency: 'USD',
          targetCurrency: 'IDR',
          rate: rateUSD,
          effectiveDate: date,
          updatedAt: date,
        ),
      );

      final retrieved = await dao.getRate(
        base: 'usd',
        target: 'idr',
        date: date,
      );

      expect(retrieved, isNotNull);
      expect(retrieved!.baseCurrency, equals('USD'));
      expect(retrieved.targetCurrency, equals('IDR'));
      expect(retrieved.rate, equals(rateUSD));
    });

    test('upsertRate on identical key updates existing rate without duplicates',
        () async {
      final date = DateTime.utc(2026, 11, 4);
      final initialRate = BigInt.from(16000000000);
      final updatedRate = BigInt.from(16100000000);

      await dao.upsertRate(
        LocalExchangeRatesCompanion.insert(
          baseCurrency: 'USD',
          targetCurrency: 'IDR',
          rate: initialRate,
          effectiveDate: date,
          updatedAt: date,
        ),
      );

      // Upsert with updated rate
      await dao.upsertRate(
        LocalExchangeRatesCompanion.insert(
          baseCurrency: 'USD',
          targetCurrency: 'IDR',
          rate: updatedRate,
          effectiveDate: date,
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      final rates = await dao.getAllRatesForDate(date, base: 'USD');
      expect(rates.length, equals(1));
      expect(rates.first.rate, equals(updatedRate));
    });

    test('getLatestRate returns the newest effective date record', () async {
      final day1 = DateTime.utc(2026, 11, 1);
      final day2 = DateTime.utc(2026, 11, 2);
      final day3 = DateTime.utc(2026, 11, 3);

      await dao.upsertRatesBatch([
        LocalExchangeRatesCompanion.insert(
          baseCurrency: 'EUR',
          targetCurrency: 'USD',
          rate: BigInt.from(1080000), // 1.08
          effectiveDate: day1,
          updatedAt: day1,
        ),
        LocalExchangeRatesCompanion.insert(
          baseCurrency: 'EUR',
          targetCurrency: 'USD',
          rate: BigInt.from(1090000), // 1.09
          effectiveDate: day3,
          updatedAt: day3,
        ),
        LocalExchangeRatesCompanion.insert(
          baseCurrency: 'EUR',
          targetCurrency: 'USD',
          rate: BigInt.from(1085000), // 1.085
          effectiveDate: day2,
          updatedAt: day2,
        ),
      ]);

      final latest = await dao.getLatestRate(base: 'EUR', target: 'USD');
      expect(latest, isNotNull);
      expect(latest!.effectiveDate.isAtSameMomentAs(day3), isTrue);
      expect(latest.rate, equals(BigInt.from(1090000)));
    });

    test(
        'identity rate query returns 1.0 (1,000,000) immediately without DB lookup',
        () async {
      final rate = await dao.getRate(
        base: 'IDR',
        target: 'idr',
        date: DateTime.now(),
      );

      expect(rate, isNotNull);
      expect(rate!.baseCurrency, equals('IDR'));
      expect(rate.targetCurrency, equals('IDR'));
      expect(rate.rate, equals(BigInt.from(1000000)));

      final latestIdentity =
          await dao.getLatestRate(base: 'USD', target: 'USD');
      expect(latestIdentity, isNotNull);
      expect(latestIdentity!.rate, equals(BigInt.from(1000000)));
    });

    test('watchLatestRate emits updates reactively when new rate is upserted',
        () async {
      final stream = dao.watchLatestRate(base: 'SGD', target: 'IDR');

      final expectation = expectLater(
        stream,
        emitsInOrder([
          isNull, // Initially null
          isNotNull, // Emitted after upsert
        ]),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final now = DateTime.utc(2026, 11, 4);
      await dao.upsertRate(
        LocalExchangeRatesCompanion.insert(
          baseCurrency: 'SGD',
          targetCurrency: 'IDR',
          rate: BigInt.from(12100000000), // 12,100 IDR
          effectiveDate: now,
          updatedAt: now,
        ),
      );

      await expectation;
    });
  });
}
