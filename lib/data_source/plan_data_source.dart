// data_source/plan_data_source.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/plan_info.dart';

class PlanDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // doc id 랜덤말고 생성되는 시간으로?!
  /// users/{uid}/plans/{auto-id} 에 저장하고 docId 반환
  Future<String> savePlan(String uid, PlanInfo plan) async {
    final col = _firestore.collection('users').doc(uid).collection('plans');
    final docRef = col.doc();
    final data = {
      ...plan.toMap(),
      'planId': docRef.id,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await docRef.set(data, SetOptions(merge: true));
    return docRef.id;
  }
}