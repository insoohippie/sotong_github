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

  // Auth (권장) - 로그인
  Future<UserCredential> loginWithAuth(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // 로그인
  Future<bool> loginWithFirestore(String email, String password) async {
    final snapshot = await _firestore
        .collection('users')
        .where('id', isEqualTo: email)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('존재하지 않는 이메일입니다.');
    }

    final storedPassword = snapshot.docs.first['pw'];
    if (storedPassword != password) {
      throw Exception('비밀번호가 일치하지 않습니다.');
    }

    return true;
  }

  // 회원가입 (Auth 생성 + Firestore 저장)
  Future<User?> signUp(SignUpInfo info) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: info.email,
      password: info.password,
    );
    final user = cred.user;
    if (user == null) return null;

    // uid 주입
    info.userID = user.uid;

    // Firestore users/{uid} 저장
    final data = {
      ...info.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    };
    await _firestore.collection('users').doc(user.uid).set(
      data,
      SetOptions(merge: true),
    );

    return user;
  }

  // 이메일 중복 확인
  Future<bool> isEmailAlreadyExists(String email) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('id', isEqualTo: email)
        .limit(1)
        .get();
    print("isNotEmpty");
    print(query.docs.isNotEmpty);
    return query.docs.isNotEmpty;
  }

  // Firestore users/{uid} 문서 읽기
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDoc(String uid) {
    return _firestore.collection('users').doc(uid).get();
  }
}
