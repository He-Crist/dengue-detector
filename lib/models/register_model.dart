class RegisterModel {
  String name;
  String email;
  String password;
  String confirmPassword;

  RegisterModel({
    this.name = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
  });

  void setName(String value) => name = value;
  void setEmail(String value) => email = value;
  void setPassword(String value) => password = value;
  void setConfirmPassword(String value) => confirmPassword = value;

  bool get isPasswordMatch => password == confirmPassword;
  bool get isNameValid => name.trim().isNotEmpty;
  bool get isEmailValid => email.contains('@') && email.contains('.');
  bool get isPasswordValid => password.length >= 6;

  void clear() {
    name = '';
    email = '';
    password = '';
    confirmPassword = '';
  }
}