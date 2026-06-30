import '../services/api_client.dart';

class UserModel {
  final int id;
  final String firstname;
  final String lastname;
  final String email;
  final String? profileUrl;
  final String role;

  const UserModel({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    this.profileUrl,
    required this.role,
  });

  String get fullName => '$firstname $lastname';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as num).toInt(),
      firstname: json['firstname'] as String? ?? '',
      lastname: json['lastname'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profileUrl: ApiClient.publicUrl(json['profileUrl'] as String?),
      role: json['role'] as String? ?? 'USER',
    );
  }
}
