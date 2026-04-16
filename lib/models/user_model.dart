import 'dart:convert';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String hashedPassword;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.hashedPassword,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'hashedPassword': hashedPassword,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      hashedPassword: map['hashedPassword'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) => 
      UserModel.fromMap(json.decode(source));
}
