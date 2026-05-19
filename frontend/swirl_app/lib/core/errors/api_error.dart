class ApiError {
  const ApiError({required this.code, required this.message, this.details});

  final String code;
  final String message;
  final Map<String, dynamic>? details;

  factory ApiError.fromJson(Map<String, dynamic> json) {
    final error = json['error'];
    if (error is Map<String, dynamic>) {
      return ApiError(
        code: error['code']?.toString() ?? 'unknown_error',
        message: error['message']?.toString() ?? 'Something went wrong',
        details: error['details'] is Map<String, dynamic>
            ? error['details'] as Map<String, dynamic>
            : null,
      );
    }

    return const ApiError(
      code: 'unknown_error',
      message: 'Something went wrong',
    );
  }
}
