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

  // 로그인 - Firebase Auth 사용
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
          throw Exception('존재하지 않는 아이디입니다.');
        case 'wrong-password':
        case 'invalid-credential':
          throw Exception('비밀번호가 일치하지 않습니다.');
        case 'invalid-email':
          throw Exception('아이디 형식이 올바르지 않습니다.');
        case 'too-many-requests':
          throw Exception('잠시 후 다시 시도해주세요. (요청이 너무 많습니다)');
        default:
          throw Exception('로그인 중 오류가 발생했습니다.');
      }
    }
  }

  // 로그인 - Firestore 사용 (보안X, 현재 미사용)
  Future<bool> loginWithFirestore(String id, String password) async {
    final snapshot = await _firestore
        .collection('users')
        .where('id', isEqualTo: id)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) throw Exception('존재하지 않는 아이디입니다.');

    final storedPassword = snapshot.docs.first['pw'];
    if (storedPassword != password) {
      throw Exception('비밀번호가 일치하지 않습니다.');
    }
    return true;
  }

  /// 아이디 중복 체크 - Firestore 기준
  Future<bool> isIdAlreadyExists(String id) async {
    final query = await _firestore
        .collection('users')
        .where('id', isEqualTo: id)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  /// 내부 이메일 중복 체크 - Firestore 기준
  Future<bool> isEmailAlreadyExists(String email) async {
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  // 회원 생성 (Auth)
  Future<UserCredential> createUser(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // users/{uid} 쓰기
  Future<void> setUserDoc(
      String uid,
      Map<String, dynamic> data, {
        bool merge = true,
      }) {
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

  /// 현재 비밀번호 확인 (재인증만 수행)
  Future<void> verifyCurrentPassword(String password) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('로그인이 필요합니다.');
    final email = user.email;
    if (email == null || email.isEmpty) throw Exception('이메일 정보가 없습니다.');

    final cred = EmailAuthProvider.credential(email: email, password: password);
    await user.reauthenticateWithCredential(cred);
  }

  /// 비밀번호 변경
  Future<void> updatePasswordTo(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('로그인이 필요합니다.');
    await user.updatePassword(newPassword);
  }
}