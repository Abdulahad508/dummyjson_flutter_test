import 'package:dio/dio.dart';
import 'package:dummyjson_flutter_test/core/network/json_map.dart';
import 'package:dummyjson_flutter_test/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthSession> login({
    required String username,
    required String password,
  });

  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final response = await _dio.post<dynamic>(
      '/auth/login',
      data: <String, dynamic>{'username': username, 'password': password},
    );
    final data = asJsonMap(response.data);
    final token = data['accessToken'];
    if (token is! String || token.isEmpty) {
      throw const FormatException(
        'Login response did not include an access token.',
      );
    }
    return AuthSession(accessToken: token, user: UserModel.fromJson(data));
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final response = await _dio.get<dynamic>('/auth/me');
    return UserModel.fromJson(asJsonMap(response.data));
  }
}
