import 'package:cloud_firestore/cloud_firestore.dart';

import '../data_source/auth_data_source.dart';
import '../data_source/category_prefs_data_source.dart';
import '../model/category/category_plan_meta_doc.dart';
import '../model/category/category_ref_prefs.dart';

class CategoryPrefsRepository {
  CategoryPrefsRepository(this._ds, this._auth);

  final CategoryPrefsDataSource _ds;
  final AuthDataSource _auth;

  String _uidOrThrow() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('로그인이 필요합니다.');
    return uid;
  }

  DateTime _normalizeDay(DateTime d) => DateTime(d.year, d.month, d.day);

  // -------------------------
  // 1) planMeta (기간)
  // -------------------------
  Future<CategoryPlanMetaDoc?> getPlanMetaForDate(DateTime date) async {
    final uid = _uidOrThrow();
    final day = _normalizeDay(date);

    final qs = await _ds.queryPlanMetaForDate(
      uid: uid,
      day: Timestamp.fromDate(day),
    );
    if (qs.docs.isEmpty) return null;

    final doc = qs.docs.first;
    final model = CategoryPlanMetaDoc.fromFirestore(doc.id, doc.data());

    final end = _normalizeDay(model.endDate);
    if (day.isAfter(end)) return null;
    return model;
  }

  /// ✅ RefData 방식 "덮어쓰기" 저장
  /// - prev(현재 활성, applyDate 커버) 존재 시:
  ///   - apply > prev.applyDate => prev.endDate = apply-1 (절단)
  ///   - apply <= prev.applyDate => prev.isActive=false (softDelete)
  /// - next는 고려하지 않음(미래 예약 유지 X)
  Future<String> savePlanMetaOverwrite({
    required CategoryPlanMetaDoc draft,
  }) async {
    final uid = _uidOrThrow();
    final apply = _normalizeDay(draft.applyDate);
    final end = _normalizeDay(draft.endDate);

    // prev: applyDate를 커버하는 "현재 활성" 문서
    final prev = await getPlanMetaForDate(apply);

    // 새 문서
    final newRef = _ds.planMetaCol(uid).doc();
    final newId = newRef.id;

    final data = draft.toFirestore();
    data['applyDate'] = Timestamp.fromDate(apply);
    data['endDate'] = Timestamp.fromDate(end);
    data['isActive'] = true;
    data['endedAt'] = null;
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    final cutEnd = apply.subtract(const Duration(days: 1));
    final cutEndTs = Timestamp.fromDate(_normalizeDay(cutEnd));

    await _ds.runTransaction((tx) async {
      if (prev != null) {
        final prevRef = _ds.planMetaCol(uid).doc(prev.id);

        // ✅ RefData와 동일한 분기 규칙:
        final prevStart = _normalizeDay(prev.applyDate);
        if (apply.isAfter(prevStart)) {
          // 중간에 끼는 경우: prev를 잘라서 공간 만들기
          tx.update(prevRef, {
            'endDate': cutEndTs,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // 새 변경이 prev보다 앞/같으면: prev는 비활성화(덮어쓰기)
          tx.update(prevRef, {
            'isActive': false,
            'endedAt': cutEndTs,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // 새 문서 저장
      tx.set(newRef, data, SetOptions(merge: false));
    });

    return newId;
  }

  // -------------------------
  // 2) refPrefs (즉시)
  // -------------------------
  Future<CategoryRefPrefs> loadRefPrefs() async {
    final uid = _uidOrThrow();
    final snap = await _ds.getRefPrefs(uid: uid);
    if (!snap.exists) return CategoryRefPrefs.empty();
    return CategoryRefPrefs.fromFirestore(snap.data() ?? {});
  }

  Future<void> saveRefPrefs(CategoryRefPrefs prefs) async {
    final uid = _uidOrThrow();
    await _ds.setRefPrefs(
      uid: uid,
      data: prefs.toFirestore(),
      options: SetOptions(merge: true),
    );
  }
}
