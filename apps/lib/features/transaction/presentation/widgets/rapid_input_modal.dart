import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:savoryx/core/database/app_database.dart';
import 'package:savoryx/core/di/injection_container.dart';
import 'package:savoryx/core/theme/clay_colors.dart';
import 'package:savoryx/core/theme/clay_shadows.dart';
import 'package:savoryx/core/theme/clay_typography.dart';
import 'package:savoryx/core/utils/currency_formatter.dart';
import 'package:savoryx/core/utils/math_evaluator.dart';
import 'package:savoryx/core/widgets/clay_button.dart';
import 'package:savoryx/core/widgets/clay_toggle_switch.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';
import 'package:savoryx/features/transaction/domain/usecases/create_transaction_usecase.dart';
import 'package:savoryx/features/transaction/presentation/bloc/transaction_bloc.dart';
import 'package:savoryx/features/transaction/presentation/bloc/transaction_event.dart';
import 'package:savoryx/features/transaction/presentation/widgets/account_chip_selector.dart';
import 'package:savoryx/features/transaction/presentation/widgets/category_selector_grid.dart';
import 'package:savoryx/features/transaction/presentation/widgets/clay_keypad.dart';
import 'package:uuid/uuid.dart';

class RapidInputModal extends StatefulWidget {
  const RapidInputModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const RapidInputModal(),
    );
  }

  @override
  State<RapidInputModal> createState() => _RapidInputModalState();
}

class _RapidInputModalState extends State<RapidInputModal> {
  String _currentRaw = '85000';
  String _selectedCategory = 'Food & Drink';
  String _selectedAccount = 'BCA Checking';
  bool _isTalangan = false;
  static const int _wagePerHour = 65000;

  static const List<String> _defaultCategories = [
    'Food & Drink',
    'Groceries',
    'Transport',
    'Tech Gadget',
    'Bills & Utilities',
  ];

  static const List<String> _defaultAccounts = [
    'BCA Checking',
    'Cash Wallet',
    'GoPay E-Wallet',
    'Mandiri Savings',
  ];

  Stream<List<LocalAccount>>? _accountsStream;
  Stream<List<LocalCategory>>? _categoriesStream;

  @override
  void initState() {
    super.initState();
    if (getIt.isRegistered<AppDatabase>()) {
      final db = getIt<AppDatabase>();
      _accountsStream = db.accountDao.watchAllActiveAccounts();
      _categoriesStream = db.categoryDao.watchAllActiveCategories();
    }
  }

  static const List<int> _acceleratorDenoms = [10000, 50000, 100000, 500000];

  void _onDigitPressed(String digit) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_currentRaw == '0') {
        _currentRaw = digit == '000' ? '0' : digit;
      } else if (_currentRaw.length < 24) {
        _currentRaw += digit;
      }
    });
  }

  void _onOperatorPressed(String op) {
    HapticFeedback.selectionClick();
    setState(() {
      final trimmed = _currentRaw.trim();
      if (trimmed.isEmpty) return;

      if (trimmed.endsWith('+') ||
          trimmed.endsWith('-') ||
          trimmed.endsWith('×') ||
          trimmed.endsWith('÷') ||
          trimmed.endsWith('*') ||
          trimmed.endsWith('/')) {
        _currentRaw = '${trimmed.substring(0, trimmed.length - 1)} $op ';
      } else {
        _currentRaw = '$trimmed $op ';
      }
    });
  }

  void _onAddAccelerator(int add) {
    HapticFeedback.selectionClick();
    setState(() {
      if (MathEvaluator.hasOperator(_currentRaw)) {
        final evaluated = MathEvaluator.evaluate(_currentRaw);
        if (evaluated != null && evaluated.isValidInt) {
          _currentRaw = (evaluated.toInt() + add).toString();
        } else {
          _currentRaw = '$_currentRaw + $add';
        }
      } else {
        final current = int.tryParse(_currentRaw) ?? 0;
        _currentRaw = (current + add).toString();
      }
    });
  }

  void _onBackspace() {
    HapticFeedback.selectionClick();
    setState(() {
      String trimmed = _currentRaw.trimRight();
      if (trimmed.length > 1) {
        if (trimmed.endsWith('+') ||
            trimmed.endsWith('-') ||
            trimmed.endsWith('×') ||
            trimmed.endsWith('÷') ||
            trimmed.endsWith('*') ||
            trimmed.endsWith('/')) {
          trimmed = trimmed.substring(0, trimmed.length - 1).trimRight();
          _currentRaw = trimmed.isEmpty ? '0' : trimmed;
        } else {
          _currentRaw = trimmed.substring(0, trimmed.length - 1);
        }
      } else {
        _currentRaw = '0';
      }
    });
  }

  void _onClear() {
    HapticFeedback.lightImpact();
    setState(() => _currentRaw = '0');
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasOp = MathEvaluator.hasOperator(_currentRaw);
    final BigInt? evaluated =
        hasOp ? MathEvaluator.evaluate(_currentRaw) : null;
    final String? livePreview =
        hasOp ? MathEvaluator.tryFormatLivePreview(_currentRaw) : null;
    final int amount = evaluated?.isValidInt == true
        ? evaluated!.toInt()
        : (int.tryParse(_currentRaw) ?? 0);
    final String workHours =
        CurrencyFormatter.calculateWorkHours(amount, hourlyWage: _wagePerHour);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? ClayColors.surfaceDark : ClayColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)),
        boxShadow: ClayShadows.elevated(isDark: isDark, scale: 1.2),
      ),
      padding: EdgeInsets.only(
        top: 16.0,
        left: 20.0,
        right: 20.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Handle Bar
            Container(
              width: 48.0,
              height: 5.0,
              decoration: BoxDecoration(
                color: isDark
                    ? ClayColors.surfaceContainerDarkHigh
                    : ClayColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 16.0),

            // Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Log Transaction',
                  style: ClayTypography.headlineSm(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                ClayButton(
                  width: 36.0,
                  height: 36.0,
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(18.0),
                  semanticLabel: 'Tutup formulir transaksi',
                  minTouchTarget: true,
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close,
                    size: 18.0,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14.0),

            // Category Horizontal Selector
            StreamBuilder<List<LocalCategory>>(
              stream: _categoriesStream,
              builder: (context, snapshot) {
                final List<String> categories;
                final Map<String, bool> isWantsMap = {};
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  categories = snapshot.data!.map((c) => c.name).toList();
                  for (final c in snapshot.data!) {
                    isWantsMap[c.name] = c.isWants;
                  }
                } else {
                  categories = _defaultCategories;
                }

                final currentSelected = categories.contains(_selectedCategory)
                    ? _selectedCategory
                    : categories.first;

                return CategorySelectorGrid(
                  categories: categories,
                  selectedCategory: currentSelected,
                  isWantsMap: isWantsMap.isNotEmpty ? isWantsMap : null,
                  onCategorySelected: (cat) =>
                      setState(() => _selectedCategory = cat),
                );
              },
            ),
            const SizedBox(height: 10.0),

            // Source Account Horizontal Selector
            StreamBuilder<List<LocalAccount>>(
              stream: _accountsStream,
              builder: (context, snapshot) {
                final List<String> accounts;
                final Map<String, String> balances = {};
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  accounts = snapshot.data!.map((a) => a.name).toList();
                  for (final a in snapshot.data!) {
                    final bal = a.balance.isValidInt
                        ? a.balance.toInt()
                        : a.balance.abs().toInt();
                    balances[a.name] = CurrencyFormatter.formatCompactRupiah(
                      bal,
                      prefix: 'Rp ',
                    );
                  }
                } else {
                  accounts = _defaultAccounts;
                }

                final currentSelected = accounts.contains(_selectedAccount)
                    ? _selectedAccount
                    : accounts.first;

                return AccountChipSelector(
                  accounts: accounts,
                  selectedAccount: currentSelected,
                  accountBalances: balances.isNotEmpty ? balances : null,
                  onAccountSelected: (acc) =>
                      setState(() => _selectedAccount = acc),
                );
              },
            ),
            const SizedBox(height: 14.0),

            // Giant Value Display Deck with Live Math Preview
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: isDark
                    ? ClayColors.surfaceContainerDarkLow
                    : ClayColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: ClayShadows.elevated(isDark: isDark, scale: 0.8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      if (!hasOp)
                        Text(
                          'Rp ',
                          style: ClayTypography.headlineMd(
                            color: ClayColors.onSurfaceVariant,
                          ),
                        ),
                      Flexible(
                        child: Text(
                          hasOp
                              ? _currentRaw
                              : CurrencyFormatter.formatMinorUnit(amount)
                                  .replaceAll('Rp', '')
                                  .trim(),
                          key: const Key('amount_display_text'),
                          textAlign: TextAlign.center,
                          style: hasOp
                              ? ClayTypography.headlineLg(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                )
                              : ClayTypography.headlineXl(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                        ),
                      ),
                    ],
                  ),
                  if (livePreview != null) ...[
                    const SizedBox(height: 4.0),
                    Text(
                      '= $livePreview',
                      key: const Key('live_preview_text'),
                      style: ClayTypography.headlineSm(
                        color: ClayColors.secondaryDeep,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8.0),
                  // Time-cost equivalence pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: ClayColors.secondaryContainer.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(16.0),
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
                          '≈ $workHours Working Hours at Rp 65k/hr',
                          style: ClayTypography.labelSm(
                            color: ClayColors.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14.0),

            // Tactile 4x4 Clay Keypad with Accelerator Chips
            ClayKeypad(
              onDigitPressed: _onDigitPressed,
              onOperatorPressed: _onOperatorPressed,
              onClear: _onClear,
              onBackspace: _onBackspace,
              onAcceleratorPressed: _onAddAccelerator,
              acceleratorDenoms: _acceleratorDenoms,
            ),
            const SizedBox(height: 14.0),

            // Talangan Toggle Card
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: isDark
                    ? ClayColors.surfaceContainerDarkLow
                    : ClayColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32.0,
                        height: 32.0,
                        decoration: const BoxDecoration(
                          color: ClayColors.secondaryFixed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.group,
                          size: 18.0,
                          color: ClayColors.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Text(
                        'Mark as Talangan',
                        style: ClayTypography.labelLg(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  ClayToggleSwitch(
                    value: _isTalangan,
                    onChanged: (val) => setState(() => _isTalangan = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            // Submit Button
            ClayButton(
              key: const Key('log_expense_submit_button'),
              isPrimaryCta: true,
              semanticLabel: 'Simpan transaksi pengeluaran',
              semanticHint: 'Menyimpan catatan transaksi ke database lokal',
              minTouchTarget: true,
              onTap: () async {
                await HapticFeedback.mediumImpact();
                final txId = const Uuid().v7();
                final now = DateTime.now().toUtc();

                String targetAccountId = 'acc-bca-001';
                String? targetCategoryId;

                if (getIt.isRegistered<AppDatabase>()) {
                  final db = getIt<AppDatabase>();
                  try {
                    final accounts = await db.accountDao.getAllActiveAccounts();
                    final matchedAcc = accounts.where((a) =>
                        a.name.toLowerCase() ==
                            _selectedAccount.toLowerCase() ||
                        a.name.toLowerCase().contains(
                            _selectedAccount.split(' ').first.toLowerCase()));
                    if (matchedAcc.isNotEmpty) {
                      targetAccountId = matchedAcc.first.id;
                    } else if (accounts.isNotEmpty) {
                      targetAccountId = accounts.first.id;
                    }

                    final categories =
                        await db.categoryDao.getAllActiveCategories();
                    final matchedCat = categories.where((c) =>
                        c.name.toLowerCase() ==
                        _selectedCategory.toLowerCase());
                    if (matchedCat.isNotEmpty) {
                      targetCategoryId = matchedCat.first.id;
                    }
                  } catch (_) {}
                }

                final entity = TransactionEntity(
                  id: txId,
                  accountId: targetAccountId,
                  categoryId: targetCategoryId ?? _selectedCategory,
                  amount: amount > 0 ? amount : 1000,
                  type: TransactionType.expense,
                  note: _isTalangan
                      ? 'Talangan: $_selectedCategory'
                      : _selectedCategory,
                  transactionDate: now,
                  createdAt: now,
                  updatedAt: now,
                );

                try {
                  if (getIt.isRegistered<TransactionBloc>()) {
                    getIt<TransactionBloc>().add(TransactionSubmitted(entity));
                  } else if (getIt.isRegistered<CreateTransactionUseCase>()) {
                    await getIt<CreateTransactionUseCase>()(entity);
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Logged: ${CurrencyFormatter.formatMinorUnit(amount)} ($_selectedCategory / $_selectedAccount)',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal menyimpan transaksi: $e'),
                        backgroundColor: ClayColors.error,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              child: Center(
                child: Text(
                  'Log Expense (${CurrencyFormatter.formatMinorUnit(amount)})',
                  style: ClayTypography.headlineSm(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
