class SignUpInfo {
  String userID;

  /// 사용자가 입력하는 실제 아이디
  String id;

  /// Firebase Auth 내부용 이메일
  String email;

  String password;
  String name;
  String gender;
  String birthday;
  String profileImg;
  String planID;

  SignUpInfo({
    this.userID = '',
    required this.id,
    this.email = '',
    required this.password,
    this.name = '',
    this.gender = '',
    this.birthday = '',
    this.profileImg = '',
    this.planID = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'pw': password,
      'name': name,
      'gender': gender,
      'birthday': birthday,
      'profileImg': profileImg,
      'planID': planID,
    };
  }
}