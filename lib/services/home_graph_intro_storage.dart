import 'package:hive_flutter/hive_flutter.dart';

class HomeGraphIntroStorage {
  HomeGraphIntroStorage._();

  static final HomeGraphIntroStorage instance = HomeGraphIntroStorage._();

  static const String _boxName = 'auth_cache';
  static const String _keyPrefix = 'homeGraphIntroSeen';

  Box get _box => Hive.box(_boxName);

  String _key({required String uid, required String planId}) =>
      '$_keyPrefix:$uid:$planId';

  bool hasSeen({required String uid, required String planId}) {
    return _box.get(_key(uid: uid, planId: planId), defaultValue: false)
        as bool;
  }

  Future<void> markSeen({required String uid, required String planId}) async {
    await _box.put(_key(uid: uid, planId: planId), true);
  }
}
