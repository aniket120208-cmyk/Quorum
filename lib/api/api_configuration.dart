class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:'https://api.newquorum.me/',);

  static const String platformHeader = 'X-Client-Platform';
  static const String platformValue = 'mobile';
  static const Duration requestTimeout = Duration(seconds: 20);
}
