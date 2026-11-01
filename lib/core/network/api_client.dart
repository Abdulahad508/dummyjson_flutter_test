import 'package:dio/dio.dart';
import 'package:dummyjson_flutter_test/core/network/session_notifier.dart';
import 'package:dummyjson_flutter_test/core/storage/token_storage.dart';

const String dummyJsonBaseUrl = 'https://dummyjson.com';

/// Shared HTTP client. Attaches the saved access token and reports 401s.
class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    required SessionNotifier sessionNotifier,
    Dio? client,
  }) : dio =
           client ??
           Dio(
             BaseOptions(
               baseUrl: dummyJsonBaseUrl,
               connectTimeout: const Duration(seconds: 15),
               receiveTimeout: const Duration(seconds: 20),
               headers: const {'Content-Type': 'application/json'},
             ),
           ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final status = error.response?.statusCode;
          final path = error.requestOptions.path;
          final isSessionCheck =
              path.contains('/auth/login') || path.contains('/auth/me');
          if (status == 401 && !isSessionCheck) {
            final token = await tokenStorage.readAccessToken();
            if (token != null && token.isNotEmpty) {
              sessionNotifier.notifyUnauthorized();
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio dio;
}
