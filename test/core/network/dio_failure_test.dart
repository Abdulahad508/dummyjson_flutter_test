import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummyjson_flutter_test/core/error/failure.dart';
import 'package:dummyjson_flutter_test/core/network/dio_failure.dart';

void main() {
  test('maps connection errors to a network failure', () {
    final failure = failureFromDio(
      DioException(
        requestOptions: RequestOptions(path: '/products'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(failure, isA<NetworkFailure>());
  });

  test('uses the server message for a rejected login', () {
    final failure = failureFromDio(
      DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 400,
          data: const {'message': 'Invalid credentials'},
        ),
      ),
    );

    expect(failure, isA<ServerFailure>());
    expect(failure.message, 'Invalid credentials');
  });

  test('maps 401 to an unauthorized failure', () {
    final failure = failureFromDio(
      DioException(
        requestOptions: RequestOptions(path: '/products'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/products'),
          statusCode: 401,
          data: const {'message': 'Token expired'},
        ),
      ),
    );

    expect(failure, isA<UnauthorizedFailure>());
    expect(failure.message, 'Token expired');
  });
}
