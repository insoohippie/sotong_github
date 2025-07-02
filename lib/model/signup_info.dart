
class SignUpInfo {
  String userID;
  String email;
  String password;
  String name;
  String gender;
  String birthday;
  String profileImg;
  String planID; // 플랜 설정할 때 값 올리기


  SignUpInfo({
    this.userID = '',
    required this.email,
    required this.password,
    this.name = '',
    this.gender = '',
    this.birthday = '',
    this.profileImg = '',
    this.planID = ''
  });

  Map<String, dynamic> toMap() {
    return {
      'id': email,
      'pw': password,
      'name': name,
      'gender': gender,
      'birthday': birthday,
      'profileImg': profileImg,
    };
  }
}