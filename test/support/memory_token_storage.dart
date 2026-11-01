import 'package:dummyjson_flutter_test/core/storage/token_storage.dart';

class MemoryTokenStorage implements TokenStorage {
  String? accessToken;
  String? userJson;

  @override
  Future<void> clear() async {
    accessToken = null;
    userJson = null;
  }

  @override
  Future<String?> readAccessToken() async => accessToken;

  @override
  Future<String?> readUserJson() async => userJson;

  @override
  Future<void> writeSession({
    required String accessToken,
    required String userJson,
  }) async {
    this.accessToken = accessToken;
    this.userJson = userJson;
  }
}
