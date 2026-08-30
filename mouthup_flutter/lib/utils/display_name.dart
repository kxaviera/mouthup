/// Display name shown in the UI (screen name, falling back to username).
String displayNameFor({String? screenName, required String username}) {
  final trimmed = screenName?.trim();
  if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  return username;
}

String usernameHandle(String username) => username.startsWith('@') ? username : '@$username';
