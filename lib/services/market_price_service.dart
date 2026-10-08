import 'api_client.dart';

/// Today's mandi (APMC) price for a crop, from GET /api/market-prices (Agmarknet).
class MandiPrice {
  final String commodity;
  final double modalPerKg;
  final double minPerKg;
  final double maxPerKg;
  final String date;
  final String? market;
  final String source;

  MandiPrice({
    required this.commodity,
    required this.modalPerKg,
    required this.minPerKg,
    required this.maxPerKg,
    required this.date,
    required this.market,
    required this.source,
  });

  factory MandiPrice.fromJson(Map<String, dynamic> j) => MandiPrice(
        commodity: j['commodity'] as String? ?? '',
        modalPerKg: (j['modalPerKg'] as num).toDouble(),
        minPerKg: (j['minPerKg'] as num?)?.toDouble() ?? 0,
        maxPerKg: (j['maxPerKg'] as num?)?.toDouble() ?? 0,
        date: j['date'] as String? ?? '',
        market: j['market'] as String?,
        source: j['source'] as String? ?? 'Agmarknet',
      );
}

/// Caches prices for the session so lists of offers do not repeat requests.
/// Returns null when there is no data: the app then simply hides the comparison.
class MarketPriceService {
  final ApiClient _api;
  final Map<String, MandiPrice?> _cache = {};

  MarketPriceService(this._api);

  Future<MandiPrice?> latest(String crop, {String? district}) async {
    final key = '${crop.toLowerCase()}|${district ?? ''}';
    if (_cache.containsKey(key)) return _cache[key];
    try {
      final res = await _api.get('/api/market-prices', query: {'crop': crop, 'district': district}) as Map<String, dynamic>;
      return _cache[key] = MandiPrice.fromJson(res);
    } catch (_) {
      return _cache[key] = null;
    }
  }
}
