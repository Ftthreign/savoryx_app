import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/core/di/injection_container.dart';
import 'package:savoryx/core/theme/clay_colors.dart';
import 'package:savoryx/core/theme/clay_shadows.dart';
import 'package:savoryx/core/theme/clay_typography.dart';
import 'package:savoryx/core/utils/constants.dart';
import 'package:savoryx/core/utils/currency_converter.dart';
import 'package:savoryx/core/utils/currency_formatter.dart';
import 'package:savoryx/core/widgets/clay_button.dart';
import 'package:savoryx/core/widgets/clay_card.dart';
import 'package:savoryx/features/search/domain/entities/search_filter_entity.dart';
import 'package:savoryx/features/search/presentation/widgets/clay_search_bar.dart';
import 'package:savoryx/features/search/presentation/widgets/search_filter_bottom_sheet.dart';
import 'package:savoryx/features/search/presentation/widgets/search_result_tile.dart';
import 'package:savoryx/features/transaction/presentation/widgets/currency_picker_sheet.dart';

class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  bool _isMasked = false;
  int _stashedFund = 45000;
  String _selectedBaseCurrency = 'IDR';
  String _selectedBaseSymbol = 'Rp';

  Stream<List<LocalAccount>>? _accountsStream;
  Stream<List<LocalTransaction>>? _transactionsStream;

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  void _initStreams() {
    if (getIt.isRegistered<AppDatabase>()) {
      final db = getIt<AppDatabase>();
      _accountsStream = db.accountDao.watchAllActiveAccounts();
      _transactionsStream =
          db.transactionDao.watchRecentTransactions(limit: 20);
    }
  }

  void _toggleMask() {
    setState(() => _isMasked = !_isMasked);
  }

  void _stashImpulse() {
    setState(() => _stashedFund += 45000);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Impulse deflected! +Rp 45k moved to Sinking Fund'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _openCurrencyPicker() async {
    final picked = await CurrencyPickerSheet.show(
      context,
      selectedCurrency: _selectedBaseCurrency,
    );

    if (picked != null && picked != _selectedBaseCurrency) {
      final info = CurrencyConverter.supportedCurrencies[picked];
      setState(() {
        _selectedBaseCurrency = picked;
        _selectedBaseSymbol = info?.symbol ?? picked;
      });
    }
  }

  void _openSearchModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _OverviewSearchSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                Column(
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
                      onTap: _openSearchModal,
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
                      onTap: _openCurrencyPicker,
                      child: Text(
                        '$_selectedBaseCurrency ($_selectedBaseSymbol)',
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
                      onTap: _toggleMask,
                      child: Icon(
                        _isMasked ? Icons.visibility_off : Icons.visibility,
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
            _buildHeroCard(),
            const SizedBox(height: 18.0),

            // Behavioral Fast-Action Row
            Row(
              children: [
                Expanded(
                  child: ClayButton(
                    color: ClayColors.tertiaryContainer,
                    borderRadius: BorderRadius.circular(24.0),
                    padding: const EdgeInsets.all(14.0),
                    onTap: _stashImpulse,
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
                                '+${CurrencyFormatter.formatCompactRupiah(_stashedFund)} Stashed',
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
            _buildAccountsCarousel(),
            const SizedBox(height: 24.0),

            // Recent Tactile Ledger Section
            Text(
              'Recent Tactile Ledger',
              style: ClayTypography.headlineSm(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12.0),
            _buildRecentLedger(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    if (_accountsStream == null) {
      return _buildHeroCardLayout(145000);
    }

    return StreamBuilder<List<LocalAccount>>(
      stream: _accountsStream,
      builder: (context, snapshot) {
        int dailyRunway = 145000;
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final totalBalance = snapshot.data!.fold<int>(
            0,
            (sum, acc) =>
                sum +
                (acc.balance.isValidInt
                    ? acc.balance.toInt()
                    : acc.balance.abs().toInt()),
          );
          // Deterministic integer division for daily runway (30 days)
          dailyRunway = totalBalance > 0 ? (totalBalance ~/ 30) : 0;
        }

        return _buildHeroCardLayout(dailyRunway);
      },
    );
  }

  Widget _buildHeroCardLayout(int runwayAmount) {
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
                  'Health Score: 94',
                  style: ClayTypography.labelSm(
                    color: ClayColors.tertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Text(
            CurrencyFormatter.formatMasked(runwayAmount, isMasked: _isMasked),
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
                  '≈ ${CurrencyFormatter.calculateWorkHours(runwayAmount)} working hours',
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

  Widget _buildAccountsCarousel() {
    if (_accountsStream == null) {
      return _buildDefaultAccountsList();
    }

    return StreamBuilder<List<LocalAccount>>(
      stream: _accountsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildDefaultAccountsList();
        }

        final accounts = snapshot.data!;
        return SizedBox(
          height: 145.0,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: accounts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12.0),
            itemBuilder: (context, index) {
              final account = accounts[index];
              final balance = account.balance.isValidInt
                  ? account.balance.toInt()
                  : account.balance.abs().toInt();

              final IconData icon;
              final Color iconColor;
              switch (account.type) {
                case 'BANK':
                  icon = Icons.account_balance;
                  iconColor = ClayColors.primary;
                  break;
                case 'E_WALLET':
                  icon = Icons.account_balance_wallet;
                  iconColor = ClayColors.secondary;
                  break;
                case 'CASH':
                  icon = Icons.payments;
                  iconColor = ClayColors.tertiary;
                  break;
                default:
                  icon = Icons.credit_card;
                  iconColor = ClayColors.primary;
              }

              return _buildAccountCard(account.name, balance, icon, iconColor);
            },
          ),
        );
      },
    );
  }

  Widget _buildDefaultAccountsList() {
    return SizedBox(
      height: 145.0,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          _buildAccountCard(
              'BCA Main', 14820000, Icons.account_balance, ClayColors.primary),
          const SizedBox(width: 12.0),
          _buildAccountCard('Mandiri Payroll', 6350000, Icons.credit_card,
              ClayColors.secondary),
          const SizedBox(width: 12.0),
          _buildAccountCard(
              'Cash Pocket', 480000, Icons.payments, ClayColors.tertiary),
          const SizedBox(width: 12.0),
          _buildAccountCard('GoPay Wallet', 320000,
              Icons.account_balance_wallet, ClayColors.secondary),
        ],
      ),
    );
  }

  Widget _buildRecentLedger() {
    if (_transactionsStream == null) {
      return _buildDefaultLedgerList();
    }

    return StreamBuilder<List<LocalTransaction>>(
      stream: _transactionsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildDefaultLedgerList();
        }

        final transactions = snapshot.data!;
        return Column(
          children: transactions.map((tx) {
            final isExpense = tx.type == 'EXPENSE';
            final int rawAmount = tx.amount.isValidInt
                ? tx.amount.toInt()
                : tx.amount.abs().toInt();
            final int amount = isExpense ? -rawAmount : rawAmount;
            final timeFormatted =
                DateFormat('HH:mm').format(tx.transactionTime);
            final title = tx.note?.isNotEmpty == true
                ? tx.note!
                : (tx.categoryId ?? tx.type);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: _buildLedgerItem(
                title,
                amount,
                timeFormatted,
                tx.accountId,
                isExpense ? Icons.shopping_bag_outlined : Icons.arrow_downward,
                isExpense ? ClayColors.primary : ClayColors.tertiary,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDefaultLedgerList() {
    return Column(
      children: [
        _buildLedgerItem(
          'Kopi Kenangan Senopati',
          -38000,
          '10:42 AM',
          'GoPay',
          Icons.local_cafe,
          ClayColors.primary,
        ),
        const SizedBox(height: 10.0),
        _buildLedgerItem(
          'Freelance UI Sprint',
          3500000,
          'Yesterday',
          'BCA Main',
          Icons.arrow_downward,
          ClayColors.tertiary,
        ),
        const SizedBox(height: 10.0),
        _buildLedgerItem(
          'Makan Malam Sushi Tei',
          -180000,
          'Monday, 19:15',
          'Mandiri',
          Icons.restaurant,
          ClayColors.primary,
        ),
      ],
    );
  }

  Widget _buildAccountCard(
    String title,
    int amount,
    IconData icon,
    Color iconColor,
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
                CurrencyFormatter.formatMasked(amount, isMasked: _isMasked),
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

  Widget _buildLedgerItem(
    String title,
    int amount,
    String time,
    String pocket,
    IconData icon,
    Color color,
  ) {
    final isIncome = amount > 0;
    final prefix = isIncome ? '+' : '';

    return ClayCard(
      borderRadius: BorderRadius.circular(20.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 42.0,
                  height: 42.0,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                  child: Icon(icon, size: 22.0, color: color),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ClayTypography.bodyLg(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '$time • $pocket',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ClayTypography.bodySm(
                          color: ClayColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12.0),
          Text(
            '$prefix${CurrencyFormatter.formatMasked(amount, isMasked: _isMasked)}',
            style: ClayTypography.headlineSm(
              color: isIncome ? ClayColors.tertiary : ClayColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Instant Search Modal Sheet for Overview Tab
class _OverviewSearchSheet extends StatefulWidget {
  const _OverviewSearchSheet();

  @override
  State<_OverviewSearchSheet> createState() => _OverviewSearchSheetState();
}

class _OverviewSearchSheetState extends State<_OverviewSearchSheet> {
  String _query = '';
  SearchFilterEntity _filter = SearchFilterEntity.empty;
  List<LocalTransaction> _results = [];
  bool _isLoading = false;

  Future<void> _performSearch(String query) async {
    setState(() {
      _query = query;
      _isLoading = true;
    });

    if (getIt.isRegistered<AppDatabase>()) {
      final db = getIt<AppDatabase>();
      try {
        final list = query.trim().isEmpty
            ? await db.transactionDao.watchRecentTransactions(limit: 30).first
            : await db.ftsSearchDao.searchTransactions(query, limit: 50);

        if (mounted) {
          setState(() {
            _results = list;
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _performSearch('');
  }

  Future<void> _openFilterModal() async {
    List<LocalAccount> accounts = [];
    List<LocalCategory> categories = [];
    if (getIt.isRegistered<AppDatabase>()) {
      final db = getIt<AppDatabase>();
      accounts = await db.accountDao.getAllActiveAccounts();
      categories = await db.categoryDao.getAllActiveCategories();
    }

    if (!mounted) return;
    final updatedFilter = await SearchFilterBottomSheet.show(
      context,
      initialFilter: _filter,
      accounts: accounts,
      categories: categories,
    );

    if (updatedFilter != null) {
      setState(() => _filter = updatedFilter);
      unawaited(_performSearch(_query));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? ClayColors.surfaceDark : ClayColors.surfaceContainerLowest;
    final subtitleColor = isDark ? ClayColors.onSurfaceVariantDark : ClayColors.outline;
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
                color: isDark ? ClayColors.surfaceContainerDark : ClayColors.surfaceContainerHigh,
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
            onSearchDebounced: _performSearch,
            onFilterTap: _openFilterModal,
          ),
          const SizedBox(height: 14.0),

          // Results Count & Status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _query.isEmpty
                      ? 'Transaksi Terbaru'
                      : 'Hasil Pencarian (${_results.length})',
                  style: ClayTypography.labelMd(color: subtitleColor),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 14.0,
                    height: 14.0,
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8.0),

          // Results List
          Expanded(
            child: _results.isEmpty && !_isLoading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, size: 48.0, color: subtitleColor),
                        const SizedBox(height: 10.0),
                        Text(
                          'Tidak ada transaksi yang cocok',
                          style: ClayTypography.bodyMd(color: subtitleColor),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final tx = _results[index];
                      return SearchResultTile(
                        transaction: tx,
                        highlightQuery: _query,
                        onTap: () {
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
