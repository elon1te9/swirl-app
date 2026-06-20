import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/api_error_utils.dart';
import '../../data/api/daily_test_api.dart';
import '../../domain/models/daily_test_model.dart';

final dailyTestApiProvider = Provider<DailyTestApi>((ref) {
  return DailyTestApi(ref.watch(dioProvider));
});

final dailyTestControllerProvider = Provider<DailyTestController>((ref) {
  return DailyTestController(dailyTestApi: ref.watch(dailyTestApiProvider));
});

class DailyTestController {
  const DailyTestController({required this.dailyTestApi});

  final DailyTestApi dailyTestApi;

  Future<DailyTestModel> loadDailyTest() async {
    try {
      return await dailyTestApi.getDailyTest();
    } on DioException catch (error) {
      throw _mapDailyTestError(error);
    }
  }

  Future<CompleteDailyTestResultModel> completeDailyTest({
    required List<DailyTestAnswerModel> answers,
  }) async {
    try {
      return await dailyTestApi.completeDailyTest(answers: answers);
    } on DioException catch (error) {
      throw _mapDailyTestError(error);
    }
  }
}

class DailyTestUnauthorizedException implements Exception {
  const DailyTestUnauthorizedException();

  @override
  String toString() {
    return 'Нужно войти снова.';
  }
}

class DailyTestUnavailableException implements Exception {
  const DailyTestUnavailableException();

  @override
  String toString() {
    return 'Изучите больше слов, чтобы открыть ежедневный тест.';
  }
}

class DailyTestAlreadyCompletedException implements Exception {
  const DailyTestAlreadyCompletedException();

  @override
  String toString() {
    return 'Ежедневный тест уже пройден сегодня.';
  }
}

Exception _mapDailyTestError(DioException error) {
  if (isUnauthorizedError(error)) {
    return const DailyTestUnauthorizedException();
  }

  final code = apiErrorCode(error.response?.data);
  if (code == 'not_enough_learned_words') {
    return const DailyTestUnavailableException();
  }

  if (code == 'daily_test_already_completed') {
    return const DailyTestAlreadyCompletedException();
  }

  return Exception(
    friendlyDioMessage(
      error,
      fallback: 'Не удалось загрузить тест. Попробуйте еще раз.',
    ),
  );
}
