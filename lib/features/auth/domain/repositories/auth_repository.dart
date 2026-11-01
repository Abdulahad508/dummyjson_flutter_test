import 'package:dummyjson_flutter_test/core/result/result.dart';
import 'package:dummyjson_flutter_test/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  /// Signs in and persists the access token in secure storage.
  Future<Result<User>> login({
    required String username,
    required String password,
  });

  /// Returns the current user when a saved token is still accepted.
  Future<Result<User>> restoreSession();

  /// Deletes the saved token and user snapshot.
  Future<void> logout();
}
