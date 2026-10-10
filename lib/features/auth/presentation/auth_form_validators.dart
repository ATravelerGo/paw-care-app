abstract final class AuthFormValidators {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return '请输入邮箱';
    if (!_emailPattern.hasMatch(email)) return '请输入有效的邮箱地址';
    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return '请输入密码';
    if (password.length < 6) return '密码至少需要 6 个字符';
    return null;
  }

  static String? nickname(String? value) {
    final nickname = value?.trim() ?? '';
    if (nickname.isEmpty) return '请输入昵称';
    if (nickname.length > 50) return '昵称不能超过 50 个字符';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return '请再次输入密码';
    if (value != password) return '两次输入的密码不一致';
    return null;
  }
}
