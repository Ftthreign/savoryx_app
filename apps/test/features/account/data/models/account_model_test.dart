import 'package:flutter_test/flutter_test.dart';
import 'package:savoryx/features/account/data/models/account_model.dart';
import 'package:savoryx/features/account/domain/entities/account_entity.dart';

void main() {
  group('AccountModel & AccountEntity Tests', () {
    final now = DateTime.utc(2026, 10, 30, 12, 0, 0);

    final tAccountModel = AccountModel(
      id: '0192d6bb-0b5c-7d31-9f23-8cfcf650b2aa',
      name: 'BCA Main Account',
      type: AccountType.bank,
      currency: 'IDR',
      balance: 14820000,
      createdAt: now,
      updatedAt: now,
    );

    test('AccountEntity copyWith and value equality works deterministically', () {
      final updated = tAccountModel.copyWith(name: 'BCA Payroll');
      expect(updated.name, 'BCA Payroll');
      expect(updated.balance, 14820000);
      expect(updated.isDeleted, isFalse);

      final identicalCopy = tAccountModel.copyWith();
      expect(identicalCopy, equals(tAccountModel));
      expect(identicalCopy.hashCode, equals(tAccountModel.hashCode));
    });

    test('AccountModel.fromJson deserializes integer balance and ISO timestamps', () {
      final jsonMap = <String, dynamic>{
        'id': '0192d6bb-0b5c-7d31-9f23-8cfcf650b2aa',
        'name': 'BCA Main Account',
        'type': 'BANK',
        'currency': 'IDR',
        'balance': 14820000,
        'created_at': '2026-10-30T12:00:00.000Z',
        'updated_at': '2026-10-30T12:00:00.000Z',
        'deleted_at': null,
      };

      final result = AccountModel.fromJson(jsonMap);
      expect(result.id, '0192d6bb-0b5c-7d31-9f23-8cfcf650b2aa');
      expect(result.name, 'BCA Main Account');
      expect(result.type, AccountType.bank);
      expect(result.balance, 14820000);
      expect(result.createdAt, now);
      expect(result.deletedAt, isNull);
      expect(result.isDeleted, isFalse);
    });

    test('AccountModel.fromJson handles string Decimal from Go PostgreSQL safely', () {
      final jsonMap = <String, dynamic>{
        'id': '0192d6bb-0b5c-7d31-9f23-8cfcf650b2aa',
        'name': 'Cash Pocket',
        'type': 'CASH',
        'currency': 'IDR',
        'balance': '450000.00',
        'created_at': '2026-10-30T12:00:00.000Z',
        'updated_at': '2026-10-30T12:00:00.000Z',
      };

      final result = AccountModel.fromJson(jsonMap);
      expect(result.balance, 450000);
      expect(result.type, AccountType.cash);
    });

    test('AccountModel.toJson outputs contract-compliant JSON payload', () {
      final json = tAccountModel.toJson();

      expect(json['id'], '0192d6bb-0b5c-7d31-9f23-8cfcf650b2aa');
      expect(json['name'], 'BCA Main Account');
      expect(json['type'], 'BANK');
      expect(json['currency'], 'IDR');
      expect(json['balance'], 14820000);
      expect(json['created_at'], '2026-10-30T12:00:00.000Z');
      expect(json.containsKey('deleted_at'), isFalse);
    });
  });
}
