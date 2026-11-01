import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dummyjson_flutter_test/core/error/failure.dart';
import 'package:dummyjson_flutter_test/core/result/result.dart';
import 'package:dummyjson_flutter_test/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:dummyjson_flutter_test/features/auth/data/models/user_model.dart';
import 'package:dummyjson_flutter_test/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:dummyjson_flutter_test/features/auth/domain/entities/user.dart';

import '../../../../support/memory_token_storage.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late MockAuthRemoteDataSource remote;
  late MemoryTokenStorage storage;
  late AuthRepositoryImpl repository;

  const user = UserModel(
    id: 1,
    username: 'emilys',
    email: 'emily.johnson@x.dummyjson.com',
    firstName: 'Emily',
    lastName: 'Johnson',
    image: 'img',
  );

  setUp(() {
    remote = MockAuthRemoteDataSource();
    storage = MemoryTokenStorage();
    repository = AuthRepositoryImpl(remote: remote, storage: storage);
  });

  test('login stores the token and a profile without the password', () async {
    when(
      () => remote.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => const AuthSession(accessToken: 'token-123', user: user),
    );

    final result = await repository.login(
      username: 'emilys',
      password: 'emilyspass',
    );

    expect(result, isA<Success<User>>());
    expect(storage.accessToken, 'token-123');
    final saved = jsonDecode(storage.userJson!) as Map<String, dynamic>;
    expect(saved['username'], 'emilys');
    expect(saved.containsKey('password'), isFalse);
    expect(saved.containsKey('accessToken'), isFalse);
  });

  test('login does not store a token when credentials are rejected', () async {
    when(
      () => remote.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 400,
          data: const {'message': 'Invalid credentials'},
        ),
      ),
    );

    final result = await repository.login(
      username: 'emilys',
      password: 'wrong',
    );

    expect(result, isA<ResultFailure<User>>());
    expect(
      (result as ResultFailure<User>).failure.message,
      'Invalid credentials',
    );
    expect(storage.accessToken, isNull);
  });

  test('restore without a token asks the user to sign in', () async {
    final result = await repository.restoreSession();

    expect(result, isA<ResultFailure<User>>());
    expect((result as ResultFailure<User>).failure, isA<UnauthorizedFailure>());
    verifyNever(() => remote.getCurrentUser());
  });

  test('a rejected token is cleared', () async {
    storage.accessToken = 'stale';
    storage.userJson = jsonEncode(user.toJson());
    when(() => remote.getCurrentUser()).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/auth/me'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/auth/me'),
          statusCode: 401,
          data: const {'message': 'Token expired'},
        ),
      ),
    );

    final result = await repository.restoreSession();

    expect((result as ResultFailure<User>).failure, isA<UnauthorizedFailure>());
    expect(storage.accessToken, isNull);
    expect(storage.userJson, isNull);
  });

  test('an offline restore uses the cached profile', () async {
    storage.accessToken = 'token-123';
    storage.userJson = jsonEncode(user.toJson());
    when(() => remote.getCurrentUser()).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/auth/me'),
        type: DioExceptionType.connectionError,
      ),
    );

    final result = await repository.restoreSession();

    expect((result as Success<User>).value.username, 'emilys');
    expect(storage.accessToken, 'token-123');
  });

  test('logout clears the saved session', () async {
    storage.accessToken = 'token-123';
    storage.userJson = '{}';

    await repository.logout();

    expect(storage.accessToken, isNull);
    expect(storage.userJson, isNull);
  });
}
