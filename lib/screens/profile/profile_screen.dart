import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../auth/login_screen.dart';
import '../settings/static_content_screen.dart';
import 'restaurant_profile_screen.dart';

/// Profile tab — doubles as the app's Settings screen. Every row here
/// opens something real: Restaurant Profile (hours/bank/GST all live in
/// that one form since that's how the backend's updateRestaurant()
/// already groups them — see that screen), a local Notifications
/// toggle, and Terms/Privacy fetched from the backend's own static-
/// content endpoints. There's no manager change-password endpoint and
/// no support contact info in the backend yet, so "Account Security"
/// and "Help & Support" aren't included rather than being built as
/// dead ends — see the delivery note for what to add if you want them.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    NotificationService.notificationsEnabled().then((v) {
      if (mounted) setState(() => _notificationsEnabled = v);
    });
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text("You'll need your email and password to log back in."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log out', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    await AuthService.logout();
    if (!context.mounted) return;
    context.read<AppState>().logout();
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<AppState>().currentManager;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(18)),
            child: Row(
              children: [
                const CircleAvatar(radius: 28, backgroundColor: AppTheme.primary, child: Icon(Icons.person, color: Colors.white, size: 30)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(manager?.name ?? 'Manager', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      if (manager?.email != null) ...[
                        const SizedBox(height: 2),
                        Text(manager!.email, style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 13)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionCard(context, children: [
            _tile(context,
                icon: Icons.storefront_outlined,
                title: 'Restaurant Profile',
                subtitle: 'Hours, contact, bank & GST details, photos',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RestaurantProfileScreen()))),
          ]),
          const SizedBox(height: 14),
          _sectionCard(context, children: [
            SwitchListTile(
              value: _notificationsEnabled,
              onChanged: (v) {
                setState(() => _notificationsEnabled = v);
                NotificationService.setNotificationsEnabled(v);
              },
              activeColor: AppTheme.primary,
              secondary: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Show a banner for new orders while the app is open', style: TextStyle(fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 14),
          _sectionCard(context, children: [
            _tile(context,
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const StaticContentScreen(title: 'Terms & Conditions', url: ApiConfig.termsPage)))),
            const Divider(height: 1, indent: 56),
            _tile(context,
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const StaticContentScreen(title: 'Privacy Policy', url: ApiConfig.privacyPage)))),
          ]),
          const SizedBox(height: 14),
          _sectionCard(context, children: [
            _tile(context, icon: Icons.logout_rounded, title: 'Log Out', iconColor: Colors.red, titleColor: Colors.red, onTap: () => _logout(context)),
          ]),
        ],
      ),
    );
  }

  Widget _sectionCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(color: AppTheme.surface(context), borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _tile(BuildContext context,
      {required IconData icon, required String title, String? subtitle, Color? iconColor, Color? titleColor, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppTheme.textPrimary(context)),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: titleColor)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      trailing: titleColor == null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }
}
