import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../model/auth/signup_info.dart';

class AuthDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 현재 로그인 유저
  User? get currentUser => _auth.currentUser;

  // 로그인 - authentication 사용
  Future<UserCredential> loginWithAuth(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('🔐 loginWithAuth success: ${cred.user?.email}');
      return cred;
    } on FirebaseAuthException catch (e) {
      print('🔥 FirebaseAuthException code = ${e.code}, message = ${e.message}');

      switch (e.code) {
        case 'user-not-found':
          throw Exception('존재하지 않는 이메일입니다.');
        case 'wrong-password':      // 일부 버전
        case 'invalid-credential':  // 네가 받은 버전
          throw Exception('비밀번호가 일치하지 않습니다.');
        case 'invalid-email':
          throw Exception('이메일 형식이 올바르지 않습니다.');
        case 'too-many-requests':
          throw Exception('잠시 후 다시 시도해주세요. (요청이 너무 많습니다)');
        default:
          throw Exception('로그인 중 오류가 발생했습니다.');
      }
    }
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

  /// 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
