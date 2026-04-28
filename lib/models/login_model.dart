class LoginModel {
  String email;
  String password;

  LoginModel({
    this.email = '',
    this.password = '',
  });

  void setEmail(String value) {
    email = value;
  }

  void setPassword(String value) {
    password = value;
  }
}