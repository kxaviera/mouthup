import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/display_name.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/screen_wrapper.dart';
import '../../widgets/user_avatar.dart';

class ChooseNameScreen extends StatefulWidget {
  const ChooseNameScreen({super.key});

  @override
  State<ChooseNameScreen> createState() => _ChooseNameScreenState();
}

class _ChooseNameScreenState extends State<ChooseNameScreen> {
  late final TextEditingController _username;
  late final TextEditingController _screenName;
  static final _usernamePattern = RegExp(r'^[A-Za-z][A-Za-z0-9_]{2,19}$');

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    final initialUsername = app.usernameLocked ? app.nickname : app.generateUniqueUsername();
    _username = TextEditingController(text: initialUsername);
    _screenName = TextEditingController(text: app.screenName.isNotEmpty ? app.screenName : _suggestedScreenName(initialUsername));
    _username.addListener(_syncPreview);
  }

  String _suggestedScreenName(String username) {
    return username.replaceAll('_', ' ').replaceAll(RegExp(r'(\d+)$'), '').trim();
  }

  void _syncPreview() {
    if (_screenName.text.trim().isEmpty || _screenName.text == _suggestedScreenName(_username.text)) {
      setState(() {});
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _screenName.dispose();
    super.dispose();
  }

  String? _validate() {
    final username = _username.text.trim();
    final screen = _screenName.text.trim();
    if (!_usernamePattern.hasMatch(username)) {
      return 'Username: 3–20 chars, starts with a letter, letters/numbers/_ only';
    }
    if (screen.length < 2 || screen.length > 40) {
      return 'Screen name must be 2–40 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final username = _username.text.trim().isEmpty ? app.nickname : _username.text.trim();
    final screen = _screenName.text.trim();
    final previewName = displayNameFor(screenName: screen, username: username);
    final locked = app.usernameLocked;

    return ScreenWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Text('STEP 1 OF 4', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Your identity', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.text)),
          const SizedBox(height: 6),
          const Text(
            'Username is for login and your profile link. Screen name is what people see.',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                UserAvatar(name: previewName, radius: 40),
                const SizedBox(height: 12),
                Text(previewName, style: const TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w700)),
                if (username.isNotEmpty)
                  Text(usernameHandle(username), style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _username,
            enabled: !locked,
            style: const TextStyle(color: AppColors.text),
            decoration: InputDecoration(
              hintText: 'Username',
              prefixIcon: const Icon(Icons.alternate_email, color: AppColors.textDim),
              suffixIcon: locked ? const Icon(Icons.lock_outline, size: 18, color: AppColors.textDim) : null,
              helperText: locked ? 'Username is permanent' : 'Used to log in and for @mentions',
              helperStyle: const TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _screenName,
            style: const TextStyle(color: AppColors.text),
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Screen name',
              prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textDim),
              helperText: 'Your display name on posts and profile',
              helperStyle: TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
          ),
          const Spacer(),
          PrimaryButton(
            title: 'Continue →',
            onPressed: () async {
              final error = _validate();
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                return;
              }
              final u = _username.text.trim();
              final s = _screenName.text.trim();
              final saveError = await context.read<AppState>().saveUsername(username: u, screenNameInput: s);
              if (!context.mounted) return;
              if (saveError != null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(saveError)));
                return;
              }
              context.go('/onboarding/account-type');
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
