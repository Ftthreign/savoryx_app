import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  List<Object?> get props => [message, code];
}

final class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.code = 'DATABASE_ERROR'});
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code = 'SERVER_ERROR'});
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code = 'VALIDATION_ERROR'});
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(
      [super.message = 'An unexpected failure occurred.', String? code])
      : super(code: code ?? 'UNEXPECTED_ERROR');
}
