import 'package:injectable/injectable.dart';
import 'package:savoryx/features/navigation/domain/entities/safe_to_spend_entity.dart';

@lazySingleton
class CalculateSafeToSpendUseCase {
  const CalculateSafeToSpendUseCase();

  SafeToSpendEntity call({
    required BigInt totalLiquidBalance,
    required BigInt monthlyFixedObligations,
    required int daysRemainingInMonth,
    String currency = 'IDR',
  }) {
    final effectiveDays = daysRemainingInMonth <= 0 ? 1 : daysRemainingInMonth;

    final BigInt discretionaryBalance =
        totalLiquidBalance > monthlyFixedObligations
            ? totalLiquidBalance - monthlyFixedObligations
            : BigInt.zero;

    final BigInt dailySafeToSpend = discretionaryBalance > BigInt.zero
        ? discretionaryBalance ~/ BigInt.from(effectiveDays)
        : BigInt.zero;

    final int runwayDays = dailySafeToSpend > BigInt.zero
        ? (discretionaryBalance ~/ dailySafeToSpend).toInt()
        : 0;

    final int bufferDays =
        runwayDays > effectiveDays ? runwayDays - effectiveDays : 0;

    final int healthScore;
    if (totalLiquidBalance <= BigInt.zero) {
      healthScore = 15;
    } else if (discretionaryBalance <= BigInt.zero) {
      healthScore = 35;
    } else if (bufferDays >= 30) {
      healthScore = 95;
    } else if (bufferDays >= 14) {
      healthScore = 85;
    } else if (bufferDays >= 7) {
      healthScore = 75;
    } else if (bufferDays >= 0) {
      healthScore = 65;
    } else {
      healthScore = 45;
    }

    return SafeToSpendEntity(
      totalLiquidBalance: totalLiquidBalance,
      monthlyFixedObligations: monthlyFixedObligations,
      daysRemainingInMonth: effectiveDays,
      dailySafeToSpend: dailySafeToSpend,
      runwayDays: runwayDays,
      bufferDays: bufferDays,
      healthScore: healthScore,
      currency: currency,
    );
  }
}
