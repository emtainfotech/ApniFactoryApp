import 'dart:io';

import 'package:apni_factory/api_services/api_client.dart';
import 'package:apni_factory/screens/network_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class HandleDio {
  static Future handleDioError({
    required DioException error,
    required BuildContext context,
  }) async {
    if (error.type == DioExceptionType.cancel) {
      return null;
    }

    final bool isOffline = error.error is SocketException ||
        error.type == DioExceptionType.connectionError;

    if (isOffline && context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => NetworkErrorScreen(),
        ),
        (route) => false,
      );
    } else {
      final apiError = ApiClient.mapError(error);
      ApiClient.safeLog('HandleDio', {
        'type': error.type.name,
        'statusCode': apiError.statusCode,
        'message': apiError.message,
      });
    }
    return null;
  }
}
