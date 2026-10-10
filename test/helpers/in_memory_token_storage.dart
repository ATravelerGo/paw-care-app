import 'package:paw_care_app/core/storage/token_storage.dart';

final class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage([this.token]);

  String? token;

  @override
  Future<void> deleteAccessToken() async {
    token = null;
  }

  @override
  Future<String?> readAccessToken() async => token;

  @override
  Future<void> saveAccessToken(String token) async {
    this.token = token;
  }
}
