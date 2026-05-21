import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swirl_app/app/app.dart';
import 'package:swirl_app/core/storage/token_storage.dart';
import 'package:swirl_app/data/api/auth_api.dart';

void main() {
  testWidgets('opens first screen once when there is no saved token', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(FakeTokenStorage()),
          authApiProvider.overrideWithValue(FakeAuthApi()),
        ],
        child: const SwirlApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('swirl.'), findsOneWidget);
    expect(find.text('Войти'), findsOneWidget);
  });
}

class FakeTokenStorage extends TokenStorage {
  @override
  Future<String?> readAccessToken() async {
    return null;
  }
}

class FakeAuthApi extends AuthApi {
  FakeAuthApi() : super(Dio());
}
