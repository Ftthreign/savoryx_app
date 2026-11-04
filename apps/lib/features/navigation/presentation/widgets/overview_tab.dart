import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:savoryx/core/di/injection_container.dart';
import 'package:savoryx/core/theme/clay_colors.dart';
import 'package:savoryx/core/theme/clay_shadows.dart';
import 'package:savoryx/core/theme/clay_typography.dart';
import 'package:savoryx/core/utils/constants.dart';
import 'package:savoryx/core/utils/currency_converter.dart';
import 'package:savoryx/core/utils/currency_formatter.dart';
import 'package:savoryx/core/widgets/clay_button.dart';
import 'package:savoryx/core/widgets/clay_card.dart';
import 'package:savoryx/features/account/domain/entities/account_entity.dart';
import 'package:savoryx/features/account/domain/usecases/get_accounts_usecase.dart';
import 'package:savoryx/features/category/domain/entities/category_entity.dart';
import 'package:savoryx/features/category/domain/usecases/get_categories_usecase.dart';
import 'package:savoryx/features/navigation/domain/entities/safe_to_spend_entity.dart';
import 'package:savoryx/features/navigation/presentation/bloc/overview_bloc.dart';
import 'package:savoryx/features/navigation/presentation/bloc/overview_event.dart';
import 'package:savoryx/features/navigation/presentation/bloc/overview_state.dart';
import 'package:savoryx/features/search/domain/entities/search_filter_entity.dart';
import 'package:savoryx/features/search/presentation/bloc/search_bloc.dart';
import 'package:savoryx/features/search/presentation/bloc/search_event.dart';
import 'package:savoryx/features/search/presentation/bloc/search_state.dart';
import 'package:savoryx/features/search/presentation/widgets/clay_search_bar.dart';
import 'package:savoryx/features/search/presentation/widgets/search_filter_bottom_sheet.dart';
import 'package:savoryx/features/search/presentation/widgets/search_result_tile.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';
import 'package:savoryx/features/transaction/presentation/bloc/currency_bloc.dart';
import 'package:savoryx/features/transaction/presentation/bloc/currency_event.dart';
import 'package:savoryx/features/transaction/presentation/widgets/currency_picker_sheet.dart';
import 'package:savoryx/features/transaction/presentation/widgets/dual_currency_ledger_card.dart';

/// Presentation widget representing the Overview / PulseSpend screen.
/// Completely decoupled from SQLite/Drift DAOs and orchestrated via OverviewBloc.
class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key, this.bloc});

  final OverviewBloc? bloc;

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<OverviewBloc>.value(
        value: bloc!,
        child: const _OverviewContentView(),
      );
    }

    return BlocProvider<OverviewBloc>(
      create: (_) => getIt<OverviewBloc>()..add(const OverviewLoadStarted()),
      child: const _OverviewContentView(),
    );
  }
}

class _OverviewContentView extends StatelessWidget {
  const _OverviewContentView();

  Future<void> _openCurrencyPicker(
    BuildContext context,
    String currentCurrency,
  ) async {
    final picked = await CurrencyPickerSheet.show(
      context,
      selectedCurrency: currentCurrency,
    );

    if (picked != null && picked != currentCurrency) {
      final info = CurrencyConverter.supportedCurrencies[picked];
      final symbol = info?.symbol ?? picked;

      if (context.mounted) {
        context.read<OverviewBloc>().add(
              OverviewCurrencyChanged(picked, symbol),
            );
      }

      if (getIt.isRegistered<CurrencyBloc>()) {
        getIt<CurrencyBloc>().add(CurrencySelected(picked));
        getIt<CurrencyBloc>().add(LoadExchangeRates(baseCurrency: picked));
      }
    }
  }

  void _openSearchModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider<SearchBloc>(
        create: (_) => getIt<SearchBloc>(),
        child: const _OverviewSearchSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OverviewBloc, OverviewState>(
      builder: (context, state) {
        return SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            key: const PageStorageKey<String>('overview_scroll_view'),
            padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 110.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Top Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PULSESPEND // SAVORYX',
                            style: ClayTypography.labelSm(
                              color: ClayColors.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            'Overview',
                            style: ClayTypography.headlineSm(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Row(
                      children: [
                        // Search Bar Trigger Button
                        ClayButton(
                          key: const Key('overview_search_button'),
                          width: 40.0,
                          height: 40.0,
                          padding: EdgeInsets.zero,
                          borderRadius: BorderRadius.circular(20.0),
                          semanticLabel: 'Cari transaksi',
                          onTap: () => _openSearchModal(context),
                          child: Icon(
                            Icons.search_rounded,
                            size: 20.0,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8.0),

                        // Currency Selector Button
                        ClayButton(
                          key: const Key('overview_currency_button'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                          borderRadius: BorderRadius.circular(18.0),
                          onTap: () => _openCurrencyPicker(
                            context,
                            state.selectedCurrency,
                          ),
                          child: Text(
                            '${state.selectedCurrency} (${state.selectedCurrencySymbol})',
                            style: ClayTypography.labelMd(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),

                        // Privacy Shield Button
                        ClayButton(
                          width: 40.0,
                          height: 40.0,
                          padding: EdgeInsets.zero,
                          borderRadius: BorderRadius.circular(20.0),
                          semanticLabel: 'Sembunyikan saldo',
                          onTap: () => context
                              .read<OverviewBloc>()
                              .add(const OverviewMaskToggled()),
                          child: Icon(
                            state.isMasked
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 18.0,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),

                // Hero Spend Card (Safe-to-Spend Runway)
                _buildHeroCard(context, state.safeToSpend, state.isMasked),
                const SizedBox(height: 18.0),

                // Behavioral Fast-Action Row
                Row(
                  children: [
                    Expanded(
                      child: ClayButton(
                        color: ClayColors.tertiaryContainer,
                        borderRadius: BorderRadius.circular(24.0),
                        padding: const EdgeInsets.all(14.0),
                        onTap: () {
                          context.read<OverviewBloc>().add(
                                const OverviewSafeToSpendStashed(
                                  amountMinorUnits: 45000,
                                ),
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Impulse deflected! +Rp 45k moved to Sinking Fund',
                              ),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 36.0,
                              height: 36.0,
                              decoration: const BoxDecoration(
                                color: ClayColors.tertiaryFixed,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.shield,
                                size: 20.0,
                                color: ClayColors.onTertiaryFixed,
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Saya Batal Beli',
                                    style: ClayTypography.labelLg(
                                      color: ClayColors.onTertiary,
                                    ),
                                  ),
                                  Text(
                                    '+${CurrencyFormatter.formatCompactRupiah(state.stashedImpulseFund)} Stashed',
                                    style: ClayTypography.labelSm(
                                      color: ClayColors.tertiaryChip,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22.0),

                // Accounts Horizontal Carousel Section
                Text(
                  'Pockets & Accounts',
                  style: ClayTypography.headlineSm(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12.0),
                _buildAccountsCarousel(context, state.accounts, state.isMasked),
                const SizedBox(height: 24.0),

                // Recent Tactile Ledger Section
                Text(
                  'Recent Tactile Ledger',
                  style: ClayTypography.headlineSm(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12.0),
                _buildRecentLedger(
                  state.recentTransactions,
                  state.accounts,
                  state.isMasked,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    SafeToSpendEntity safeToSpend,
    bool isMasked,
  ) {
    final int dailyAmount = safeToSpend.dailySafeToSpend > BigInt.zero
        ? safeToSpend.dailySafeToSpend.toInt()
        : 145000;

    return ClayCard(
      isHero: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 28.0,
                      height: 28.0,
                      decoration: const BoxDecoration(
                        color: ClayColors.secondaryFixed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.speed,
                        size: 16.0,
                        color: ClayColors.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        'SAFE-TO-SPEND RUNWAY',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ClayTypography.labelLg(
                          color: ClayColors.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  'Health Score: ${safeToSpend.healthScore}',
                  style: ClayTypography.labelSm(
                    color: ClayColors.tertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            CurrencyFormatter.formatMasked(dailyAmount, isMasked: isMasked),
            style: ClayTypography.headlineXl(
              color: ClayColors.onSurface,
            ),
          ),
          Text(
            '/ day safe remaining',
            style: ClayTypography.labelMd(
              color: ClayColors.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 12.0),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 6.0,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(14.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.hourglass_top,
                  size: 14.0,
                  color: ClayColors.secondary,
                ),
                const SizedBox(width: 4.0),
                Text(
                  '≈ ${CurrencyFormatter.calculateWorkHours(dailyAmount)} working hours',
                  style: ClayTypography.labelSm(
                    color: ClayColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsCarousel(
    BuildContext context,
    List<AccountEntity> accounts,
    bool isMasked,
  ) {
    if (accounts.isEmpty) {
      return _buildDefaultAccountsList(context, isMasked);
    }

    return SizedBox(
      height: 145.0,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: accounts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12.0),
        itemBuilder: (context, index) {
          final account = accounts[index];
          final IconData icon;
          final Color iconColor;

          switch (account.type) {
            case AccountType.bank:
              icon = Icons.account_balance;
              iconColor = ClayColors.primary;
              break;
            case AccountType.eWallet:
              icon = Icons.account_balance_wallet;
              iconColor = ClayColors.secondary;
              break;
            case AccountType.cash:
              icon = Icons.payments;
              iconColor = ClayColors.tertiary;
              break;
            default:
              icon = Icons.credit_card;
              iconColor = ClayColors.primary;
          }

          return _buildAccountCard(
            context,
            account.name,
            account.balance,
            icon,
            iconColor,
            isMasked,
          );
        },
      ),
    );
  }

  Widget _buildDefaultAccountsList(BuildContext context, bool isMasked) {
    return SizedBox(
      height: 145.0,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          _buildAccountCard(context, 'BCA Main', 14820000,
              Icons.account_balance, ClayColors.primary, isMasked),
          const SizedBox(width: 12.0),
          _buildAccountCard(context, 'Mandiri Payroll', 6350000,
              Icons.credit_card, ClayColors.secondary, isMasked),
          const SizedBox(width: 12.0),
          _buildAccountCard(context, 'Cash Pocket', 480000, Icons.payments,
              ClayColors.tertiary, isMasked),
          const SizedBox(width: 12.0),
          _buildAccountCard(context, 'GoPay Wallet', 320000,
              Icons.account_balance_wallet, ClayColors.secondary, isMasked),
        ],
      ),
    );
  }

  Widget _buildRecentLedger(
    List<TransactionEntity> transactions,
    List<AccountEntity> accounts,
    bool isMasked,
  ) {
    if (transactions.isEmpty) {
      return _buildDefaultLedgerList(isMasked);
    }

    final Map<String, String> accountNames = {
      for (final a in accounts) a.id: a.name,
    };

    return Column(
      children: transactions.map((tx) {
        final accountName = accountNames[tx.accountId] ?? 'Akun';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: DualCurrencyLedgerCard.fromEntity(
            entity: tx,
            accountName: accountName,
            isMasked: isMasked,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDefaultLedgerList(bool isMasked) {
    return Column(
      children: [
        DualCurrencyLedgerCard(
          title: 'Kopi Kenangan Senopati',
          amount: 38000,
          currency: 'IDR',
          type: TransactionType.expense,
          time: '10:42 AM',
          pocketOrAccount: 'GoPay',
          categoryIcon: 'coffee',
          isMasked: isMasked,
        ),
        const SizedBox(height: 10.0),
        DualCurrencyLedgerCard(
          title: 'Freelance UI Sprint',
          amount: 3500000,
          currency: 'IDR',
          type: TransactionType.income,
          time: 'Yesterday',
          pocketOrAccount: 'BCA Main',
          categoryIcon: 'receipt',
          isMasked: isMasked,
        ),
        const SizedBox(height: 10.0),
        DualCurrencyLedgerCard(
          title: 'Figma Pro Subscription',
          amount: 15,
          currency: 'USD',
          baseAmount: 243750,
          exchangeRateToBase: BigInt.from(16250000000),
          type: TransactionType.expense,
          time: 'Monday, 19:15',
          pocketOrAccount: 'Rekening BCA',
          categoryIcon: 'shopping',
          isMasked: isMasked,
        ),
      ],
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    String title,
    int amount,
    IconData icon,
    Color iconColor,
    bool isMasked,
  ) {
    return ClayCard(
      width: 180.0,
      borderRadius: BorderRadius.circular(AppConstants.clayCarouselRadius),
      padding: const EdgeInsets.all(14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20.0, color: iconColor),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClayTypography.labelSm(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available',
                style: ClayTypography.bodySm(
                  color: ClayColors.onSurfaceVariant,
                ),
              ),
              Text(
                CurrencyFormatter.formatMasked(amount, isMasked: isMasked),
                style: ClayTypography.headlineSm(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Instant Search Modal Sheet for Overview Tab powered by Clean Architecture SearchBloc
class _OverviewSearchSheet extends StatefulWidget {
  const _OverviewSearchSheet();

  @override
  State<_OverviewSearchSheet> createState() => _OverviewSearchSheetState();
}

class _OverviewSearchSheetState extends State<_OverviewSearchSheet> {
  String _currentQuery = '';
  SearchFilterEntity _filter = SearchFilterEntity.empty;

  Future<void> _openFilterModal() async {
    List<AccountEntity> accounts = [];
    List<CategoryEntity> categories = [];

    if (getIt.isRegistered<GetAccountsUseCase>()) {
      accounts = await getIt<GetAccountsUseCase>()();
    }
    if (getIt.isRegistered<GetCategoriesUseCase>()) {
      categories = await getIt<GetCategoriesUseCase>()();
    }

    if (!mounted) return;
    final updatedFilter = await SearchFilterBottomSheet.show(
      context,
      initialFilter: _filter,
      accounts: accounts,
      categories: categories,
    );

    if (updatedFilter != null && mounted) {
      setState(() => _filter = updatedFilter);
      context.read<SearchBloc>().add(SearchFilterApplied(updatedFilter));
    }
  }

  void _onSearchDebounced(String query) {
    _currentQuery = query;
    context.read<SearchBloc>().add(SearchQueryChanged(query));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg =
        isDark ? ClayColors.surfaceDark : ClayColors.surfaceContainerLowest;
    final subtitleColor =
        isDark ? ClayColors.onSurfaceVariantDark : ClayColors.outline;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
        boxShadow: ClayShadows.elevated(isDark: isDark, scale: 1.2),
      ),
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 14.0,
        bottom: 20.0 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44.0,
              height: 5.0,
              decoration: BoxDecoration(
                color: isDark
                    ? ClayColors.surfaceContainerDark
                    : ClayColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
          const SizedBox(height: 16.0),

          // Search Bar
          ClaySearchBar(
            autofocus: true,
            hintText: 'Cari catatan, merchant, #tag...',
            hasActiveFilter: _filter.hasActiveFilter,
            onSearchDebounced: _onSearchDebounced,
            onFilterTap: _openFilterModal,
          ),
          const SizedBox(height: 14.0),

          // Search Results / Filter Status Area
          Expanded(
            child: BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) {
                switch (state) {
                  case SearchInitial():
                    return Center(
                      child: Text(
                        'Ketik minimal 1 karakter untuk mencari...',
                        style: ClayTypography.bodyMd(color: subtitleColor),
                      ),
                    );
                  case SearchLoading():
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  case SearchEmpty():
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48.0,
                            color: subtitleColor,
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            'Tidak ada transaksi yang cocok.',
                            style: ClayTypography.bodyMd(color: subtitleColor),
                          ),
                        ],
                      ),
                    );
                  case SearchLoaded(:final results):
                    if (results.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48.0,
                              color: subtitleColor,
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'Tidak ada transaksi yang cocok.',
                              style: ClayTypography.bodyMd(color: subtitleColor),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      key: const Key('overview_search_results_list'),
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8.0),
                      itemBuilder: (ctx, idx) {
                        final res = results[idx];
                        return SearchResultTile.fromEntity(
                          result: res,
                          highlightQuery: _currentQuery,
                        );
                      },
                    );
                  case SearchFailure(:final message):
                    return Center(
                      child: Text(
                        'Error: $message',
                        style: ClayTypography.bodyMd(color: ClayColors.primary),
                      ),
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
