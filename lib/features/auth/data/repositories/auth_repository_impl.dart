import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dummyjson_flutter_test/core/error/failure.dart';
import 'package:dummyjson_flutter_test/core/network/dio_failure.dart';
import 'package:dummyjson_flutter_test/core/network/guard_request.dart';
import 'package:dummyjson_flutter_test/core/result/result.dart';
import 'package:dummyjson_flutter_test/core/storage/token_storage.dart';
import 'package:dummyjson_flutter_test/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:dummyjson_flutter_test/features/auth/data/models/user_model.dart';
import 'package:dummyjson_flutter_test/features/auth/domain/entities/user.dart';
import 'package:dummyjson_flutter_test/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required this._remote, required this._storage});

  final AuthRemoteDataSource _remote;
  final TokenStorage _storage;

  @override
  Future<Result<User>> login({
    required String username,
    required String password,
  }) {
    return guardRequest(() async {
      final session = await _remote.login(
        username: username,
        password: password,
      );
      await _storage.writeSession(
        accessToken: session.accessToken,
        userJson: jsonEncode(session.user.toJson()),
      );
      return session.user;
    });
  }

  @override
  Future<Result<User>> restoreSession() async {
    final token = await _storage.readAccessToken();
    if (token == null || token.isEmpty) {
      return const ResultFailure(UnauthorizedFailure('Sign in to continue.'));
    }

    try {
      final user = await _remote.getCurrentUser();
      try {
        await _storage.writeSession(
          accessToken: token,
          userJson: jsonEncode(user.toJson()),
        );
      } on StorageException {
        // The existing token is enough to stay signed in for this launch.
      }
      return Success(user);
    } on DioException catch (error) {
      final failure = failureFromDio(error);
      if (failure is UnauthorizedFailure) {
        await _storage.clear();
        return ResultFailure(failure);
      }
      final cached = await _readCachedUser();
      if (cached != null) {
        return Success(cached);
      }
      return ResultFailure(failure);
    } on FormatException catch (error) {
      return ResultFailure(ServerFailure(error.message));
    } catch (_) {
      final cached = await _readCachedUser();
      if (cached != null) {
        return Success(cached);
      }
      return const ResultFailure(
        ServerFailure('Something went wrong. Please try again.'),
      );
    }
  }

  @override
  Future<void> logout() => _storage.clear();

  Future<User?> _readCachedUser() async {
    final raw = await _storage.readUserJson();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      return UserModel.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }
}
