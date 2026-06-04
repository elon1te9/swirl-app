import 'package:dio/dio.dart';

import '../../domain/models/level_model.dart';
import 'api_paths.dart';

class LevelApi {
  LevelApi(this._dio);

  final Dio _dio;

  Future<LevelDetailsModel> getLevelDetails(int levelId) async {
    final response = await _dio.get(ApiPaths.levelDetails(levelId));
    return LevelDetailsModel.fromJson(_jsonMap(response.data));
  }

  Map<String, dynamic> _jsonMap(Object? data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return {};
  }
}
