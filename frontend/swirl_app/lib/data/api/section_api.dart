import 'package:dio/dio.dart';

import '../../domain/models/level_model.dart';
import '../../domain/models/section_model.dart';
import 'api_paths.dart';

class SectionApi {
  SectionApi(this._dio);

  final Dio _dio;

  Future<List<SectionModel>> getSections() async {
    final response = await _dio.get(ApiPaths.sections);
    final data = response.data;

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map((item) => SectionModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<SectionModel> getSection(int sectionId) async {
    final response = await _dio.get(ApiPaths.sectionDetails(sectionId));
    return SectionModel.fromJson(_jsonMap(response.data));
  }

  Future<List<LevelModel>> getLevels(int sectionId) async {
    final response = await _dio.get(ApiPaths.sectionLevels(sectionId));
    final data = response.data;

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map>()
        .map((item) => LevelModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Map<String, dynamic> _jsonMap(Object? data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return {};
  }
}
