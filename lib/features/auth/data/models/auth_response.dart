import '../../domain/models/auth_user.dart';

final class AuthResponse {
  const AuthResponse({required this.accessToken, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: _requiredString(json, 'access_token'),
      user: AuthUserJson.fromJson(_requiredMap(json, 'user')),
    );
  }

  final String accessToken;
  final AuthUser user;
}

abstract final class AuthUserJson {
  static AuthUser fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: _requiredString(json, 'id'),
      email: _requiredString(json, 'email'),
      nickname: _nullableString(json, 'nickname'),
      avatarUrl: _nullableString(json, 'avatarUrl'),
    );
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  throw FormatException('Expected a non-empty string for "$key".');
}

String? _nullableString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null || value is String) {
    return value as String?;
  }
  throw FormatException('Expected a string or null for "$key".');
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is Map<String, dynamic>) {
    return value;
  }
  throw FormatException('Expected an object for "$key".');
}
