import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme.dart';
import 'auth/login_screen.dart';
import '../widgets/root_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decide());
  }

  Future<void> _decide() async {
    final state = context.read<AppState>();
    await Future.wait([
      state.bootstrap(),
      Future.delayed(const Duration(milliseconds: 1200)), // brief brand moment
    ]);
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => state.isLoggedIn ? const RootShell() : const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(color: AppTheme.gold, shape: BoxShape.circle),
              child: const Icon(Icons.storefront, color: AppTheme.primaryDark, size: 44),
            ),
            const SizedBox(height: 24),
            const Text(
              'JEEVI FOODIE\nRESTAURANT',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1, height: 1.3),
            ),
            const SizedBox(height: 10),
            Text('Manage orders & menu', style: TextStyle(color: Colors.white.withOpacity(0.85))),
            const SizedBox(height: 32),
            const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.gold)),
          ],
        ),
      ),
    );
  }
}
