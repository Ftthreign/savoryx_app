import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/features/transaction/data/models/transaction_model.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';

void main() {
  group('TransactionModel & TransactionEntity Tests', () {
    final now = DateTime.utc(2026, 10, 30, 10, 42, 0);

    final tTxModel = TransactionModel(
      id: '0192d6bb-0b5c-7d31-9f23-8cfcf650b2cc',
      accountId: '0192d6bb-0b5c-7d31-9f23-8cfcf650b2aa',
      categoryId: '0192d6bb-0b5c-7d31-9f23-8cfcf650b2bb',
      amount: 38000,
      type: TransactionType.expense,
      note: 'Kopi Kenangan Senopati',
      transactionDate: now,
      isSynced: false,
      createdAt: now,
      updatedAt: now,
    );

    test(
        'TransactionEntity copyWith and value equality works deterministically',
        () {
      final updated = tTxModel.copyWith(amount: 45000, isSynced: true);
      expect(updated.amount, 45000);
      expect(updated.isSynced, isTrue);
      expect(updated.note, 'Kopi Kenangan Senopati');

      final identicalCopy = tTxModel.copyWith();
      expect(identicalCopy, equals(tTxModel));
      expect(identicalCopy.hashCode, equals(tTxModel.hashCode));
    });

    test('TransactionModel.fromJson deserializes integer amount and ISO dates',
        () {
      final jsonMap = <String, dynamic>{
        'id': '0192d6bb-0b5c-7d31-9f23-8cfcf650b2cc',
        'account_id': '0192d6bb-0b5c-7d31-9f23-8cfcf650b2aa',
        'category_id': '0192d6bb-0b5c-7d31-9f23-8cfcf650b2bb',
        'amount': 38000,
        'type': 'EXPENSE',
        'note': 'Kopi Kenangan Senopati',
        'transaction_date': '2026-10-30T10:42:00.000Z',
        'is_synced': false,
        'created_at': '2026-10-30T10:42:00.000Z',
        'updated_at': '2026-10-30T10:42:00.000Z',
        'deleted_at': null,
      };

      final result = TransactionModel.fromJson(jsonMap);
      expect(result.id, '0192d6bb-0b5c-7d31-9f23-8cfcf650b2cc');
      expect(result.amount, 38000);
      expect(result.type, TransactionType.expense);
      expect(result.note, 'Kopi Kenangan Senopati');
      expect(result.isSynced, isFalse);
      expect(result.transactionDate, now);
      expect(result.deletedAt, isNull);
    });

    test(
        'TransactionModel.fromJson parses string amounts without precision loss',
        () {
      final jsonMap = <String, dynamic>{
        'id': '0192d6bb-0b5c-7d31-9f23-8cfcf650b2cc',
        'account_id': '0192d6bb-0b5c-7d31-9f23-8cfcf650b2aa',
        'amount': '3500000',
        'type': 'INCOME',
        'note': 'Freelance Sprint',
        'created_at': '2026-10-30T10:42:00.000Z',
      };

      final result = TransactionModel.fromJson(jsonMap);
      expect(result.amount, 3500000);
      expect(result.type, TransactionType.income);
    });

    test('TransactionModel.toJson outputs contract-compliant JSON payload', () {
      final json = tTxModel.toJson();

      expect(json['id'], '0192d6bb-0b5c-7d31-9f23-8cfcf650b2cc');
      expect(json['account_id'], '0192d6bb-0b5c-7d31-9f23-8cfcf650b2aa');
      expect(json['category_id'], '0192d6bb-0b5c-7d31-9f23-8cfcf650b2bb');
      expect(json['amount'], 38000);
      expect(json['type'], 'EXPENSE');
      expect(json['note'], 'Kopi Kenangan Senopati');
      expect(json['transaction_date'], '2026-10-30T10:42:00.000Z');
      expect(json['is_synced'], isFalse);
      expect(json.containsKey('destination_account_id'), isFalse);
      expect(json.containsKey('deleted_at'), isFalse);
    });

    test(
        'parseTransactionsJsonList and computeFromRawJson parses batch JSON arrays',
        () async {
      final rawList = [
        tTxModel.toJson(),
        tTxModel
            .copyWith(
                id: '0192d6bb-0b5c-7d31-9f23-8cfcf650b2cd', amount: 150000)
            .toJson(),
      ];
      final rawJson = jsonEncode(rawList);

      final synchronousResult = parseTransactionsJsonList(rawJson);
      expect(synchronousResult.length, 2);
      expect(synchronousResult[0].id, tTxModel.id);
      expect(synchronousResult[1].amount, 150000);

      // Verify background compute execution
      final asyncResult = await TransactionModel.computeFromRawJson(rawJson);
      expect(asyncResult.length, 2);
      expect(asyncResult[0].id, tTxModel.id);
      expect(asyncResult[1].amount, 150000);
    });
  });
}
