import 'package:flutter/foundation.dart';

abstract class SessionResettable {
  void resetSession();
}

class AppSessionResetService {
  AppSessionResetService({
    required List<SessionResettable> targets,
  }) : _targets = targets;

  final List<SessionResettable> _targets;

  void resetAll() {
    for (final target in _targets) {
      try {
        target.resetSession();
      } catch (e) {
        debugPrint('[AppSessionResetService] reset failed: $e');
      }
    }
  }
}