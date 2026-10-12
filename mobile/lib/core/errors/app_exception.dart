class AppException implements Exception {
  const AppException({
    required this.code,
    required this.message,
    this.statusCode,
    this.correlationId,
  });

  final String code;
  final String message;
  final int? statusCode;
  final String? correlationId;

  @override
  String toString() => 'AppException($code): $message';
}
