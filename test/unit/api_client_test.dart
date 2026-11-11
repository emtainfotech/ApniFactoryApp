import 'dart:convert';
import 'dart:typed_data';

import 'package:apni_factory/api_services/api_client.dart';
import 'package:apni_factory/api_services/api_end_point.dart';
import 'package:apni_factory/config/api_config.dart';
import 'package:apni_factory/shared_pref.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(
    RequestOptions options,
    int callIndex,
  ) handler;
  int calls = 0;

  _StubAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    calls += 1;
    return handler(options, calls);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ApiConfig & ApiEndPoint', () {
    test('uses safe default timeouts and resolves endpoints from baseUrl', () {
      expect(ApiConfig.connectTimeout, const Duration(seconds: 15));
      expect(ApiConfig.receiveTimeout, const Duration(seconds: 20));
      expect(ApiConfig.sendTimeout, const Duration(seconds: 15));
      expect(ApiEndPoint.baseUrl, ApiConfig.baseUrl);
      expect(ApiEndPoint.loginApi, '${ApiConfig.baseUrl}login');
      expect(ApiEndPoint.v2ProductsApi, '${ApiConfig.baseUrl}v2/products');
    });

    test('shared ApiClient configures timeouts and Accept header', () {
      final options = ApiClient.instance.dio.options;
      expect(options.connectTimeout, ApiConfig.connectTimeout);
      expect(options.receiveTimeout, ApiConfig.receiveTimeout);
      expect(options.sendTimeout, ApiConfig.sendTimeout);
      expect(options.headers['Accept'], 'application/json');
    });
  });

  group('ApiClient safety guarantees', () {
    test('redacts sensitive tokens, passwords, OTPs, and PayU secrets', () {
      const raw =
          'Authorization: Bearer abc.def.ghi token="secret_tok" password=myPass otp=1234 merchantSalt=xyz123';
      final cleaned = ApiClient.redactSensitiveString(raw);
      expect(cleaned, isNot(contains('abc.def.ghi')));
      expect(cleaned, isNot(contains('secret_tok')));
      expect(cleaned, isNot(contains('myPass')));
      expect(cleaned, isNot(contains('1234')));
      expect(cleaned, isNot(contains('xyz123')));
      expect(cleaned, contains('[REDACTED]'));
    });

    test('attaches Bearer token when available and retries idempotent GET on 503',
        () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      String? capturedAuth;
      final adapter = _StubAdapter((options, callIndex) async {
        capturedAuth = options.headers['Authorization']?.toString();
        if (callIndex == 1) {
          return ResponseBody.fromString(
            jsonEncode({'message': 'Temporary outage'}),
            503,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString(
          jsonEncode({'ok': true}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
      dio.httpClientAdapter = adapter;

      final client = ApiClient.forTesting(
        dio: dio,
        tokenProvider: () async => 'test-sanctum-token',
      );

      final response = await client.dio.get('v2/products');
      expect(response.statusCode, 200);
      expect(capturedAuth, 'Bearer test-sanctum-token');
      expect(adapter.calls, 2);
    });

    test('never retries financial POST order/payment requests on 503', () {
      final orderErr = DioException(
        requestOptions: RequestOptions(
          path: '/api/order',
          method: 'POST',
          extra: {'idempotent': true},
        ),
        response: Response(
          requestOptions: RequestOptions(path: '/api/order'),
          statusCode: 503,
        ),
        type: DioExceptionType.badResponse,
      );
      expect(ApiClient.shouldRetryRequest(orderErr), isFalse);

      final paymentErr = DioException(
        requestOptions: RequestOptions(
          path: '/api/v2/payments/initiate',
          method: 'POST',
          headers: {'X-Idempotency-Key': 'k1'},
        ),
        type: DioExceptionType.connectionTimeout,
      );
      expect(ApiClient.shouldRetryRequest(paymentErr), isFalse);
    });

    test('triggers single-shot session expiry and clears token on 401',
        () async {
      await SharedPref.setAuthToken('stale-token');
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'));
      dio.httpClientAdapter = _StubAdapter((options, callIndex) async {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Unauthenticated'}),
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      int expiredCount = 0;
      final client = ApiClient.forTesting(
        dio: dio,
        tokenProvider: () async => 'stale-token',
        onSessionExpired: () async {
          expiredCount += 1;
        },
      );

      await expectLater(
        client.dio.get('v2/buyer/claims'),
        throwsA(isA<DioException>()),
      );
      expect(expiredCount, 1);
      expect(await SharedPref.getAuthToken(), isEmpty);
    });

    test('mapError maps cancellation, timeouts, and 401 consistently', () {
      final cancel = ApiClient.mapError(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.cancel,
        ),
      );
      expect(cancel.isCancelled, isTrue);

      final timeout = ApiClient.mapError(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.receiveTimeout,
        ),
      );
      expect(timeout.isNetworkError, isTrue);

      final unauth = ApiClient.mapError(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          response: Response(
            requestOptions: RequestOptions(path: '/x'),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      expect(unauth.isUnauthorized, isTrue);
      expect(unauth.statusCode, 401);
    });
  });
}

