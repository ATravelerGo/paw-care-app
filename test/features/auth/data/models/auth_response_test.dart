import 'package:flutter_test/flutter_test.dart';
import 'package:paw_care_app/features/auth/data/models/auth_response.dart';

void main() {
  test('maps the server auth response into client models', () {
    final response = AuthResponse.fromJson({
      'access_token': 'access-token',
      'user': {
        'id': 'user-id',
        'email': 'user@example.com',
        'nickname': '小陈',
        'avatarUrl': null,
      },
    });

    expect(response.accessToken, 'access-token');
    expect(response.user.id, 'user-id');
    expect(response.user.email, 'user@example.com');
    expect(response.user.nickname, '小陈');
    expect(response.user.avatarUrl, isNull);
  });

  test('rejects an auth response without a token', () {
    expect(
      () => AuthResponse.fromJson({
        'user': {
          'id': 'user-id',
          'email': 'user@example.com',
          'nickname': null,
          'avatarUrl': null,
        },
      }),
      throwsFormatException,
    );
  });
}
