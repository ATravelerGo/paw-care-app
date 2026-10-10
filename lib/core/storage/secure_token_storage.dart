import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../error/app_exception.dart';
import 'token_storage.dart';

final class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  static const _accessTokenKey = 'pawcare.access_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } on Object catch (error) {
      throw SecureStorageException('无法读取登录凭证', cause: error);
    }
  }

  @override
  Future<void> saveAccessToken(String token) async {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      throw ArgumentError.value(token, 'token', 'Token must not be empty.');
    }

    try {
      await _storage.write(key: _accessTokenKey, value: normalizedToken);
    } on Object catch (error) {
      throw SecureStorageException('无法保存登录凭证', cause: error);
    }
  }

  @override
  Future<void> deleteAccessToken() async {
    try {
      await _storage.delete(key: _accessTokenKey);
    } on Object catch (error) {
      throw SecureStorageException('无法清除登录凭证', cause: error);
    }
  }
}
