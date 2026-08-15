/// Thrown when the Kanboard server returns a JSON-RPC `error` object,
/// e.g. invalid params, unknown method, or application-level failures.
class KanboardApiException implements Exception {
  final int code;
  final String message;
  final Object? data;

  KanboardApiException({required this.code, required this.message, this.data});

  factory KanboardApiException.fromJson(Map<String, dynamic> error) {
    return KanboardApiException(
      code: int.tryParse(error['code']?.toString() ?? '') ?? 0,
      message: error['message']?.toString() ?? 'Unknown JSON-RPC error',
      data: error['data'],
    );
  }

  @override
  String toString() =>
      'KanboardApiException($code): $message${data != null ? ' (data: $data)' : ''}';
}

/// Thrown for transport-level failures: non-200 HTTP status, network errors,
/// or auth failures (401/403) before a JSON-RPC envelope was even parsed.
class KanboardHttpException implements Exception {
  final int? statusCode;
  final String message;

  KanboardHttpException({this.statusCode, required this.message});

  @override
  String toString() =>
      'KanboardHttpException${statusCode != null ? '($statusCode)' : ''}: $message';
}
