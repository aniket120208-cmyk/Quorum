import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:quorum/token_storage.dart';
import 'api_configuration.dart';
import 'api_exception.dart';

class ApiResponse {
  const ApiResponse({required this.message, this.data,});
  final String message;
  final Map<String, dynamic>? data;
}

class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    Dio? dio,
  })  : _tokens = tokenStorage,
        _dio = dio ?? _buildDio() {
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError,
      ),
    );
  }

  static const String _authKey = 'auth';
  static const String _retriedKey = 'retried';
  final TokenStorage _tokens;
  final Dio _dio;

  final StreamController<void> _sessionExpired =
      StreamController<void>.broadcast();

  Future<bool>? _refreshInFlight;

  static Dio _buildDio() {
    return Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.requestTimeout,
        receiveTimeout: ApiConfig.requestTimeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          ApiConfig.platformHeader: ApiConfig.platformValue,
        },
      ),
    );
  }

  Stream<void> get sessionExpired => _sessionExpired.stream;

  Future<ApiResponse> get(
    String path, {
    bool auth = false,
  }) {
    return _send(
      'GET',
      path,
      auth: auth,
    );
  }

  Future<ApiResponse> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) {
    return _send(
      'POST',
      path,
      body: body,
      auth: auth,
    );
  }

  Future<bool> refreshSession() {
    return _refreshAccessToken();
  }

  Future<ApiResponse> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    required bool auth,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        data: method == 'GET' ? null : (body ?? <String, dynamic>{}),
        options: Options(
          method: method,
          extra: {
            _authKey: auth,
          },
        ),
      );

      return _toApiResponse(response);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  void _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final token = _tokens.accessToken;

    if (options.extra[_authKey] == true && token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final request = error.requestOptions;

    final isUnauthorized =
        error.response?.statusCode == 401;

    final isAuthenticatedRequest =
        request.extra[_authKey] == true;

    final hasAlreadyRetried =
        request.extra[_retriedKey] == true;

    if (!isUnauthorized ||
        !isAuthenticatedRequest ||
        hasAlreadyRetried) {
      handler.next(error);
      return;
    }

    try {
      final refreshed = await _refreshAccessToken();

      if (!refreshed) {
        if (!_sessionExpired.isClosed) {
          _sessionExpired.add(null);
        }

        handler.next(error);
        return;
      }

      request.extra[_retriedKey] = true;

      final newRequest = await _dio.fetch<dynamic>(
        request,
      );

      handler.resolve(newRequest);
    } catch (e) {
      if (e is DioException) {
        handler.reject(e);
        return;
      }
      if (e is ApiException) {
        handler.reject(
          DioException(
            requestOptions: request,
            error: e,
            message: e.message,
          ),
        );
        return;
      }
      handler.reject(
        DioException(
          requestOptions: request,
          error: e,
        ),
      );
    }
  }

  Future<bool> _refreshAccessToken() {
    final existingRefresh = _refreshInFlight;
    if (existingRefresh != null) {
      return existingRefresh;
    }

    final future = _doRefresh();
    _refreshInFlight = future;

    future.then(
      (_) {
        if (identical(_refreshInFlight, future)) {
          _refreshInFlight = null;
        }
      },
      onError: (_,_) {
        if (identical(_refreshInFlight, future)) {
          _refreshInFlight = null;
        }
      },
    );
    return future;
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await _tokens.readRefreshToken();

    if (refreshToken == null ||
        refreshToken.isEmpty) {
      await _tokens.clear();
      return false;
    }

    try {
      final response = await _dio.post<dynamic>(
        '/api/auth/refresh-token',
        data: {
          'refreshToken': refreshToken,
        },
        options: Options(
          extra: {
            _authKey: false,
          },
        ),
      );

      final data = _toApiResponse(response).data;

      final accessToken = data?['accessToken'];
      final newRefreshToken = data?['refreshToken'];

      if (accessToken is String &&
          accessToken.isNotEmpty &&
          newRefreshToken is String &&
          newRefreshToken.isNotEmpty) {
        await _tokens.saveTokens(
          accessToken: accessToken,
          refreshToken: newRefreshToken,
        );
        return true;
      }

      throw const ApiException(
        'Unexpected response from the server.',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _tokens.clear();
        return false;
      }
      throw _toApiException(e);
    }
  }

  Map<String, dynamic>? _asMap(dynamic body) {
    dynamic decoded = body;

    if (decoded is String) {
      try {
        decoded = jsonDecode(decoded);
      } catch (_) {
        return null;
      }
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    return null;
  }

  ApiResponse _toApiResponse(
    Response<dynamic> response,
  ) {
    final json = _asMap(response.data);
    final rawMessage = json?['message'];
    final rawData = json?['data'];

    return ApiResponse(
      message: rawMessage is String ? rawMessage : '',
      data: rawData is Map ? Map<String, dynamic>.from(rawData) : null,
    );
  }

  ApiException _toApiException(DioException e) {
    final inner = e.error;

    if (inner is ApiException) {
      return inner;
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          'The server took too long to respond. Please try again.',
        );

      case DioExceptionType.connectionError:
        return const ApiException(
          "Couldn't reach the server. Check your internet connection.",
        );

      case DioExceptionType.cancel:
        return const ApiException(
          'Request cancelled.',
        );

      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;

        final message = _asMap(e.response?.data,)?['message'];

        return ApiException(
          message is String? message : _fallbackMessage(status ?? 0),
          statusCode: status,
        );

      case DioExceptionType.badCertificate:
        return const ApiException(
          'The server certificate is invalid.',
        );

      case DioExceptionType.unknown:
        if (inner is SocketException) {
          return const ApiException(
            "Couldn't reach the server. Check your internet connection.",
          );
        }

        return const ApiException(
          'Something went wrong. Please try again.',
        );

      default:
        return const ApiException(
          'Something went wrong. Please try again.',
        );
    }
  }

  String _fallbackMessage(int status) {
    if (status == 400) {
      return 'Invalid request.';
    }
    if (status == 401) {
      return 'Session expired. Please log in again.';
    }
    if (status == 403) {
      return 'You are not authorized to perform this action.';
    }
    if (status == 404) {
      return 'Requested resource was not found.';
    }
    if (status == 429) {
      return 'Too many attempts. Please try again later.';
    }
    if (status >= 500) {
      return 'Server error. Please try again in a moment.';
    }
    return 'Request failed ($status). Please try again.';
  }
  void dispose() {
    _sessionExpired.close();
  }
}