import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swirl_app/core/storage/token_storage.dart';
import 'package:swirl_app/data/api/profile_api.dart';
import 'package:swirl_app/domain/models/profile_model.dart';
import 'package:swirl_app/presentation/state/profile_provider.dart';

void main() {
  group('ProfileModel', () {
    test('parses profile response with section progress', () {
      final profile = ProfileModel.fromJson({
        'name': 'Vladimir',
        'avatarUrl': '/media/avatars/avatar_1.png',
        'currentStreak': 4,
        'bestStreak': 7,
        'learnedWordsCount': 45,
        'completedLevelsCount': 8,
        'sectionsProgress': [
          {'sectionId': 1, 'title': 'Food', 'progressPercent': 50},
        ],
      });

      expect(profile.name, 'Vladimir');
      expect(profile.avatarUrl, '/media/avatars/avatar_1.png');
      expect(profile.currentStreak, 4);
      expect(profile.bestStreak, 7);
      expect(profile.learnedWordsCount, 45);
      expect(profile.completedLevelsCount, 8);
      expect(profile.sectionsProgress, hasLength(1));
      expect(profile.sectionsProgress.first.sectionId, 1);
      expect(profile.sectionsProgress.first.title, 'Food');
      expect(profile.sectionsProgress.first.progressPercent, 50);
    });

    test('uses safe defaults for missing or null profile fields', () {
      final profile = ProfileModel.fromJson({
        'name': null,
        'avatarUrl': null,
        'currentStreak': null,
        'bestStreak': null,
        'learnedWordsCount': null,
        'completedLevelsCount': null,
        'sectionsProgress': null,
      });

      expect(profile.name, '');
      expect(profile.avatarUrl, '');
      expect(profile.currentStreak, 0);
      expect(profile.bestStreak, 0);
      expect(profile.learnedWordsCount, 0);
      expect(profile.completedLevelsCount, 0);
      expect(profile.sectionsProgress, isEmpty);
    });
  });

  group('ProfileController', () {
    test('loadProfile returns profile from api', () async {
      final expected = ProfileModel.fromJson({'name': 'Milena'});
      final controller = ProfileController(
        profileApi: _FakeProfileApi(expected),
        tokenStorage: _FakeTokenStorage(),
      );

      final profile = await controller.loadProfile();

      expect(profile.name, 'Milena');
    });

    test('logout deletes stored access token', () async {
      final storage = _FakeTokenStorage();
      final controller = ProfileController(
        profileApi: _FakeProfileApi(ProfileModel.fromJson({})),
        tokenStorage: storage,
      );

      await controller.logout();

      expect(storage.deleteWasCalled, isTrue);
    });
  });
}

class _FakeProfileApi extends ProfileApi {
  _FakeProfileApi(this.profile) : super(Dio());

  final ProfileModel profile;

  @override
  Future<ProfileModel> getProfile() async {
    return profile;
  }
}

class _FakeTokenStorage extends TokenStorage {
  bool deleteWasCalled = false;

  @override
  Future<void> deleteAccessToken() async {
    deleteWasCalled = true;
  }
}
