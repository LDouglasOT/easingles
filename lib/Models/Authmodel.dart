class User {
  String token;
  String refreshToken;
  String id;
  String lastname;
  String firstname;
  String gender;

  User({
    required this.token,
    required this.refreshToken,
    required this.id,
    required this.lastname,
    required this.firstname,
    required this.gender,
  });

  // Factory method to create a User object from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      token: json['token'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      id: json['id'] ?? '',
      lastname: json['lastname'] ?? '',
      firstname: json['firstname'] ?? '',
      gender: json['gender'] ?? '',
    );
  }
}
