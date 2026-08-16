/// Generic errors surfaced by any [TaskProvider] implementation. UI code
/// depends only on these, never on a specific backend's exception types
/// (e.g. Kanboard's KanboardApiException), so new providers slot in without
/// touching error-handling call sites.
class ProviderAuthException implements Exception {
  final String message;
  ProviderAuthException(this.message);

  @override
  String toString() => message;
}

class ProviderConnectionException implements Exception {
  final String message;
  ProviderConnectionException(this.message);

  @override
  String toString() => message;
}

class ProviderException implements Exception {
  final String message;
  ProviderException(this.message);

  @override
  String toString() => message;
}
