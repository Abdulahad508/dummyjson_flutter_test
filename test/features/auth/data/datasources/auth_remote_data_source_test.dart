import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dummyjson_flutter_test/features/auth/data/datasources/auth_remote_data_source.dart';

void main() {
  test('login posts credentials and keeps the access token', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, '/auth/login');
          expect(options.data, {
            'username': 'emilys',
            'password': 'emilyspass',
          });
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'id': 1,
                'username': 'emilys',
                'email': 'emily.johnson@x.dummyjson.com',
                'firstName': 'Emily',
                'lastName': 'Johnson',
                'image': 'img',
                'accessToken': 'token-123',
                'password': 'emilyspass',
              },
            ),
          );
        },
      ),
    );

    final session = await AuthRemoteDataSourceImpl(dio)
        .login(username: 'emilys', password: 'emilyspass');

    expect(session.accessToken, 'token-123');
    expect(session.user.toJson().containsKey('password'), isFalse);
  });
}
