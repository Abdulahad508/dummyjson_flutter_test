import 'package:dummyjson_flutter_test/core/error/failure.dart';

/// The outcome of a use case. Failures stay typed instead of thrown.
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

final class ResultFailure<T> extends Result<T> {
  const ResultFailure(this.failure);

  final Failure failure;
}
