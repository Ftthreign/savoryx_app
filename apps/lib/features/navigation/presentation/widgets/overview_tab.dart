import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/core/di/injection_container.dart';
import 'package:savoryx/core/theme/clay_colors.dart';
import 'package:savoryx/core/theme/clay_typography.dart';
import 'package:savoryx/core/utils/constants.dart';
import 'package:savoryx/core/utils/currency_formatter.dart';
import 'package:savoryx/core/widgets/clay_button.dart';
import 'package:savoryx/core/widgets/clay_card.dart';

class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  bool _isMasked = false;
  int _stashedFund = 45000;

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
                    ClayButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                      borderRadius: BorderRadius.circular(18.0),
                      onTap: () {},
                      child: Text(
                        'IDR (Rp)',
                        style: ClayTypography.labelMd(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    ClayButton(
                      width: 40.0,
                      height: 40.0,
                      padding: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(20.0),
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
