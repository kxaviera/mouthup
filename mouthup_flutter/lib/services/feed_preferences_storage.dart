import 'package:shared_preferences/shared_preferences.dart';

class FeedPreferencesStorage {
  static const _comfortKey = 'feed_comfort_mode';
  static const _comfortUntilKey = 'feed_comfort_until';
  static const _shieldsKey = 'feed_topic_shields';

  Future<bool> getComfortFeedEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final until = prefs.getInt(_comfortUntilKey);
    if (until != null && DateTime.now().millisecondsSinceEpoch > until) {
      await prefs.setBool(_comfortKey, false);
      await prefs.remove(_comfortUntilKey);
      return false;
    }
    return prefs.getBool(_comfortKey) ?? false;
  }

  Future<void> setComfortFeedEnabled(bool enabled, {Duration? duration}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_comfortKey, enabled);
    if (enabled && duration != null) {
      await prefs.setInt(
        _comfortUntilKey,
        DateTime.now().add(duration).millisecondsSinceEpoch,
      );
    } else {
      await prefs.remove(_comfortUntilKey);
    }
  }

  Future<Set<String>> getTopicShields() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_shieldsKey)?.toSet() ?? {};
  }

  Future<void> setTopicShields(Set<String> shields) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_shieldsKey, shields.toList());
  }
}
