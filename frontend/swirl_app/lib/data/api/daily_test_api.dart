import 'package:dio/dio.dart';

import '../../domain/models/daily_test_model.dart';
import 'api_paths.dart';

class DailyTestApi {
  DailyTestApi(this._dio);

  final Dio _dio;

  Future<DailyTestModel> getDailyTest() async {
    final response = await _dio.get(ApiPaths.dailyTest);
    return DailyTestModel.fromJson(_jsonMap(response.data));
  }

  Future<CompleteDailyTestResultModel> completeDailyTest({
    required List<DailyTestAnswerModel> answers,
  }) async {
    final response = await _dio.post(
      ApiPaths.completeDailyTest,
      data: {'answers': answers.map((answer) => answer.toJson()).toList()},
    );
    return CompleteDailyTestResultModel.fromJson(_jsonMap(response.data));
  }

  Map<String, dynamic> _jsonMap(Object? data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return {};
  }
}
