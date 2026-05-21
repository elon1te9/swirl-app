import 'user_model.dart';

class AuthResponseModel {
  const AuthResponseModel({required this.accessToken, required this.user});

  final String accessToken;
  final UserModel user;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];

    return AuthResponseModel(
      accessToken: json['accessToken']?.toString() ?? '',
      user: UserModel.fromJson(
        userJson is Map ? Map<String, dynamic>.from(userJson) : {},
      ),
    );
  }
}
