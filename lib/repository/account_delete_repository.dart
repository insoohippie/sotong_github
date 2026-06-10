import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'auth_repository.dart';

class AccountDeleteRepository {
  AccountDeleteRepository(this._authRepository);

  final AuthRepository _authRepository;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> deleteAccountCompletely() async {
    // 1. uid 확보
    final uid = _authRepository.cachedUid ?? _authRepository.currentUserId;

    if (uid == null) {
      throw Exception('로그인된 사용자 정보가 없습니다.');
    }

    debugPrint('[AccountDeleteRepository] delete start uid=$uid');

    // 4. Firestore 사용자 데이터 삭제
    await _deleteUserFirestoreData(uid);

    // 5. Hive 사용자 데이터 삭제
    await clearLocalHiveCaches(uid);

    // 6. Firebase Auth 계정 삭제
    await _authRepository.deleteCurrentAccount();

    debugPrint('[AccountDeleteRepository] delete complete uid=$uid');
  }

  Future<void> _deleteUserFirestoreData(String uid) async {
    final userRef = _firestore.collection('users').doc(uid);

    await _deleteCollection(userRef.collection('plans'));
    await _deleteCollection(userRef.collection('records'));
    await _deleteCollection(userRef.collection('refCategories'));

    final refRoot = userRef.collection('refData').doc('_root');

    await _deleteCollection(refRoot.collection('monthlyIncome'));
    await _deleteCollection(refRoot.collection('monthlyConsume'));
    await _deleteCollection(refRoot.collection('dailyConsume'));

    await refRoot.delete().catchError((_) {});
    await userRef.delete().catchError((_) {});
  }

  Future<void> _deleteCollection(
      CollectionReference<Map<String, dynamic>> collection, {
        int batchSize = 400,
      }) async {
    while (true) {
      final snapshot = await collection.limit(batchSize).get();

      if (snapshot.docs.isEmpty) break;

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (snapshot.docs.length < batchSize) break;
    }
  }

  Future<void> clearLocalHiveCaches(String uid) async {
    await _deleteKeysByPrefix('monthly_spending', '$uid:');
    await _deleteKeysByPrefix('refData', '$uid:refdata:');
    await _deleteKeysByPrefix('ref_categories', '$uid:refcat:');
    await _deleteKeysByPrefix('past_plans', '$uid:');
    await _deleteKeysByPrefix('notification_read', '$uid:');
    await _deleteKeysByPrefix('notification_cache', '$uid:');

    await _deleteExactKey('plan_cache', uid);

    await _deleteExactKey('notification_settings', 'settings_$uid');
    await _deleteExactKey(
      'notification_settings',
      'applied_signup_defaults_$uid',
    );

    await _deleteExactKey('auth_cache', 'hasPlan_$uid');
    await _deleteExactKey('auth_cache', 'uid');
    await _deleteExactKey('auth_cache', 'loggedIn');
    await _deleteExactKey('auth_cache', 'loggedOutExplicit');

    // settings 박스는 유지
    // 현재 settings에는 isDarkMode만 저장되므로 계정 데이터가 아니라 기기 설정으로 봄.
  }

  Future<void> _deleteKeysByPrefix(String boxName, String prefix) async {
    try {
      final box = Hive.isBoxOpen(boxName)
          ? Hive.box(boxName)
          : await Hive.openBox(boxName);

      final keysToDelete = box.keys
          .where((key) => key.toString().startsWith(prefix))
          .toList();

      for (final key in keysToDelete) {
        await box.delete(key);
      }

      debugPrint(
        '[AccountDeleteRepository] deleted $boxName prefix=$prefix count=${keysToDelete.length}',
      );
    } catch (e) {
      debugPrint(
        '[AccountDeleteRepository] failed prefix delete $boxName: $e',
      );
    }
  }

  Future<void> _deleteExactKey(String boxName, String key) async {
    try {
      final box = Hive.isBoxOpen(boxName)
          ? Hive.box(boxName)
          : await Hive.openBox(boxName);

      await box.delete(key);

      debugPrint(
        '[AccountDeleteRepository] deleted $boxName key=$key',
      );
    } catch (e) {
      debugPrint(
        '[AccountDeleteRepository] failed key delete $boxName:$key: $e',
      );
    }
  }
}