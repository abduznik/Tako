import 'dart:convert';
import 'dart:io';

/// Persists which (taskId, type, dueDate) alerts have already fired, so a
/// restarted app doesn't re-notify for deadlines it already alerted on.
///
/// Backed by a flat JSON file. Kept deliberately simple (no sqlite) since
/// the data is just a set of dedupe keys with timestamps — swap the storage
/// backend later if this needs to scale.
class AlertStore {
  final File _file;
  final Map<String, DateTime> _alerted = {};
  bool _loaded = false;

  AlertStore(String path) : _file = File(path);

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    if (!await _file.exists()) return;
    try {
      final raw = await _file.readAsString();
      if (raw.trim().isEmpty) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      for (final entry in decoded.entries) {
        final parsed = DateTime.tryParse(entry.value.toString());
        if (parsed != null) _alerted[entry.key] = parsed;
      }
    } catch (_) {
      // Corrupt or unreadable alert history shouldn't crash the watchdog —
      // treat it as empty and let it be overwritten on the next save.
    }
  }

  bool hasFired(String key) => _alerted.containsKey(key);

  Future<void> markFired(String key, DateTime firedAt) async {
    _alerted[key] = firedAt;
    await _save();
  }

  Future<void> _save() async {
    final serializable = _alerted.map(
      (key, value) => MapEntry(key, value.toIso8601String()),
    );
    await _file.parent.create(recursive: true);
    await _file.writeAsString(jsonEncode(serializable));
  }
}
