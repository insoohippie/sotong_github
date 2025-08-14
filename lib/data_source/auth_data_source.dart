import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../model/signup_info.dart';

class AuthDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 현재 로그인 유저
  User? get currentUser => _auth.currentUser;

  // 로그인 - authentication 사용
  Future<UserCredential> loginWithAuth(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // 로그인 - Firestore 사용 (보안X)
  Future<bool> loginWithFirestore(String email, String password) async {
    final snapshot = await _firestore
        .collection('users')
        .where('id', isEqualTo: email)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) throw Exception('존재하지 않는 이메일입니다.');
    final storedPassword = snapshot.docs.first['pw'];
    if (storedPassword != password) throw Exception('비밀번호가 일치하지 않습니다.');
    return true;
  }

  // 이메일 중복 체크 - Firestore 기반
  Future<bool> isEmailAlreadyExists(String email) async {
    final query = await _firestore
        .collection('users')
        .where('id', isEqualTo: email)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  // 회원 생성 (Auth)
  Future<UserCredential> createUser(String email, String password) {
    return _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  // users/{uid} 쓰기
  Future<void> setUserDoc(String uid, Map<String, dynamic> data, {bool merge = true}) {
    final ref = _firestore.collection('users').doc(uid);
    return merge ? ref.set(data, SetOptions(merge: true)) : ref.set(data);
  }

  // users/{uid} 읽기
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDoc(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }
}
