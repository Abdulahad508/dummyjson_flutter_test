import 'dart:async';

import 'package:flutter/foundation.dart';

/// Notifies [GoRouter] when a bloc stream emits, so redirects re-run.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) {
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  late final StreamSubscription<dynamic> _subscription;
  var _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _subscription.cancel();
    super.dispose();
  }
}
