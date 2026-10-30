class ServerException implements Exception {
  final String message;
  final String? code;

  const ServerException(this.message, {this.code});

  @override
  String toString() => 'ServerException: $message (code: $code)';
}

class DatabaseException implements Exception {
  final String message;
  final String? code;

  const DatabaseException(this.message, {this.code});

  @override
  String toString() => 'DatabaseException: $message (code: $code)';
}

class ValidationException implements Exception {
  final String message;

  const ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}
