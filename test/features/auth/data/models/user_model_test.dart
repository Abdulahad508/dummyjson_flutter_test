import 'package:flutter_test/flutter_test.dart';
import 'package:dummyjson_flutter_test/features/auth/data/models/user_model.dart';

void main() {
  test('fromJson ignores token and password fields', () {
    final user = UserModel.fromJson({
      'id': 1,
      'username': 'emilys',
      'email': 'emily.johnson@x.dummyjson.com',
      'firstName': 'Emily',
      'lastName': 'Johnson',
      'image': 'https://dummyjson.com/icon/emilys/128',
      'accessToken': 'secret-token',
      'password': 'emilyspass',
    });

    expect(user.username, 'emilys');
    expect(user.toJson().containsKey('password'), isFalse);
    expect(user.toJson().containsKey('accessToken'), isFalse);
    expect(UserModel.fromJson(user.toJson()), user);
  });
}
