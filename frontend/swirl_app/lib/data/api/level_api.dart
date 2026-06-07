import 'package:dio/dio.dart';

import '../../domain/models/level_model.dart';
import '../../domain/models/word_model.dart';
import 'api_paths.dart';

class LevelApi {
  LevelApi(this._dio);

  final Dio _dio;

  Future<LevelDetailsModel> getLevelDetails(int levelId) async {
    final response = await _dio.get(ApiPaths.levelDetails(levelId));
    return LevelDetailsModel.fromJson(_jsonMap(response.data));
  }

  Future<List<WordModel>> getLevelWords(int levelId) async {
    final response = await _dio.get(ApiPaths.levelWords(levelId));
    return _jsonList(
      response.data,
    ).map((item) => WordModel.fromJson(item)).toList();
  }

  Future<void> markLevelWordsLearned(
    int levelId, {
    required List<int> wordIds,
  }) async {
    await _dio.post(
      ApiPaths.markLevelWordsLearned(levelId),
      data: {'wordIds': wordIds},
    );
  }

  Map<String, dynamic> _jsonMap(Object? data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return {};
  }

  List<Map<String, dynamic>> _jsonList(Object? data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return const [];
  }
}
