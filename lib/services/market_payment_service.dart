import 'api_client.dart';
class MarketPaymentService { final ApiClient api; MarketPaymentService(this.api);
 Future<Map<String,dynamic>> digital(String orderId) async=>await api.post('/api/payments/market-orders/$orderId/digital') as Map<String,dynamic>;
 Future<Map<String,dynamic>> selectCash(String orderId) async=>await api.post('/api/payments/market-orders/$orderId/cash/select') as Map<String,dynamic>;
 Future<Map<String,dynamic>> cash(String orderId) async=>await api.post('/api/payments/market-orders/$orderId/cash') as Map<String,dynamic>;
}
