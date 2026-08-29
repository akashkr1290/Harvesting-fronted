import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  String? _error;
  List<AppNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiClient>();
      final list = await api.get('/api/notifications') as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _notifications = list.map((j) => AppNotification.fromApi(j as Map<String, dynamic>)).toList();
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load notifications. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(AppNotification n) async {
    if (!n.isUnread) return;
    try {
      await context.read<ApiClient>().post('/api/notifications/${n.id}/read');
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  IconData _iconFor(String category) {
    switch (category) {
      case 'IMAGE_VERIFICATION':
        return Icons.image_outlined;
      case 'PAYMENT':
        return Icons.payments_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [
                    const SizedBox(height: 80),
                    Center(child: Text(_error!, style: const TextStyle(color: AppTheme.danger))),
                  ])
                : _notifications.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 80),
                        Center(child: Text('No notifications yet.', style: TextStyle(color: Colors.grey))),
                      ])
                    : ListView.builder(
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final n = _notifications[index];
                          return ListTile(
                            leading: Icon(_iconFor(n.category), color: n.isUnread ? AppTheme.primary : Colors.grey),
                            title: Text(n.title, style: TextStyle(fontWeight: n.isUnread ? FontWeight.bold : FontWeight.normal)),
                            subtitle: Text(n.message),
                            trailing: n.isUnread ? const Icon(Icons.circle, size: 10, color: AppTheme.accent) : null,
                            onTap: () => _markRead(n),
                          );
                        },
                      ),
      ),
    );
  }
}
