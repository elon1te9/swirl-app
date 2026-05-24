import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/token_storage.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(tokenStorage: tokenStorage);
});

final dioProvider = Provider<Dio>((ref) {
  return ref.watch(apiClientProvider).dio;
});

class ApiClient {
  ApiClient({required TokenStorage tokenStorage})
    : dio = Dio(
        BaseOptions(
          baseUrl: apiBaseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await tokenStorage.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await tokenStorage.deleteAccessToken();
          }
          handler.next(error);
        },
      ),
    );
  }

  static const backendOrigin ='http://10.0.2.2:5122';

  static const apiBaseUrl = '$backendOrigin/api';

  final Dio dio;
}
