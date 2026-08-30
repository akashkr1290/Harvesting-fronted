import '../../services/api_client.dart';

class RegistrationApi {
  final ApiClient _api;
  RegistrationApi(this._api);
  Future<Map<String,dynamic>> start({required String username,required String password,required String fullName,required String email}) async => await _api.post('/api/auth/register',body:{'username':username,'password':password,'fullName':fullName,'email':email}) as Map<String,dynamic>;
  Future<Map<String,dynamic>> sendMobile(String token,String mobile) async => await _api.post('/api/auth/register/mobile/send-otp',body:{'registrationToken':token,'mobileNumber':mobile}) as Map<String,dynamic>;
  Future<Map<String,dynamic>> verifyMobile(String token,String otp) async => await _api.post('/api/auth/register/mobile/verify-otp',body:{'registrationToken':token,'otp':otp}) as Map<String,dynamic>;
  Future<Map<String,dynamic>> sendAadhaar(String token,String aadhaar) async => await _api.post('/api/auth/register/aadhaar/send-otp',body:{'registrationToken':token,'aadhaarNumber':aadhaar}) as Map<String,dynamic>;
  Future<Map<String,dynamic>> verifyAadhaar(String token,String otp) async => await _api.post('/api/auth/register/aadhaar/verify-otp',body:{'registrationToken':token,'otp':otp}) as Map<String,dynamic>;
  Future<Map<String,dynamic>> role(String token,String role) async => await _api.post('/api/auth/register/role',body:{'registrationToken':token,'role':role}) as Map<String,dynamic>;
  Future<Map<String,dynamic>> address(String token,Map<String,String> a) async => await _api.post('/api/auth/register/address',body:{'registrationToken':token,...a}) as Map<String,dynamic>;
  Future<Map<String,dynamic>> upload(String token,String type,List<int> bytes,String filename) async => await _api.uploadFile('/api/auth/register/documents/$type?registrationToken=${Uri.encodeQueryComponent(token)}',bytes:bytes,filename:filename) as Map<String,dynamic>;
  Future<Map<String,dynamic>> submit(String token) async => await _api.post('/api/auth/register/submit',body:{'registrationToken':token}) as Map<String,dynamic>;
}
