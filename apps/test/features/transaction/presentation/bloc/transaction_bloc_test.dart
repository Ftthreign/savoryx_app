import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';
import 'package:savoryx/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:savoryx/features/transaction/domain/usecases/create_transaction_usecase.dart';
import 'package:savoryx/features/transaction/domain/usecases/delete_transaction_usecase.dart';
import 'package:savoryx/features/transaction/domain/usecases/watch_recent_transactions_usecase.dart';
import 'package:savoryx/features/transaction/presentation/bloc/transaction_bloc.dart';
import 'package:savoryx/features/transaction/presentation/bloc/transaction_event.dart';
import 'package:savoryx/features/transaction/presentation/bloc/transaction_state.dart';

class FakeTransactionRepository implements TransactionRepository {
  final List<TransactionEntity> transactions = [];
  final StreamController<List<TransactionEntity>> _streamController =
      StreamController<List<TransactionEntity>>.broadcast();

  bool shouldThrowOnCreate = false;
  bool shouldThrowOnDelete = false;

  @override
  Future<void> createTransaction(TransactionEntity transaction) async {
    if (shouldThrowOnCreate) {
      throw Exception('Database write failure');
    }
    transactions.add(transaction);
    _streamController.add(List.unmodifiable(transactions));
  }

  @override
  Stream<List<TransactionEntity>> watchRecentTransactions({int limit = 50}) {
    return _streamController.stream;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    if (shouldThrowOnDelete) {
      throw StateError('Cannot delete transaction');
    }
    transactions.removeWhere((t) => t.id == id);
    _streamController.add(List.unmodifiable(transactions));
  }

  @override
  Future<TransactionEntity?> getTransactionById(String id) async {
    return transactions.cast<TransactionEntity?>().firstWhere(
          (t) => t?.id == id,
          orElse: () => null,
        );
  }

  void emit(List<TransactionEntity> list) {
    _streamController.add(list);
  }

  void emitError(Object error) {
    _streamController.addError(error);
  }

  void dispose() {
    _streamController.close();
  }
}

void main() {
  group('TransactionBloc Tests (Feature-First Clean Architecture)', () {
    late FakeTransactionRepository fakeRepository;
    late CreateTransactionUseCase createTransactionUseCase;
    late WatchRecentTransactionsUseCase watchRecentTransactionsUseCase;
    late DeleteTransactionUseCase deleteTransactionUseCase;

    final dummyTx = TransactionEntity(
      id: '0192e4a1-0000-7000-8000-000000000001',
      accountId: 'acc-bca-001',
      categoryId: 'cat-food-001',
      amount: 85000,
      type: TransactionType.expense,
      note: 'Lunch at Cafe',
      transactionDate: DateTime.parse('2026-11-01T12:00:00Z'),
      createdAt: DateTime.parse('2026-11-01T12:00:00Z'),
      updatedAt: DateTime.parse('2026-11-01T12:00:00Z'),
    );

    setUp(() {
      fakeRepository = FakeTransactionRepository();
      createTransactionUseCase = CreateTransactionUseCase(fakeRepository);
      watchRecentTransactionsUseCase = WatchRecentTransactionsUseCase(fakeRepository);
      deleteTransactionUseCase = DeleteTransactionUseCase(fakeRepository);
    });

    tearDown(() {
      fakeRepository.dispose();
    });

    TransactionBloc buildBloc() {
      return TransactionBloc(
        createTransactionUseCase: createTransactionUseCase,
        watchRecentTransactionsUseCase: watchRecentTransactionsUseCase,
        deleteTransactionUseCase: deleteTransactionUseCase,
      );
    }

    test('initial state is TransactionInitial', () {
      expect(buildBloc().state, equals(const TransactionInitial()));
    });

    blocTest<TransactionBloc, TransactionState>(
      'emits [TransactionLoading, TransactionLoaded] when stream receives updated transactions',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const WatchTransactionsStarted());
        await pumpEventQueue();
        fakeRepository.emit([dummyTx]);
      },
      expect: () => [
        const TransactionLoading(),
        TransactionLoaded(transactions: [dummyTx]),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits [TransactionLoading, TransactionFailure] when watch stream throws error',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const WatchTransactionsStarted());
        await pumpEventQueue();
        fakeRepository.emitError(Exception('Database stream disconnected'));
      },
      expect: () => [
        const TransactionLoading(),
        isA<TransactionFailure>().having(
          (s) => s.message,
          'message',
          contains('Database stream disconnected'),
        ),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits [TransactionLoading, TransactionSuccess] when transaction is submitted successfully',
      build: buildBloc,
      act: (bloc) => bloc.add(TransactionSubmitted(dummyTx)),
      expect: () => [
        const TransactionLoading(),
        const TransactionSuccess(message: 'Transaction saved successfully'),
      ],
      verify: (_) {
        expect(fakeRepository.transactions.length, equals(1));
        expect(fakeRepository.transactions.first.amount, equals(85000));
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits [TransactionLoading, TransactionFailure] when validation fails (amount <= 0)',
      build: buildBloc,
      act: (bloc) => bloc.add(
        TransactionSubmitted(
          dummyTx.copyWith(amount: 0),
        ),
      ),
      expect: () => [
        const TransactionLoading(),
        isA<TransactionFailure>().having(
          (s) => s.message,
          'message',
          contains('greater than zero'),
        ),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits [TransactionLoading, TransactionFailure] when repository throws error on submit',
      build: () {
        fakeRepository.shouldThrowOnCreate = true;
        return buildBloc();
      },
      act: (bloc) => bloc.add(TransactionSubmitted(dummyTx)),
      expect: () => [
        const TransactionLoading(),
        isA<TransactionFailure>().having(
          (s) => s.message,
          'message',
          contains('Database write failure'),
        ),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits [TransactionLoading, TransactionSuccess] when transaction is deleted successfully',
      build: () {
        fakeRepository.transactions.add(dummyTx);
        return buildBloc();
      },
      act: (bloc) => bloc.add(TransactionDeleted(dummyTx.id)),
      expect: () => [
        const TransactionLoading(),
        const TransactionSuccess(message: 'Transaction deleted successfully'),
      ],
      verify: (_) {
        expect(fakeRepository.transactions, isEmpty);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits [TransactionLoading, TransactionFailure] when deleting non-existent ID fails',
      build: () {
        fakeRepository.shouldThrowOnDelete = true;
        return buildBloc();
      },
      act: (bloc) => bloc.add(const TransactionDeleted('invalid-id')),
      expect: () => [
        const TransactionLoading(),
        isA<TransactionFailure>().having(
          (s) => s.message,
          'message',
          contains('Cannot delete transaction'),
        ),
      ],
    );
  });
}
