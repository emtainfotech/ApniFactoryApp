import 'dart:async';
import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../shared_pref.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool isNetworkError;
  final bool isUnauthorized;
  final bool isCancelled;

  const ApiException({
    required this.message,
    this.statusCode,
    this.isNetworkError = false,
    this.isUnauthorized = false,
    this.isCancelled = false,
  });

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message)';
}

/// Shared, testable Dio HTTP client with timeouts, auth headers, safe retry for
/// idempotent requests, single-shot 401 session expiry callback, and log redaction.
class ApiClient {
  ApiClient._internal() {
    dio = _buildDio();
  }

  /// Injectable constructor for unit & widget tests with mock Dio/interceptors.
  ApiClient.forTesting({
    required this.dio,
    Future<String> Function()? tokenProvider,
    Future<void> Function()? onSessionExpired,
  })  : _tokenProvider = tokenProvider,
        _onSessionExpired = onSessionExpired {
    _attachInterceptors(dio);
  }

  static final ApiClient instance = ApiClient._internal();

  late final Dio dio;
  Future<String> Function()? _tokenProvider;
  Future<void> Function()? _onSessionExpired;
  bool _handlingUnauthorized = false;

  void configureSessionHandlers({
    Future<String> Function()? tokenProvider,
    Future<void> Function()? onSessionExpired,
  }) {
    _tokenProvider = tokenProvider;
    _onSessionExpired = onSessionExpired;
  }

  CancelToken createCancelToken() => CancelToken();

  Dio _buildDio() {
    final client = Dio(
      BaseOptions(
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: const {'Accept': 'application/json'},
      ),
    );
    _attachInterceptors(client);
    return client;
  }

  void _attachInterceptors(Dio target) {
    target.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = _tokenProvider != null
                ? await _tokenProvider!()
                : await SharedPref.getAuthToken();
            if (token.isNotEmpty &&
                !options.headers.containsKey('Authorization')) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (_) {
            // Safe fallback when SharedPreferences is unavailable in isolated tests
          }
          handler.next(options);
        },
        onError: (DioException err, handler) async {
          if (err.response?.statusCode == 401) {
            await _handleUnauthorizedOnce();
            return handler.next(err);
          }

          if (shouldRetryRequest(err)) {
            final retryCount = (err.requestOptions.extra['retry_count'] as int?) ?? 0;
            if (retryCount < 2) {
              err.requestOptions.extra['retry_count'] = retryCount + 1;
              await Future<void>.delayed(Duration(milliseconds: 250 * (retryCount + 1)));
              try {
                final response = await target.fetch(err.requestOptions);
                return handler.resolve(response);
              } on DioException catch (retryErr) {
                return handler.next(retryErr);
              }
            }
          }

          handler.next(err);
        },
      ),
    );
  }

  Future<void> _handleUnauthorizedOnce() async {
    if (_handlingUnauthorized) return;
    _handlingUnauthorized = true;
    try {
      await SharedPref.clearAuthToken();
      if (_onSessionExpired != null) {
        await _onSessionExpired!();
      }
    } finally {
      _handlingUnauthorized = false;
    }
  }

  /// Never retry financial, checkout, or non-idempotent POST writes blindly.
  static bool shouldRetryRequest(DioException err) {
    if (err.type == DioExceptionType.cancel) return false;

    final method = err.requestOptions.method.toUpperCase();
    final hasIdempotencyKey =
        err.requestOptions.headers.containsKey('X-Idempotency-Key') ||
            err.requestOptions.extra['idempotent'] == true;

    final bool isSafeMethod = (method == 'GET' || method == 'HEAD') ||
        (hasIdempotencyKey &&
            !err.requestOptions.path.contains('/order') &&
            !err.requestOptions.path.contains('/payments'));

    if (!isSafeMethod) return false;

    final status = err.response?.statusCode;
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        status == 502 ||
        status == 503 ||
        status == 504;
  }

  static ApiException mapError(DioException error) {
    if (error.type == DioExceptionType.cancel) {
      return const ApiException(
        message: 'Request cancelled.',
        isCancelled: true,
      );
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const ApiException(
        message: 'Network timeout or unavailable. Please check your connection and retry.',
        isNetworkError: true,
      );
    }
    final status = error.response?.statusCode;
    if (status == 401) {
      return const ApiException(
        message: 'Session expired. Please sign in again.',
        statusCode: 401,
        isUnauthorized: true,
      );
    }
    final dynamic data = error.response?.data;
    String msg = 'Request failed. Please try again.';
    if (data is Map && (data['message'] != null || data['msg'] != null)) {
      msg = redactSensitiveString((data['message'] ?? data['msg']).toString());
    }
    return ApiException(message: msg, statusCode: status);
  }

  static String redactSensitiveString(String input) {
    var out = input.replaceAll(
      RegExp(r'(Bearer\s+)[A-Za-z0-9\-\._~\+\/]+=*', caseSensitive: false),
      r'$1[REDACTED]',
    );
    out = out.replaceAll(
      RegExp(
        r'("?(?:password|token|otp|access_token|secret|salt|merchantSalt|merchantSecretKey)"?\s*[:=]\s*"?)[^",}\s]+("?)',
        caseSensitive: false,
      ),
      r'$1[REDACTED]$2',
    );
    return out;
  }

  static void safeLog(String label, dynamic payload) {
    if (!kDebugMode) return;
    final text = redactSensitiveString(payload?.toString() ?? '');
    dev.log('$label: $text');
  }
}
