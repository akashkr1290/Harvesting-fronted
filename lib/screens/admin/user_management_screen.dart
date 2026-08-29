import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../models/login_history_entry.dart';
import '../../models/user_role.dart';
import '../../services/api_client.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Screen opens with whatever's already cached; refresh from the backend
    // so Admin sees the current state (e.g. another admin's changes) rather
    // than a possibly-stale list from login time.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserService>().fetchUsers().catchError((_) {
        // Swallow here — the cached list still renders; a banner would be
        // more correct but this keeps the screen usable if offline briefly.
      });
    });
  }

  /// Shown once after creating a user or resetting a password — this is
  /// the only moment the plaintext temp password exists anywhere, so it
  /// gets a dialog the admin has to explicitly dismiss, not a snackbar
  /// that could disappear before they've copied it down.
  void _showCredentialsDialog(String title, String username, String tempPassword) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share these with the user — this password will not be shown again.'),
            const SizedBox(height: 16),
            SelectableText('Username: $username', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            SelectableText('Temporary password: $tempPassword',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Done')),
        ],
      ),
    );
  }

  void _openCreateUserSheet() {
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    final emailController = TextEditingController();
    final locationController = TextEditingController();
    UserRole selectedRole = UserRole.plotSelection;
    bool creating = false;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> submit() async {
              if (nameController.text.trim().isEmpty || emailController.text.trim().isEmpty) {
                setSheetState(() => error = 'Name and email are required.');
                return;
              }
              setSheetState(() {
                creating = true;
                error = null;
              });
              try {
                final result = await context.read<UserService>().createUser(
                      name: nameController.text.trim(),
                      mobile: mobileController.text.trim(),
                      email: emailController.text.trim(),
                      role: selectedRole,
                      location: locationController.text.trim(),
                    );
                if (!sheetContext.mounted) return;
                Navigator.pop(sheetContext);
                _showCredentialsDialog('User Created', result.user.username, result.temporaryPassword);
              } on ApiException catch (e) {
                setSheetState(() {
                  creating = false;
                  error = e.message;
                });
              } catch (_) {
                setSheetState(() {
                  creating = false;
                  error = 'Could not reach the server. Check your connection and try again.';
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Create User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    enabled: !creating,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: mobileController,
                    enabled: !creating,
                    decoration: const InputDecoration(labelText: 'Mobile'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    enabled: !creating,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: locationController,
                    enabled: !creating,
                    decoration: const InputDecoration(labelText: 'Location'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<UserRole>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: UserRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.label))).toList(),
                    onChanged: creating ? null : (r) => setSheetState(() => selectedRole = r ?? selectedRole),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: creating ? null : submit,
                    child: creating
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Create & Auto-Generate Credentials'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleActive(AppUser user) async {
    try {
      await context.read<UserService>().toggleActive(user);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not reach the server. Check your connection and try again.')),
      );
    }
  }

  Future<void> _resetPassword(AppUser user) async {
    try {
      final result = await context.read<UserService>().resetPassword(user);
      if (!mounted) return;
      _showCredentialsDialog('Password Reset', result.user.username, result.temporaryPassword);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not reach the server. Check your connection and try again.')),
      );
    }
  }

  Future<void> _showLoginHistory(AppUser user) async {
    List<LoginHistoryEntry> history;
    try {
      history = await context.read<UserService>().getLoginHistory(user);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not reach the server. Check your connection and try again.')),
      );
      return;
    }
    if (!mounted) return;

    final dateFmt = DateFormat('dd MMM yyyy, hh:mm a');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Login History — ${user.username}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              if (history.isEmpty)
                const Text('No login attempts recorded yet.', style: TextStyle(color: Colors.grey))
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: history.length,
                    itemBuilder: (context, i) {
                      final entry = history[i];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          entry.success ? Icons.check_circle_outline : Icons.error_outline,
                          color: entry.success ? AppTheme.primary : AppTheme.danger,
                        ),
                        title: Text(dateFmt.format(entry.loggedInAt.toLocal())),
                        subtitle: Text(entry.success
                            ? (entry.ipAddress ?? 'Unknown IP')
                            : (entry.failureReason ?? 'Failed') + (entry.ipAddress != null ? ' · ${entry.ipAddress}' : '')),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userService = context.watch<UserService>();
    final users = userService.users;

    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateUserSheet,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('New User'),
      ),
      body: userService.isLoading && users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                try {
                  await context.read<UserService>().fetchUsers();
                } on ApiException catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                } catch (_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not refresh. Check your connection and try again.')),
                  );
                }
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, i) {
                  final user = users[i];
                  return Card(
                    child: ListTile(
                      title: Text(user.name),
                      subtitle: Text('${user.role.label} · ${user.location}\n@${user.username}'),
                      isThreeLine: true,
                      leading: CircleAvatar(
                        backgroundColor: user.active ? AppTheme.primary.withOpacity(0.15) : Colors.grey.shade200,
                        child: Icon(Icons.person, color: user.active ? AppTheme.primary : Colors.grey),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) {
                          if (action == 'toggle') {
                            _toggleActive(user);
                          } else if (action == 'reset') {
                            _resetPassword(user);
                          } else if (action == 'history') {
                            _showLoginHistory(user);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'toggle', child: Text(user.active ? 'Deactivate' : 'Activate')),
                          const PopupMenuItem(value: 'reset', child: Text('Reset Password')),
                          const PopupMenuItem(value: 'history', child: Text('View Login History')),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
