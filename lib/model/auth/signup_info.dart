class SignUpInfo {
  String userID;

  /// 사용자가 입력하는 실제 아이디
  String id;

  /// Firebase Auth 내부용 이메일
  String email;

  /// Firebase Auth 회원가입에만 사용.
  /// Firestore에는 저장하지 않음.
  String password;

  /// 앱 내 표시용 닉네임
  String nickname;

  String profileImg;
  String planID;

  SignUpInfo({
    this.userID = '',
    required this.id,
    this.email = '',
    required this.password,
    this.nickname = '',
    this.profileImg = '',
    this.planID = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'profileImg': profileImg,
      'planID': planID,
    };
  }
}