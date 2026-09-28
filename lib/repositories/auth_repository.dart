import '../../api/api_client.dart';
import '../../api/api_exception.dart';
import 'package:quorum/token_storage.dart';
import '../models/app_user.dart';

class AuthRepository {
  AuthRepository({required ApiClient api, required TokenStorage tokenStorage})
      : _api = api,
        _tokens = tokenStorage;

  final ApiClient _api;
  final TokenStorage _tokens;

  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  Stream<void> get sessionExpired => _api.sessionExpired;

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      '/api/auth/register',
      body: {'name': name.trim(), 'email': email.trim(), 'password': password},
    );
    return _startSession(response);
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      '/api/auth/login',
      body: {'email': email.trim(), 'password': password},
    );
    return _startSession(response);
  }

  Future<AppUser> fetchProfile() async {
    final response = await _api.get('/api/auth/me', auth: true);
    final data = response.data;
    if (data == null) {
      throw const ApiException('Unexpected response from the server.');
    }
    return _currentUser = AppUser.fromJson(data);
  }

  Future<AppUser?> restoreSession() async {
    if (await _tokens.readRefreshToken() == null) return null;
    if (!await _api.refreshSession()) return null;
    return fetchProfile();
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _tokens.readRefreshToken();
      if (refreshToken != null) {
        await _api.post('/api/auth/logout', body: {'refreshToken': refreshToken});
      }
    } catch (_) {
    } finally {
      await _tokens.clear();
      _currentUser = null;
    }
  }

  Future<void> sendVerificationOtp() =>
      _api.post('/api/otp/send-verification', auth: true);

  Future<void> verifyEmail(String otp) =>
      _api.post('/api/otp/verify-email', body: {'otp': otp}, auth: true);

  Future<void> forgotPassword(String email) =>
      _api.post('/api/otp/forgot-password', body: {'email': email.trim()});

  Future<void> resetPassword({required String email, required String otp, required String newPassword,}) =>
      _api.post(
        '/api/otp/reset-password',
        body: {'email': email.trim(), 'otp': otp, 'newPassword': newPassword},
      );

  Future<AppUser> _startSession(ApiResponse response) async {
    final data = response.data;
    final accessToken = data?['accessToken'];
    final refreshToken = data?['refreshToken'];
    final userJson = data?['user'];

    if (accessToken is! String || refreshToken is! String || userJson is! Map) {
      throw const ApiException(
        'Unexpected response from the server. Please try again.',
      );
    }

    await _tokens.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    return _currentUser = AppUser.fromJson(Map<String, dynamic>.from(userJson));
  }
}
