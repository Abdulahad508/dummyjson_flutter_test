/// Thrown when the platform secure store cannot complete an operation.
class StorageException implements Exception {
  const StorageException(this.message);

  final String message;
}

/// Persistence for the access token and a non-secret user snapshot.
abstract class TokenStorage {
  Future<String?> readAccessToken();

  Future<String?> readUserJson();

  Future<void> writeSession({
    required String accessToken,
    required String userJson,
  });

  Future<void> clear();
}
