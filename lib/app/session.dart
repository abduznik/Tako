import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../notifications/alert_store.dart';
import '../notifications/notification_event.dart';
import '../notifications/watchdog_service.dart';
import '../providers/kanboard_provider.dart';
import '../providers/local_provider.dart';
import '../providers/provider_exceptions.dart';
import '../providers/task_provider.dart';
import '../storage/app_storage.dart';
import '../storage/hive_models.dart';
import '../storage/secure_credential_store.dart';

enum SessionStatus { loading, ready }

/// App-wide session state: which [TaskProvider] is active (or standalone),
/// the connection profile behind it, and whether we're showing an "offline"
/// banner because a saved profile couldn't be reached at startup.
///
/// Also owns the [WatchdogService] that polls for deadline notifications
/// while the app is open, restarting it against whichever provider is
/// currently active.
///
/// Screens consume this via [Provider]/[Consumer] rather than talking to
/// storage or KanboardClient/LocalProvider directly.
class Session extends ChangeNotifier {
  static const _uuid = Uuid();

  final SecureCredentialStore _credentialStore;

  Session({SecureCredentialStore? credentialStore})
      : _credentialStore = credentialStore ?? SecureCredentialStore();

  SessionStatus status = SessionStatus.loading;

  TaskProvider _provider = LocalProvider();
  TaskProvider get provider => _provider;

  ConnectionProfileHive? activeProfile;

  bool get isStandalone => activeProfile == null;

  /// Set when a saved "remember me" profile exists but couldn't be reached
  /// at startup — the UI falls through to standalone mode with this banner
  /// rather than blocking the user.
  String? offlineBannerMessage;

  WatchdogService? _watchdog;

  /// Notifications fired since the app opened, newest first — backs the
  /// dashboard's notification bell.
  final List<NotificationEvent> notifications = [];

  int get unreadNotificationCount => notifications.length;

  /// Runs at app start: attempts silent login against a remembered profile,
  /// otherwise leaves the session in standalone mode.
  Future<void> bootstrap() async {
    final lastProfileId = AppStorage.lastActiveProfileId;
    if (lastProfileId != null) {
      final profile = AppStorage.profiles.get(lastProfileId);
      if (profile != null && profile.rememberMe && profile.hasSavedPassword) {
        final connected = await _trySilentLogin(profile);
        if (connected) {
          status = SessionStatus.ready;
          _restartWatchdog();
          notifyListeners();
          return;
        }
        offlineBannerMessage = "Working offline — couldn't reach ${profile.name}";
      }
    }

    _provider = LocalProvider();
    activeProfile = null;
    status = SessionStatus.ready;
    _restartWatchdog();
    notifyListeners();
  }

  Future<bool> _trySilentLogin(ConnectionProfileHive profile) async {
    final password = await _credentialStore.readPassword(profile.id);
    if (password == null) return false;

    final candidate = KanboardProvider(
      baseUrl: profile.baseUrl,
      username: profile.username,
      password: password,
      profileName: profile.name,
    );
    try {
      await candidate.verifyConnection();
    } catch (_) {
      candidate.dispose();
      return false;
    }

    _provider.dispose();
    _provider = candidate;
    activeProfile = profile;
    return true;
  }

  /// Verifies credentials against Kanboard and, on success, connects and
  /// optionally saves the profile. Throws [ProviderAuthException] /
  /// [ProviderConnectionException] on failure — callers should catch and
  /// display the message, not save anything.
  Future<void> connectToKanboard({
    required String name,
    required String baseUrl,
    required String username,
    required String password,
    required bool rememberMe,
  }) async {
    final candidate = KanboardProvider(
      baseUrl: baseUrl,
      username: username,
      password: password,
      profileName: name,
    );

    // Verify before persisting anything, so bad credentials are never saved.
    await candidate.verifyConnection();

    final profileId = _uuid.v4();
    final profile = ConnectionProfileHive(
      id: profileId,
      name: name,
      baseUrl: baseUrl,
      username: username,
      rememberMe: rememberMe,
      hasSavedPassword: rememberMe,
    );
    await AppStorage.profiles.put(profileId, profile);

    if (rememberMe) {
      await _credentialStore.savePassword(profileId, password);
      await AppStorage.setLastActiveProfileId(profileId);
    }

    _provider.dispose();
    _provider = candidate;
    activeProfile = profile;
    offlineBannerMessage = null;
    _restartWatchdog();
    notifyListeners();
  }

  Future<void> continueStandalone() async {
    _provider.dispose();
    _provider = LocalProvider();
    activeProfile = null;
    offlineBannerMessage = null;
    _restartWatchdog();
    notifyListeners();
  }

  Future<void> logOut() async {
    final profile = activeProfile;
    if (profile != null) {
      await _credentialStore.deletePassword(profile.id);
      if (AppStorage.lastActiveProfileId == profile.id) {
        await AppStorage.setLastActiveProfileId(null);
      }
    }
    _provider.dispose();
    _provider = LocalProvider();
    activeProfile = null;
    offlineBannerMessage = null;
    _restartWatchdog();
    notifyListeners();
  }

  void dismissOfflineBanner() {
    offlineBannerMessage = null;
    notifyListeners();
  }

  void _restartWatchdog() {
    _watchdog?.stop();
    final alertStore = AlertStore('.tako/alert_history.json');
    _watchdog = WatchdogService(
      provider: _provider,
      alertStore: alertStore,
      onEvent: (event) {
        notifications.insert(0, event);
        notifyListeners();
      },
      onError: (_) {
        // Poll failures are transient (offline, server hiccup); the
        // watchdog itself already retries next interval, so there's
        // nothing actionable to surface to the user here.
      },
    );
    _watchdog!.start();
  }

  void clearNotifications() {
    notifications.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _watchdog?.stop();
    super.dispose();
  }
}
