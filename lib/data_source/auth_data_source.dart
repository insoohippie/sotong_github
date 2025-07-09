import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../model/signup_info.dart';

class AuthDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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

  // 회원가입
  Future<User?> signUp(SignUpInfo info, {File? profileImage}) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: info.email,
      password: info.password,
    );

    final uid = userCredential.user?.uid;
    if (uid != null) {
      info.userID = uid;

      await _firestore.collection('users').doc(uid).set(info.toMap());
      return userCredential.user;
    }
    return null;
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
}
