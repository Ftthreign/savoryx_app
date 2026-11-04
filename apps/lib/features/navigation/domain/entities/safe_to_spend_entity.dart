/// Pure Dart domain entity representing the Safe-to-Spend daily runway.
/// Zero-floating-point: all currency balances are strictly stored in integer minor units.
class SafeToSpendEntity {
  const SafeToSpendEntity({
    required this.totalLiquidBalance,
    required this.monthlyFixedObligations,
    required this.daysRemainingInMonth,
    required this.dailySafeToSpend,
    required this.runwayDays,
    required this.bufferDays,
    required this.healthScore,
    this.currency = 'IDR',
  });

  /// Total liquid balance across all active non-credit accounts in minor units (sen/rupiah).
  final BigInt totalLiquidBalance;

  /// Monthly fixed recurring commitments/bills in minor units.
  final BigInt monthlyFixedObligations;

  /// Days remaining in the active calendar cycle/month.
  final int daysRemainingInMonth;

  /// Deterministic daily safe expenditure allowance in minor units.
  final BigInt dailySafeToSpend;

  /// Projected days the liquid balance will last given active burn rate.
  final int runwayDays;

  /// Extra safety margin days before breaching survival floor.
  final int bufferDays;

  /// Holistic financial vitality score between 0 and 100.
  final int healthScore;

  /// Base ISO-4217 currency code.
  final String currency;

  static final SafeToSpendEntity initial = SafeToSpendEntity(
    totalLiquidBalance: BigInt.zero,
    monthlyFixedObligations: BigInt.zero,
    daysRemainingInMonth: 30,
    dailySafeToSpend: BigInt.zero,
    runwayDays: 0,
    bufferDays: 0,
    healthScore: 50,
  );

  SafeToSpendEntity copyWith({
    BigInt? totalLiquidBalance,
    BigInt? monthlyFixedObligations,
    int? daysRemainingInMonth,
    BigInt? dailySafeToSpend,
    int? runwayDays,
    int? bufferDays,
    int? healthScore,
    String? currency,
  }) {
    return SafeToSpendEntity(
      totalLiquidBalance: totalLiquidBalance ?? this.totalLiquidBalance,
      monthlyFixedObligations:
          monthlyFixedObligations ?? this.monthlyFixedObligations,
      daysRemainingInMonth: daysRemainingInMonth ?? this.daysRemainingInMonth,
      dailySafeToSpend: dailySafeToSpend ?? this.dailySafeToSpend,
      runwayDays: runwayDays ?? this.runwayDays,
      bufferDays: bufferDays ?? this.bufferDays,
      healthScore: healthScore ?? this.healthScore,
      currency: currency ?? this.currency,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SafeToSpendEntity &&
        other.totalLiquidBalance == totalLiquidBalance &&
        other.monthlyFixedObligations == monthlyFixedObligations &&
        other.daysRemainingInMonth == daysRemainingInMonth &&
        other.dailySafeToSpend == dailySafeToSpend &&
        other.runwayDays == runwayDays &&
        other.bufferDays == bufferDays &&
        other.healthScore == healthScore &&
        other.currency == currency;
  }

  @override
  int get hashCode => Object.hash(
        totalLiquidBalance,
        monthlyFixedObligations,
        daysRemainingInMonth,
        dailySafeToSpend,
        runwayDays,
        bufferDays,
        healthScore,
        currency,
      );
}
