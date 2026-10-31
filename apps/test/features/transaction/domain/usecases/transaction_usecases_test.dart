import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/features/transaction/data/datasources/transaction_local_datasource.dart';
import 'package:savoryx/features/transaction/data/repositories/transaction_repository_impl.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';
import 'package:savoryx/features/transaction/domain/usecases/create_transaction_usecase.dart';
import 'package:savoryx/features/transaction/domain/usecases/delete_transaction_usecase.dart';
import 'package:savoryx/features/transaction/domain/usecases/watch_recent_transactions_usecase.dart';

class FakeTransactionLocalDataSource implements TransactionLocalDataSource {
  final List<TransactionEntity> items = [];

  @override
  Future<void> createTransaction(TransactionEntity transaction) async {
    items.add(transaction);
  }

  @override
  Stream<List<TransactionEntity>> watchRecentTransactions({int limit = 50}) {
    return Stream.value(List.unmodifiable(items));
  }

  @override
  Future<void> deleteTransaction(String id) async {
    items.removeWhere((item) => item.id == id);
  }

  @override
  Future<TransactionEntity?> getTransactionById(String id) async {
    return items.cast<TransactionEntity?>().firstWhere(
          (t) => t?.id == id,
          orElse: () => null,
        );
  }
}

void main() {
  group('Transaction Domain Use Cases & Repository Tests', () {
    late FakeTransactionLocalDataSource fakeDataSource;
    late TransactionRepositoryImpl repository;
    late CreateTransactionUseCase createUseCase;
    late WatchRecentTransactionsUseCase watchUseCase;
    late DeleteTransactionUseCase deleteUseCase;

    final sampleTx = TransactionEntity(
      id: 'tx-001',
      accountId: 'acc-001',
      categoryId: 'cat-001',
      amount: 45000,
      type: TransactionType.expense,
      note: 'Coffee',
      transactionDate: DateTime.parse('2026-11-01T08:00:00Z'),
      createdAt: DateTime.parse('2026-11-01T08:00:00Z'),
      updatedAt: DateTime.parse('2026-11-01T08:00:00Z'),
    );

    setUp(() {
      fakeDataSource = FakeTransactionLocalDataSource();
      repository = TransactionRepositoryImpl(fakeDataSource);
      createUseCase = CreateTransactionUseCase(repository);
      watchUseCase = WatchRecentTransactionsUseCase(repository);
      deleteUseCase = DeleteTransactionUseCase(repository);
    });

    test('CreateTransactionUseCase validates positive amount', () async {
      // Valid amount succeeds
      await createUseCase(sampleTx);
      expect(fakeDataSource.items.length, equals(1));

      // Amount <= 0 throws ArgumentError
      expect(
        () => createUseCase(sampleTx.copyWith(amount: 0)),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => createUseCase(sampleTx.copyWith(amount: -5000)),
        throwsA(isA<ArgumentError>()),
      );

      // Empty account ID throws ArgumentError
      expect(
        () => createUseCase(sampleTx.copyWith(accountId: '')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('WatchRecentTransactionsUseCase streams items through repository', () async {
      await repository.createTransaction(sampleTx);

      final stream = watchUseCase(limit: 10);
      expect(stream, emits(contains(sampleTx)));
    });

    test('DeleteTransactionUseCase validates non-empty ID and deletes item', () async {
      await repository.createTransaction(sampleTx);
      expect(fakeDataSource.items.length, equals(1));

      await deleteUseCase(sampleTx.id);
      expect(fakeDataSource.items, isEmpty);

      // Empty ID throws ArgumentError
      expect(
        () => deleteUseCase(''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('TransactionRepositoryImpl getTransactionById returns matching entity', () async {
      await repository.createTransaction(sampleTx);

      final found = await repository.getTransactionById(sampleTx.id);
      expect(found, isNotNull);
      expect(found!.id, equals(sampleTx.id));

      final notFound = await repository.getTransactionById('non-existent');
      expect(notFound, isNull);
    });
  });
}
