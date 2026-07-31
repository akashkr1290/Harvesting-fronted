import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/master_item.dart';

/// Real master data against /api/master-data/{category}. Reads are open to
/// any authenticated user (every stage form needs these for dropdowns);
/// writes are Admin-only on the backend, enforced there via @PreAuthorize —
/// this service doesn't duplicate that check, it just surfaces the 403 if
/// a non-admin somehow calls add/toggleActive/remove.
class MasterDataService extends ChangeNotifier {
  final ApiClient _api;
  final Map<MasterCategory, List<MasterItem>> _data = {
    for (final c in MasterCategory.values) c: [],
  };
  bool _loading = false;

  MasterDataService(this._api);

  bool get isLoading => _loading;

  List<MasterItem> itemsFor(MasterCategory category) => List.unmodifiable(_data[category]!);

  List<MasterItem> activeItemsFor(MasterCategory category) =>
      _data[category]!.where((i) => i.active).toList();

  /// Fetches every category (including inactive items, so Admin's master
  /// data screen can still see and re-toggle them) and populates the local
  /// cache. Call once after login; the rest of the app reads synchronously
  /// off that cache via itemsFor/activeItemsFor, same as before.
  Future<void> fetchAll() async {
    _loading = true;
    notifyListeners();
    try {
      for (final category in MasterCategory.values) {
        final res = await _api.get(
          '/api/master-data/${category.apiValue}',
          query: {'activeOnly': false},
        ) as List<dynamic>;
        _data[category] = res.map((j) => MasterItem.fromJson(j as Map<String, dynamic>)).toList();
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> add(MasterCategory category, String name) async {
    final res = await _api.post('/api/master-data/${category.apiValue}', body: {'name': name})
        as Map<String, dynamic>;
    _data[category]!.add(MasterItem.fromJson(res));
    notifyListeners();
  }

  Future<void> toggleActive(MasterCategory category, MasterItem item) async {
    final res = await _api.patch('/api/master-data/${category.apiValue}/${item.id}/toggle-active')
        as Map<String, dynamic>;
    final updated = MasterItem.fromJson(res);
    final index = _data[category]!.indexWhere((i) => i.id == item.id);
    if (index != -1) _data[category]![index] = updated;
    notifyListeners();
  }

  Future<void> remove(MasterCategory category, MasterItem item) async {
    await _api.delete('/api/master-data/${category.apiValue}/${item.id}');
    _data[category]!.removeWhere((i) => i.id == item.id);
    notifyListeners();
  }
}
