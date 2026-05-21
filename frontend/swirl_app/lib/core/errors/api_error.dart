class ApiError {
  const ApiError({required this.code, required this.message, this.details});

  static const fallbackMessage = 'Что-то пошло не так. Попробуйте еще раз.';

  final String code;
  final String message;
  final Map<String, dynamic>? details;

  factory ApiError.fromJson(Map<String, dynamic> json) {
    final error = json['error'];
    if (error is Map) {
      final detailsJson = error['details'];

      return ApiError(
        code: error['code']?.toString() ?? 'unknown_error',
        message: error['message']?.toString() ?? fallbackMessage,
        details: detailsJson is Map
            ? Map<String, dynamic>.from(detailsJson)
            : null,
      );
    }

    return const ApiError(code: 'unknown_error', message: fallbackMessage);
  }
}
