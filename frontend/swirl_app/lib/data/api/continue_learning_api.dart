import 'package:dio/dio.dart';

import '../../domain/models/continue_learning_model.dart';
import 'api_paths.dart';

class ContinueLearningApi {
  ContinueLearningApi(this._dio);

  final Dio _dio;

  Future<List<ContinueSectionModel>> getSections() async {
    final response = await _dio.get(ApiPaths.sections);
    final data = response.data;

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map(
          (item) =>
              ContinueSectionModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<List<ContinueLevelModel>> getLevels(int sectionId) async {
    final response = await _dio.get(ApiPaths.sectionLevels(sectionId));
    final data = response.data;

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map(
          (item) =>
              ContinueLevelModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }
}
