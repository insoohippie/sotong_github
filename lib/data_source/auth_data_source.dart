import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // =========================================================
  // 로그인
  // =========================================================

  Future<UserCredential> loginWithAuth(
      String email,
      String password,
      ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint(
        '🔐 loginWithAuth success: ${credential.user?.email}',
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '🔥 loginWithAuth FirebaseAuthException '
            'code=${e.code}, message=${e.message}',
      );

      switch (e.code) {
        case 'user-not-found':
          throw Exception('존재하지 않는 아이디입니다.');

        case 'wrong-password':
        case 'invalid-credential':
          throw Exception('아이디 또는 비밀번호가 일치하지 않습니다.');

        case 'invalid-email':
          throw Exception('아이디 형식이 올바르지 않습니다.');

        case 'network-request-failed':
          throw Exception('인터넷 연결을 확인해주세요.');

        case 'too-many-requests':
          throw Exception(
            '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.',
          );

        case 'user-disabled':
          throw Exception('사용이 중지된 계정입니다.');

        default:
          throw Exception('로그인 중 오류가 발생했습니다.');
      }
    } catch (e) {
      debugPrint('🔥 loginWithAuth error: $e');

      throw Exception('로그인 중 오류가 발생했습니다.');
    }
  }

  // =========================================================
  // 아이디 및 이메일 중복 확인
  // =========================================================

  Future<bool> isIdAlreadyExists(String id) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('id', isEqualTo: id)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      debugPrint(
        '🔥 isIdAlreadyExists FirebaseException '
            'code=${e.code}, message=${e.message}',
      );

      if (e.code == 'unavailable') {
        throw Exception('인터넷 연결을 확인해주세요.');
      }

      throw Exception('아이디 확인 중 오류가 발생했습니다.');
    } catch (e) {
      debugPrint('🔥 isIdAlreadyExists error: $e');

      throw Exception('아이디 확인 중 오류가 발생했습니다.');
    }
  }

  Future<bool> isEmailAlreadyExists(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      debugPrint(
        '🔥 isEmailAlreadyExists FirebaseException '
            'code=${e.code}, message=${e.message}',
      );

      if (e.code == 'unavailable') {
        throw Exception('인터넷 연결을 확인해주세요.');
      }

      throw Exception('이메일 확인 중 오류가 발생했습니다.');
    } catch (e) {
      debugPrint('🔥 isEmailAlreadyExists error: $e');

      throw Exception('이메일 확인 중 오류가 발생했습니다.');
    }
  }

  // =========================================================
  // 회원가입
  // =========================================================

  Future<UserCredential> createUser(
      String email,
      String password,
      ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '🔥 createUser FirebaseAuthException '
            'code=${e.code}, message=${e.message}',
      );

      switch (e.code) {
        case 'email-already-in-use':
          throw Exception('이미 사용 중인 아이디입니다.');

        case 'weak-password':
          throw Exception('비밀번호가 너무 간단합니다.');

        case 'invalid-email':
          throw Exception('아이디 형식이 올바르지 않습니다.');

        case 'network-request-failed':
          throw Exception('인터넷 연결을 확인해주세요.');

        case 'operation-not-allowed':
          throw Exception('현재 회원가입을 진행할 수 없습니다.');

        case 'too-many-requests':
          throw Exception(
            '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.',
          );

        default:
          throw Exception('회원가입 중 오류가 발생했습니다.');
      }
    } catch (e) {
      debugPrint('🔥 createUser error: $e');

      throw Exception('회원가입 중 오류가 발생했습니다.');
    }
  }

  // =========================================================
  // Firestore 사용자 정보
  // =========================================================

  Future<void> setUserDoc(
      String uid,
      Map<String, dynamic> data, {
        bool merge = true,
      }) async {
    try {
      final ref = _firestore.collection('users').doc(uid);

      if (merge) {
        await ref.set(
          data,
          SetOptions(merge: true),
        );
      } else {
        await ref.set(data);
      }
    } on FirebaseException catch (e) {
      debugPrint(
        '🔥 setUserDoc FirebaseException '
            'code=${e.code}, message=${e.message}',
      );

      if (e.code == 'unavailable') {
        throw Exception('인터넷 연결을 확인해주세요.');
      }

      if (e.code == 'permission-denied') {
        throw Exception('회원 정보를 저장할 권한이 없습니다.');
      }

      throw Exception('회원 정보 저장 중 오류가 발생했습니다.');
    } catch (e) {
      debugPrint('🔥 setUserDoc error: $e');

      throw Exception('회원 정보 저장 중 오류가 발생했습니다.');
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDoc(
      String uid,
      ) async {
    try {
      return await _firestore.collection('users').doc(uid).get();
    } on FirebaseException catch (e) {
      debugPrint(
        '🔥 getUserDoc FirebaseException '
            'code=${e.code}, message=${e.message}',
      );

      if (e.code == 'unavailable') {
        throw Exception('인터넷 연결을 확인해주세요.');
      }

      throw Exception('회원 정보를 불러오는 중 오류가 발생했습니다.');
    }
  }

  // =========================================================
  // 로그아웃
  // =========================================================

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('🔥 signOut error: $e');

      throw Exception('로그아웃 중 오류가 발생했습니다.');
    }
  }

  // =========================================================
  // 현재 비밀번호 확인
  // =========================================================

  Future<void> verifyCurrentPassword(String password) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final email = user.email;

    if (email == null || email.isEmpty) {
      throw Exception('계정 정보가 없습니다.');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    try {
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '🔥 verifyCurrentPassword FirebaseAuthException '
            'code=${e.code}, message=${e.message}',
      );

      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          throw Exception('현재 비밀번호가 일치하지 않습니다.');

        case 'network-request-failed':
          throw Exception('인터넷 연결을 확인해주세요.');

        case 'too-many-requests':
          throw Exception(
            '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.',
          );

        default:
          throw Exception('비밀번호 확인 중 오류가 발생했습니다.');
      }
    }
  }

  // =========================================================
  // 비밀번호 변경
  // =========================================================

  Future<void> updatePasswordTo(String newPassword) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '🔥 updatePasswordTo FirebaseAuthException '
            'code=${e.code}, message=${e.message}',
      );

      switch (e.code) {
        case 'weak-password':
          throw Exception('새 비밀번호가 너무 간단합니다.');

        case 'requires-recent-login':
          throw Exception('보안을 위해 현재 비밀번호를 다시 확인해주세요.');

        case 'network-request-failed':
          throw Exception('인터넷 연결을 확인해주세요.');

        default:
          throw Exception('비밀번호 변경 중 오류가 발생했습니다.');
      }
    }
  }
}