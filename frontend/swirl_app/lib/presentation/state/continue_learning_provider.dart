import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
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
      return loadContinueLearningFromSections(sections);
    } on DioException {
      return null;
    }
  }

  Future<List<ContinueSectionModel>> loadSections() async {
    try {
      return await api.getSections();
    } on DioException {
      return [];
    }
  }

  Future<ContinueLearningModel?> loadContinueLearningFromSections(
    List<ContinueSectionModel> sections,
  ) async {
    final startedSections =
        sections.where((section) => section.completedLevels > 0).toList()
          ..sort((a, b) => b.completedLevels.compareTo(a.completedLevels));

    for (final section in startedSections) {
      final levels = await api.getLevels(section.id);
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

      return ContinueLearningModel(
        section: section,
        nextLevel: availableLevels.first,
        completedLevels: completedLevels.length,
        totalLevels: levels.length,
      );
    }

    return null;
  }
}
