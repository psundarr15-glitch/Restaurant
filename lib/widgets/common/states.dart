import 'package:flutter/material.dart';
import '../../theme.dart';
import 'buttons.dart';

/// Centered spinner for the initial load of any API-driven screen.
class LoadingState extends StatelessWidget {
  const LoadingState({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator(color: AppTheme.primary));
}

/// "No orders yet" / "Add your first menu item" style placeholder so no
/// API-driven screen ever renders a blank list.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(icon, size: 34, color: AppTheme.primary),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context))),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              SizedBox(width: 180, child: PrimaryButton(label: actionLabel!, onPressed: onAction)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shown when an API call fails, with a retry action — never leaves a
/// blank screen or a raw exception string on its own.
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.wifi_off_rounded, size: 32, color: Colors.red),
            ),
            const SizedBox(height: 16),
            Text('Something went wrong',
                style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context))),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context))),
            const SizedBox(height: 20),
            SizedBox(width: 160, child: SecondaryButton(label: 'Retry', onPressed: onRetry)),
          ],
        ),
      ),
    );
  }
}
