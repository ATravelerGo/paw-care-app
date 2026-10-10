final class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.nickname,
    required this.avatarUrl,
  });

  final String id;
  final String email;
  final String? nickname;
  final String? avatarUrl;
}
