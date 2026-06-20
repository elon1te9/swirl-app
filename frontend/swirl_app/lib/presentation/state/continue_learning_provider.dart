import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/api_error_utils.dart';
import '../../data/api/continue_learning_api.dart';
import '../../domain/models/continue_learning_model.dart';

final continueLearningApiProvider = Provider<ContinueLearningApi>((ref) {
  return ContinueLearningApi(ref.watch(dioProvider));
});

final continueLearningControllerProvider = Provider<ContinueLearningController>(
  (ref) {
    return ContinueLearningController(
      api: ref.watch(continueLearningApiProvider),
    );
  },
);

class ContinueLearningController {
  ContinueLearningController({required this.api});

  final ContinueLearningApi api;

  Future<ContinueLearningModel?> loadContinueLearning() async {
    try {
      final sections = await api.getSections();
      return await loadContinueLearningFromSections(sections);
    } on DioException catch (error) {
      if (isUnauthorizedError(error)) {
        throw const ContinueLearningUnauthorizedException();
      }
      return null;
    }
  }

  Future<List<ContinueSectionModel>> loadSections() async {
    try {
      return await api.getSections();
    } on DioException catch (error) {
      throw _mapContinueLearningError(error);
    }
  }

  Future<ContinueLearningModel?> loadContinueLearningFromSections(
    List<ContinueSectionModel> sections,
  ) async {
    final startedSections = sections
        .where((section) => section.completedLevels > 0)
        .toList();

    final candidates = <_ContinueLearningCandidate>[];
    for (final section in startedSections) {
      final levels = await _loadLevels(section.id);
      final completedLevels = levels
          .where((level) => level.status == 'completed')
          .toList();

      if (completedLevels.isEmpty) {
        continue;
      }

      final availableLevels =
          levels.where((level) => level.status == 'available').toList()
            ..sort((a, b) => a.levelNumber.compareTo(b.levelNumber));

      if (availableLevels.isEmpty) {
        continue;
      }

      final latestCompletedAt = completedLevels
          .map((level) => level.completedAt)
          .whereType<DateTime>()
          .fold<DateTime?>(null, (latest, completedAt) {
            if (latest == null || completedAt.isAfter(latest)) {
              return completedAt;
            }

            return latest;
          });

      candidates.add(
        _ContinueLearningCandidate(
          model: ContinueLearningModel(
            section: section,
            nextLevel: availableLevels.first,
            completedLevels: completedLevels.length,
            totalLevels: levels.length,
          ),
          latestCompletedAt: latestCompletedAt,
        ),
      );
    }

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort((a, b) {
      final latestComparison = _compareNullableDateTimeDesc(
        a.latestCompletedAt,
        b.latestCompletedAt,
      );
      if (latestComparison != 0) {
        return latestComparison;
      }

      return b.model.completedLevels.compareTo(a.model.completedLevels);
    });

    return candidates.first.model;
  }

  Future<List<ContinueLevelModel>> _loadLevels(int sectionId) async {
    try {
      return await api.getLevels(sectionId);
    } on DioException catch (error) {
      throw _mapContinueLearningError(error);
    }
  }
}

class _ContinueLearningCandidate {
  const _ContinueLearningCandidate({
    required this.model,
    required this.latestCompletedAt,
  });

  final ContinueLearningModel model;
  final DateTime? latestCompletedAt;
}

int _compareNullableDateTimeDesc(DateTime? first, DateTime? second) {
  if (first == null && second == null) {
    return 0;
  }

  if (first == null) {
    return 1;
  }

  if (second == null) {
    return -1;
  }

  return second.compareTo(first);
}

class ContinueLearningUnauthorizedException implements Exception {
  const ContinueLearningUnauthorizedException();

  @override
  String toString() {
    return 'Нужно войти снова.';
  }
}

Exception _mapContinueLearningError(DioException error) {
  if (isUnauthorizedError(error)) {
    return const ContinueLearningUnauthorizedException();
  }

  return Exception(
    friendlyDioMessage(
      error,
      fallback: 'Не удалось загрузить обучение. Попробуйте еще раз.',
    ),
  );
}
