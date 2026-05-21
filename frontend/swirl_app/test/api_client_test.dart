import 'package:flutter_test/flutter_test.dart';
import 'package:swirl_app/core/network/api_client.dart';

void main() {
  test('uses Android emulator backend origin by default', () {
    expect(ApiClient.backendOrigin, 'http://10.0.2.2:5122');
    expect(ApiClient.apiBaseUrl, 'http://10.0.2.2:5122/api');
  });
}
