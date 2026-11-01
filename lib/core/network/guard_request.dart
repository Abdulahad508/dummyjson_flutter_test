import 'package:dio/dio.dart';
import 'package:dummyjson_flutter_test/core/error/failure.dart';
import 'package:dummyjson_flutter_test/core/network/dio_failure.dart';
import 'package:dummyjson_flutter_test/core/result/result.dart';
import 'package:dummyjson_flutter_test/core/storage/token_storage.dart';

/// Runs [action] and converts thrown transport errors into a [Result].
Future<Result<T>> guardRequest<T>(Future<T> Function() action) async {
  try {
    return Success(await action());
  } on DioException catch (error) {
    return ResultFailure(failureFromDio(error));
  } on StorageException catch (error) {
    return ResultFailure(ServerFailure(error.message));
  } on FormatException catch (error) {
    return ResultFailure(ServerFailure(error.message));
  } catch (_) {
    return const ResultFailure(
      ServerFailure('Something went wrong. Please try again.'),
    );
  }
}
