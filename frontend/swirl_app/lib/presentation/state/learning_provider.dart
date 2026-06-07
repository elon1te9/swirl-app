import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../data/api/level_api.dart';
import '../../data/api/section_api.dart';
import '../../domain/models/level_model.dart';
import '../../domain/models/section_model.dart';
import '../../domain/models/word_model.dart';

final sectionApiProvider = Provider<SectionApi>((ref) {
  return SectionApi(ref.watch(dioProvider));
});

final levelApiProvider = Provider<LevelApi>((ref) {
  return LevelApi(ref.watch(dioProvider));
});

final learningControllerProvider = Provider<LearningController>((ref) {
  return LearningController(
    sectionApi: ref.watch(sectionApiProvider),
    levelApi: ref.watch(levelApiProvider),
  );
});

class LearningController {
  const LearningController({required this.sectionApi, required this.levelApi});

  final SectionApi sectionApi;
  final LevelApi levelApi;

  Future<List<SectionModel>> loadSections() async {
    try {
      return await sectionApi.getSections();
    } on DioException catch (error) {
      throw _mapLearningError(error);
    }
  }

  Future<SectionModel> loadSection(int sectionId) async {
    try {
      return await sectionApi.getSection(sectionId);
    } on DioException catch (error) {
      throw _mapLearningError(error);
    }
  }

  Future<List<LevelModel>> loadLevels(int sectionId) async {
    try {
      return await sectionApi.getLevels(sectionId);
    } on DioException catch (error) {
      throw _mapLearningError(error);
    }
  }

  Future<LevelDetailsModel> loadLevelDetails(int levelId) async {
    try {
      return await levelApi.getLevelDetails(levelId);
    } on DioException catch (error) {
      throw _mapLearningError(error);
    }
  }

  Future<List<WordModel>> loadLevelWords(int levelId) async {
    try {
      return await levelApi.getLevelWords(levelId);
    } on DioException catch (error) {
      throw _mapLearningError(error);
    }
  }

  Future<void> markLevelWordsLearned(
    int levelId, {
    required List<int> wordIds,
  }) async {
    try {
      await levelApi.markLevelWordsLearned(levelId, wordIds: wordIds);
    } on DioException catch (error) {
      throw _mapLearningError(error);
    }
  }
}

class LearningUnauthorizedException implements Exception {
  const LearningUnauthorizedException();

  @override
  String toString() {
    return 'Нужно войти снова.';
  }
}

Exception _mapLearningError(DioException error) {
  if (error.response?.statusCode == 401) {
    return const LearningUnauthorizedException();
  }

  final code = _errorCode(error.response?.data);
  if (code == 'level_locked') {
    return Exception('Этот уровень пока закрыт.');
  }

  if (error.response?.statusCode == 404) {
    return Exception('Не удалось найти данные. Попробуйте вернуться назад.');
  }

  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.connectionError) {
    return Exception(
      'Не удалось подключиться к серверу. Проверьте интернет и попробуйте еще раз.',
    );
  }

  return Exception('Не удалось загрузить данные. Попробуйте еще раз.');
}

String _errorCode(Object? data) {
  if (data is! Map) {
    return '';
  }

  final error = data['error'];
  if (error is! Map) {
    return '';
  }

  final code = error['code'];
  return code is String ? code : '';
}
