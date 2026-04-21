import 'package:chopper/chopper.dart';
import 'package:student_platform_frontend/data/data_sources/remote/api_service.dart';

void main() async {
  final chopper = ChopperClient(
    baseUrl: Uri.parse("http://localhost:5297"),
    services: [ApiService.create()],
    converter: const JsonConverter(),
  );

  final apiService = chopper.getService<ApiService>();
  final response = await apiService.login({'username': 'admin', 'password': 'admin1234'});
  
  print('Status code: ' + response.statusCode.toString() + '');
  if (response.isSuccessful && response.body != null) {
      print('Login Success!');
      print(response.body);
  } else {
      print('Login failed.');
  }

  chopper.dispose();
}
