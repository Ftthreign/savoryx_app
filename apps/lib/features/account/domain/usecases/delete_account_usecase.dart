import 'package:injectable/injectable.dart';
import 'package:savoryx/features/account/domain/repositories/account_repository.dart';

@lazySingleton
class DeleteAccountUseCase {
  final AccountRepository _repository;

  const DeleteAccountUseCase(this._repository);

  Future<void> call(String id) {
    if (id.trim().isEmpty) {
      throw ArgumentError('Account ID cannot be empty');
    }
    return _repository.deleteAccount(id);
  }
}
