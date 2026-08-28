import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ButtonVariant { primary, secondary, ghost }

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.disabled = false,
    this.loading = false,
  });

  final String title;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool disabled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isPrimary = variant == ButtonVariant.primary;

    Color bg;
    Color fg;
    Border? border;

    switch (variant) {
      case ButtonVariant.primary:
        bg = AppColors.primary;
        fg = AppColors.onPrimary;
      case ButtonVariant.secondary:
        bg = AppColors.bgElevated;
        fg = AppColors.text;
        border = Border.all(color: AppColors.border);
      case ButtonVariant.ghost:
        bg = Colors.transparent;
        fg = AppColors.primary;
    }

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: disabled ? bg.withValues(alpha: 0.5) : bg,
        borderRadius: BorderRadius.circular(16),
        elevation: isPrimary ? 4 : 0,
        shadowColor: isPrimary ? Colors.black.withValues(alpha: 0.4) : null,
        child: InkWell(
          onTap: disabled || loading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: border,
            ),
            alignment: Alignment.center,
            child: loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                  )
                : Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: disabled ? fg.withValues(alpha: 0.6) : fg,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
