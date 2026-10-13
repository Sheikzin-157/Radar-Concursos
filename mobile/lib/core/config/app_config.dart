abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://radar-concursos-backend-production.up.railway.app/v1',
  );
}
