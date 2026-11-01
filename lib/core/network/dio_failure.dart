import 'package:dio/dio.dart';
import 'package:dummyjson_flutter_test/core/error/failure.dart';

/// Maps a [DioException] to a domain [Failure] with a message safe to show.
Failure failureFromDio(DioException exception) {
  final isOffline =
      exception.type == DioExceptionType.connectionTimeout ||
      exception.type == DioExceptionType.sendTimeout ||
      exception.type == DioExceptionType.receiveTimeout ||
      exception.type == DioExceptionType.connectionError ||
      (exception.type == DioExceptionType.unknown &&
          exception.response == null);

  if (isOffline) {
    return const NetworkFailure();
  }

  final status = exception.response?.statusCode;
  final message = _messageFromBody(exception.response?.data);

  if (status == 401) {
    return UnauthorizedFailure(
      message ?? 'Your session has expired. Please sign in again.',
    );
  }
  if (status == 404) {
    return ServerFailure(message ?? 'The requested item was not found.');
  }
  return ServerFailure(message ?? 'Something went wrong. Please try again.');
}

String? _messageFromBody(Object? data) {
  if (data is Map && data['message'] is String) {
    final message = (data['message'] as String).trim();
    if (message.isNotEmpty) {
      return message;
    }
  }
  return null;
}
