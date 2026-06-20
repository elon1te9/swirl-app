import 'package:dio/dio.dart';

String apiErrorCode(Object? data) {
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

bool isUnauthorizedError(DioException error) {
  return error.response?.statusCode == 401;
}

bool isNetworkError(DioException error) {
  return error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.connectionError;
}

String friendlyDioMessage(
  DioException error, {
  String fallback = 'Что-то пошло не так. Попробуйте еще раз.',
}) {
  final code = apiErrorCode(error.response?.data);
  switch (code) {
    case 'validation_error':
      return 'Проверьте данные и попробуйте еще раз.';
    case 'invalid_credentials':
      return 'Неверная почта или пароль.';
    case 'email_already_exists':
      return 'Пользователь с такой почтой уже есть.';
    case 'unauthorized':
      return 'Нужно войти снова.';
    case 'not_found':
      return 'Не удалось найти данные.';
    case 'level_locked':
      return 'Этот уровень пока закрыт.';
    case 'not_enough_learned_words':
      return 'Изучите больше слов, чтобы открыть ежедневный тест.';
    case 'daily_test_already_completed':
      return 'Ежедневный тест уже пройден сегодня.';
    case 'internal_error':
      return 'Сервер не справился. Попробуйте еще раз.';
  }

  if (isNetworkError(error)) {
    return 'Не удалось подключиться к серверу. Проверьте интернет и попробуйте еще раз.';
  }

  final statusCode = error.response?.statusCode;
  if (statusCode == 400) {
    return 'Проверьте данные и попробуйте еще раз.';
  }

  if (statusCode == 404) {
    return 'Не удалось найти данные.';
  }

  if (statusCode != null && statusCode >= 500) {
    return 'Сервер не справился. Попробуйте еще раз.';
  }

  return fallback;
}

String friendlyErrorMessage(
  Object error, {
  String fallback = 'Что-то пошло не так. Попробуйте еще раз.',
}) {
  if (error is DioException) {
    return friendlyDioMessage(error, fallback: fallback);
  }

  var message = error.toString().replaceFirst('Exception: ', '').trim();
  if (message.isEmpty ||
      message.contains('DioException') ||
      message.contains('SocketException') ||
      message.contains('FormatException') ||
      message.contains('type ') ||
      message.contains('Null check operator')) {
    message = fallback;
  }

  return message;
}
