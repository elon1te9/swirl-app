import 'package:flutter_test/flutter_test.dart';
import 'package:swirl_app/domain/models/auth_response_model.dart';
import 'package:swirl_app/domain/models/avatar_model.dart';
import 'package:swirl_app/domain/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('reads user fields from json', () {
      final user = UserModel.fromJson({
        'id': 'user-id',
        'name': 'Vladimir',
        'email': 'user@example.com',
        'avatarUrl': '/media/avatars/avatar_1.png',
      });

      expect(user.id, 'user-id');
      expect(user.name, 'Vladimir');
      expect(user.email, 'user@example.com');
      expect(user.avatarUrl, '/media/avatars/avatar_1.png');
    });

    test('allows missing avatar url', () {
      final user = UserModel.fromJson({
        'id': 'user-id',
        'name': 'Vladimir',
        'email': 'user@example.com',
        'avatarUrl': null,
      });

      expect(user.avatarUrl, isNull);
    });
  });

  group('AuthResponseModel', () {
    test('reads token and nested user from json', () {
      final response = AuthResponseModel.fromJson({
        'accessToken': 'jwt-token',
        'user': {
          'id': 'user-id',
          'name': 'Vladimir',
          'email': 'user@example.com',
          'avatarUrl': '/media/avatars/avatar_1.png',
        },
      });

      expect(response.accessToken, 'jwt-token');
      expect(response.user.name, 'Vladimir');
      expect(response.user.email, 'user@example.com');
    });
  });

  group('AvatarModel', () {
    test('reads avatar fields from json', () {
      final avatar = AvatarModel.fromJson({
        'id': 1,
        'name': 'Avatar 1',
        'imageUrl': '/media/avatars/avatar_1.png',
      });

      expect(avatar.id, 1);
      expect(avatar.name, 'Avatar 1');
      expect(avatar.imageUrl, '/media/avatars/avatar_1.png');
    });
  });
}
