import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/master_item.dart';
import '../../services/api_client.dart';
import '../../services/master_data_service.dart';

class MasterDataScreen extends StatefulWidget {
  const MasterDataScreen({super.key});

  @override
  State<MasterDataScreen> createState() => _MasterDataScreenState();
}

class _MasterDataScreenState extends State<MasterDataScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: MasterCategory.values.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addItem(BuildContext context, MasterCategory category) {
    final controller = TextEditingController();
    bool saving = false;
    String? error;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> save() async {
            if (controller.text.trim().isEmpty) return;
            setDialogState(() {
              saving = true;
              error = null;
            });
            try {
              await context.read<MasterDataService>().add(category, controller.text.trim());
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            } on ApiException catch (e) {
              setDialogState(() {
                saving = false;
                error = e.message;
              });
            } catch (_) {
              setDialogState(() {
                saving = false;
                error = 'Could not reach the server. Check your connection and try again.';
              });
            }
          }

          return AlertDialog(
            title: Text('Add ${category.label}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  enabled: !saving,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: saving ? null : save,
                child: saving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleActive(MasterCategory category, MasterItem item) async {
    try {
      await context.read<MasterDataService>().toggleActive(category, item);
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

  Future<void> _removeItem(MasterCategory category, MasterItem item) async {
    try {
      await context.read<MasterDataService>().remove(category, item);
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

  @override
  Widget build(BuildContext context) {
    final masterData = context.watch<MasterDataService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Data'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: MasterCategory.values.map((c) => Tab(text: c.label)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: MasterCategory.values.map((category) {
          final items = masterData.itemsFor(category);
          return Scaffold(
            floatingActionButton: FloatingActionButton(
              mini: true,
              onPressed: () => _addItem(context, category),
              child: const Icon(Icons.add),
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                try {
                  await context.read<MasterDataService>().fetchAll();
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
              child: items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('No entries yet.', style: TextStyle(color: Colors.grey))),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];
                        return Card(
                          child: ListTile(
                            title: Text(
                              item.name,
                              style: TextStyle(
                                color: item.active ? Colors.black87 : Colors.grey,
                                decoration: item.active ? null : TextDecoration.lineThrough,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: item.active,
                                  onChanged: (_) => _toggleActive(category, item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                  onPressed: () => _removeItem(category, item),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
