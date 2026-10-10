import 'package:flutter/foundation.dart';

final class AuthSessionInvalidator extends ChangeNotifier {
  Object? _cleanupError;

  Object? get cleanupError => _cleanupError;

  void invalidate({Object? cleanupError}) {
    _cleanupError = cleanupError;
    notifyListeners();
  }
}
