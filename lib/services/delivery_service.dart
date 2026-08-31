import 'api_client.dart';
class DeliveryService { final ApiClient api; DeliveryService(this.api);
 Future<List<Map<String,dynamic>>> assigned() async => ((await api.get('/api/deliveries/assigned')) as List).cast<Map<String,dynamic>>();
 Future<Map<String,dynamic>> pickup(String id) async => await api.post('/api/deliveries/$id/pickup') as Map<String,dynamic>;
 Future<Map<String,dynamic>> reachBuyer(String id) async => await api.post('/api/deliveries/$id/reach-buyer') as Map<String,dynamic>;
 Future<Map<String,dynamic>> complete(String id,String otp) async => await api.post('/api/deliveries/$id/complete?otp=${Uri.encodeQueryComponent(otp)}') as Map<String,dynamic>;
 Future<String> generateOtp(String id) async {final r=await api.post('/api/deliveries/$id/otp') as Map<String,dynamic>;return r['otp'] as String;}
 Future<Map<String,dynamic>> receipt(String id) async => await api.get('/api/deliveries/$id/receipt') as Map<String,dynamic>;
}
