class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:'http://quorum-backend-env.eba-2vd8rmzr.ap-south-1.elasticbeanstalk.com',);

  static const String platformHeader = 'X-Client-Platform';
  static const String platformValue = 'mobile';
  static const Duration requestTimeout = Duration(seconds: 20);
}
