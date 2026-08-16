import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Holds the secret half of a connection profile (the password/API token).
/// Profile metadata (url, username, "has saved password" flag) lives in
/// Hive instead — see [ConnectionProfileHive] — so the plaintext secret
/// never touches the Hive box on disk.
class SecureCredentialStore {
  final FlutterSecureStorage _storage;

  SecureCredentialStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  String _keyFor(String profileId) => 'tako_profile_password_$profileId';

  Future<void> savePassword(String profileId, String password) {
    return _storage.write(key: _keyFor(profileId), value: password);
  }

  Future<String?> readPassword(String profileId) {
    return _storage.read(key: _keyFor(profileId));
  }

  Future<void> deletePassword(String profileId) {
    return _storage.delete(key: _keyFor(profileId));
  }
}
