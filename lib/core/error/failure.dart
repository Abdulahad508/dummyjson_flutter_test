/// A user-facing failure that crossed a feature boundary.
///
/// Domain and presentation code branch on the subtype and show [message].
sealed class Failure {
  const Failure(this.message);

  final String message;
}

final class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Check your internet connection and try again.',
  ]);
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Please sign in again.']);
}
