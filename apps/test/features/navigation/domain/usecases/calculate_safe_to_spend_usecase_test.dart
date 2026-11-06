import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/features/navigation/domain/usecases/calculate_safe_to_spend_usecase.dart';

void main() {
  group('CalculateSafeToSpendUseCase Pure Dart Math Tests', () {
    const useCase = CalculateSafeToSpendUseCase();

    test('healthy surplus balance computes accurate daily runway and health score', () {
      final result = useCase(
        totalLiquidBalance: BigInt.from(15000000), // Rp 15.000.000
        monthlyFixedObligations: BigInt.from(3000000), // Rp 3.000.000
        daysRemainingInMonth: 20,
      );

      // Discretionary: 15.000.000 - 3.000.000 = 12.000.000
      // Daily: 12.000.000 / 20 = 600.000
      expect(result.dailySafeToSpend, equals(BigInt.from(600000)));
      expect(result.daysRemainingInMonth, equals(20));
      expect(result.runwayDays, equals(20));
      expect(result.healthScore, greaterThanOrEqualTo(65));
    });

    test('zero or deficit discretionary balance clamps dailySafeToSpend to zero', () {
      final result = useCase(
        totalLiquidBalance: BigInt.from(2500000),
        monthlyFixedObligations: BigInt.from(5000000),
        daysRemainingInMonth: 15,
      );

      expect(result.dailySafeToSpend, equals(BigInt.zero));
      expect(result.runwayDays, equals(0));
      expect(result.healthScore, equals(35));
    });

    test('zero total liquid balance yields critical health score', () {
      final result = useCase(
        totalLiquidBalance: BigInt.zero,
        monthlyFixedObligations: BigInt.zero,
        daysRemainingInMonth: 10,
      );

      expect(result.dailySafeToSpend, equals(BigInt.zero));
      expect(result.healthScore, equals(15));
    });

    test('daysRemainingInMonth zero or negative is safely clamped to 1', () {
      final result = useCase(
        totalLiquidBalance: BigInt.from(500000),
        monthlyFixedObligations: BigInt.zero,
        daysRemainingInMonth: 0,
      );

      expect(result.daysRemainingInMonth, equals(1));
      expect(result.dailySafeToSpend, equals(BigInt.from(500000)));
    });
  });
}
