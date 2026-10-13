import 'package:flutter_test/flutter_test.dart';
import 'package:radar_concursos/core/config/app_config.dart';

void main() {
  test('API base URL is HTTPS and includes v1 path', () {
    final uri = Uri.parse(AppConfig.apiBaseUrl);
    expect(uri.scheme, 'https');
    expect(uri.host, 'radar-concursos-backend-production.up.railway.app');
    expect(uri.path, '/v1');
  });
}
