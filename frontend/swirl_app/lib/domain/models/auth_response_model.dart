import 'user_model.dart';

class AuthResponseModel {
  const AuthResponseModel({required this.accessToken, required this.user});

  final String accessToken;
  final UserModel user;

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> userJson = json['user'];
    final user = UserModel.fromJson(userJson);

    return AuthResponseModel(
      accessToken: json['accessToken'],
      user: user,
    );
  }
}
