import '../services/api_client.dart';

class UserModel {
  final int id;
  final String firstname;
  final String lastname;
  final String email;
  final String? profileUrl;
  final String role;
  final String? username;
  final String? bio;
  final String? location;

  const UserModel({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    this.profileUrl,
    required this.role,
    this.username,
    this.bio,
    this.location,
  });

  String get fullName => '$firstname $lastname';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as num).toInt(),
      firstname:
          json['firstname'] as String? ?? json['firstName'] as String? ?? '',
      lastname:
          json['lastname'] as String? ?? json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profileUrl: ApiClient.publicUrl(json['profileUrl'] as String?),
      role: json['role'] as String? ?? 'USER',
      username: json['username'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
    );
  }
}
