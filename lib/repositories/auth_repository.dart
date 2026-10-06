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

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _api.post(
      '/api/auth/register',
      body: {'name': name.trim(), 'email': email.trim(), 'password': password},
    );
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
    final nested = data['user'];
    final userJson =
        nested is Map ? Map<String, dynamic>.from(nested) : data;
    return _currentUser = AppUser.fromJson(userJson);
  }

  Future<AppUser?> restoreSession() async {
    if (await _tokens.readRefreshToken() == null) return null;
    if (!await _api.refreshSession()) return null;
    return fetchProfile();
  }

  Future<void> logout() async {
    try {
      await _api.post('/api/auth/logout', auth: true);
    } catch (_) {
    } finally {
      await _tokens.clear();
      await _tokens.clearRolePending();
      _currentUser = null;
    }
  }

  Future<void> sendVerificationOtp(String email) =>
      _api.post('/api/otp/send-verification', body: {'email': email.trim()});
      
  Future<AppUser> verifyEmail({
    required String email,
    required String otp,
  }) async {
    final response = await _api.post(
      '/api/otp/verify-email',
      body: {'email': email.trim(), 'otp': otp},
    );
    final user = await _startSession(response);
    await _tokens.markRolePending(user.id);
    return user;
  }

  Future<bool> needsRoleSelection() async {
    final user = _currentUser;
    if (user == null) return false;
    final onboarded = user.isOnboarded;
    if (onboarded != null) return !onboarded;
    return await _tokens.readRolePendingUser() == user.id;
  }

  Future<AppUser> saveOnboarding(List<String> useCases) async {
    final response = await _api.patch(
      '/api/users/onboarding',
      body: {'useCases': useCases},
      auth: true,
    );

    final nested = response.data?['user'];
    final savedUseCases = nested is Map && nested['useCases'] is List
        ? (nested['useCases'] as List).map((e) => '$e').toList()
        : useCases;

    await _tokens.clearRolePending();

    final current = _currentUser;
    if (current == null) {
      return _currentUser = await fetchProfile();
    }
    return _currentUser = current.copyWith(
      isOnboarded: true,
      useCases: savedUseCases,
    );
  }
  
  Future<void> enableTwoFactor(String code) =>
      _api.post('/api/auth/2fa/enable', body: {'code': code}, auth: true);

  Future<void> forgotPassword(String email) =>
      _api.post('/api/otp/forgot-password', body: {'email': email.trim()});

  Future<void> resetPassword({required String email, required String otp, required String newPassword,}) =>
      _api.post(
        '/api/otp/reset-password',
        body: {'email': email.trim(), 'otp': otp, 'newPassword': newPassword},
      );

  _Session? _extractSession(Map<String, dynamic>? data) {
    if (data == null) return null;
    final tokens = data['tokens'] is Map
        ? Map<String, dynamic>.from(data['tokens'] as Map)
        : data;
    final access = tokens['accessToken'] ?? tokens['access_token'] ?? tokens['access'];
    final refresh =
        tokens['refreshToken'] ?? tokens['refresh_token'] ?? tokens['refresh'];
    if (access is! String || access.isEmpty) return null;
    if (refresh is! String || refresh.isEmpty) return null;
    final userJson = data['user'];
    return _Session(
      access,
      refresh,
      userJson is Map ? Map<String, dynamic>.from(userJson) : null,
    );
  }

  Future<AppUser> _startSession(ApiResponse response) async {
    final session = _extractSession(response.data);
    if (session == null) {
      throw const ApiException(
        'Unexpected response from the server. Please try again.',
      );
    }

    await _tokens.saveTokens(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
    );
    final userJson = session.user;
    if (userJson == null) return fetchProfile();
    return _currentUser = AppUser.fromJson(userJson);
  }
}

class _Session {
  const _Session(this.accessToken, this.refreshToken, this.user);
  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic>? user;
}
