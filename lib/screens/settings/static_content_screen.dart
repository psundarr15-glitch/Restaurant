import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/common/states.dart';

/// Renders Terms & Conditions / Privacy Policy from the backend's own
/// `pages/terms` and `pages/privacy` endpoints (Api\StaticContentApiController)
/// — the same content the customer-facing site shows, not placeholder text.
class StaticContentScreen extends StatefulWidget {
  final String title;
  final String url;
  const StaticContentScreen({super.key, required this.title, required this.url});

  @override
  State<StaticContentScreen> createState() => _StaticContentScreenState();
}

class _StaticContentScreenState extends State<StaticContentScreen> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _future = ApiClient.get(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData && !snapshot.hasError) return const LoadingState();
          if (snapshot.hasError) return ErrorState(message: '${snapshot.error}', onRetry: _load);

          final data = snapshot.data!;
          final sections = (data['sections'] as List<dynamic>? ?? []);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (data['updated'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text('Updated ${data['updated']}', style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 12.5)),
                ),
              for (final s in sections) ...[
                if (s['heading'] != null) ...[
                  Text(s['heading'].toString(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 8),
                ],
                Text(s['body']?.toString() ?? '', style: TextStyle(fontSize: 13.5, height: 1.5, color: AppTheme.textPrimary(context))),
                const SizedBox(height: 16),
              ],
            ],
          );
        },
      ),
    );
  }
}
