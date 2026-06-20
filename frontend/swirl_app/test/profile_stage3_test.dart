import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swirl_app/core/storage/token_storage.dart';
import 'package:swirl_app/data/api/continue_learning_api.dart';
import 'package:swirl_app/data/api/profile_api.dart';
import 'package:swirl_app/domain/models/continue_learning_model.dart';
import 'package:swirl_app/domain/models/profile_model.dart';
import 'package:swirl_app/presentation/state/continue_learning_provider.dart';
import 'package:swirl_app/presentation/state/profile_provider.dart';

void main() {
  group('ProfileModel', () {
    test('parses profile response with section progress', () {
      final profile = ProfileModel.fromJson({
        'name': 'Vladimir',
        'avatarUrl': '/media/avatars/avatar_1.png',
        'currentStreak': 4,
        'bestStreak': 7,
        'lastActivityDate': '2026-06-18',
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
      expect(profile.lastActivityDate, DateTime(2026, 6, 18));
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
        'lastActivityDate': null,
        'learnedWordsCount': null,
        'completedLevelsCount': null,
        'sectionsProgress': null,
      });

      expect(profile.name, '');
      expect(profile.avatarUrl, '');
      expect(profile.currentStreak, 0);
      expect(profile.bestStreak, 0);
      expect(profile.lastActivityDate, isNull);
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

  group('ContinueLearningController', () {
    test('uses section with latest completed level', () async {
      final controller = ContinueLearningController(
        api: _FakeContinueLearningApi(
          levelsBySectionId: {
            1: [
              _level(
                id: 11,
                sectionId: 1,
                levelNumber: 1,
                status: 'completed',
                completedAt: DateTime(2026, 6, 17, 10),
              ),
              _level(
                id: 12,
                sectionId: 1,
                levelNumber: 2,
                status: 'completed',
                completedAt: DateTime(2026, 6, 18, 10),
              ),
              _level(id: 13, sectionId: 1, levelNumber: 3, status: 'available'),
            ],
            4: [
              _level(
                id: 41,
                sectionId: 4,
                levelNumber: 1,
                status: 'completed',
                completedAt: DateTime(2026, 6, 19, 10),
              ),
              _level(id: 42, sectionId: 4, levelNumber: 2, status: 'available'),
            ],
          },
        ),
      );

      final result = await controller.loadContinueLearningFromSections([
        _section(id: 1, title: 'Food', completedLevels: 2),
        _section(id: 4, title: 'Wardrobe', completedLevels: 1),
      ]);

      expect(result?.section.title, 'Wardrobe');
      expect(result?.nextLevel.levelNumber, 2);
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

class _FakeContinueLearningApi extends ContinueLearningApi {
  _FakeContinueLearningApi({required this.levelsBySectionId}) : super(Dio());

  final Map<int, List<ContinueLevelModel>> levelsBySectionId;

  @override
  Future<List<ContinueLevelModel>> getLevels(int sectionId) async {
    return levelsBySectionId[sectionId] ?? const [];
  }
}

ContinueSectionModel _section({
  required int id,
  required String title,
  required int completedLevels,
}) {
  return ContinueSectionModel(
    id: id,
    title: title,
    imageUrl: '',
    progressPercent: 0,
    completedLevels: completedLevels,
    totalLevels: 6,
  );
}

ContinueLevelModel _level({
  required int id,
  required int sectionId,
  required int levelNumber,
  required String status,
  DateTime? completedAt,
}) {
  return ContinueLevelModel(
    id: id,
    sectionId: sectionId,
    title: '',
    levelNumber: levelNumber,
    status: status,
    isFinalTest: false,
    completedAt: completedAt,
  );
}
