import 'dart:async';

/// Broadcasts when an authenticated request is rejected.
///
/// The API client publishes. The auth bloc listens and clears the session.
/// A broadcast stream drops events nobody is listening for, so the
/// subscription is attached when the bloc is created, before the first call.
class SessionNotifier {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get onUnauthorized => _controller.stream;

  void notifyUnauthorized() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  Future<void> dispose() => _controller.close();
}
