import 'package:intl/intl.dart';

DateTime _parseDate(String? dateString) {
  if (dateString == null) {
    return DateTime.now();
  }
  try {
    // First, try the standard ISO 8601 format
    return DateTime.parse(dateString);
  } catch (e) {
    // If that fails, try the RFC 1123 format
    try {
      return DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'").parse(dateString, true).toUtc();
    } catch (e2) {
      // If both fail, return the current time as a fallback
      print('Could not parse date: $dateString. Error: $e2');
      return DateTime.now();
    }
  }
}

class UserProfile {
  final int id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String role;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Apiary> apiaries;
  final String profilePicture;

  UserProfile({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.role,
    required this.isVerified,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.apiaries,
    required this.profilePicture,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? 0,
      name: json['nombre'] ?? json['name'] ?? 'Sin nombre',
      username: json['username'] ?? 'Sin usuario',
      email: json['email'] ?? 'Sin email',
      phone: json['phone'] ?? 'Sin teléfono',
      role: json['role'] ?? 'user',
      isVerified: json['isVerified'] ?? json['verified'] ?? false,
      isActive: json['isActive'] ?? json['active'] ?? true,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at'] ?? json['created_at']),
      apiaries: (json['apiaries'] as List? ?? [])
          .map((apiary) => Apiary.fromJson(apiary))
          .toList(),
      profilePicture:
          json['profile_picture'] ??
          json['profilePicture'] ??
          'default_profile.jpg',
    );
  }

  String get profilePictureUrl {
    if (profilePicture == 'default_profile.jpg' || profilePicture.isEmpty) {
      return 'images/userSoftbee.png';
    }
    return 'https://softbee-back-end.onrender.com/static/profile_pictures/$profilePicture';
  }
}

class Apiary {
  final int id;
  final String name;
  final String address;
  final int hiveCount;
  final bool appliesTreatments;
  final DateTime createdAt;

  Apiary({
    required this.id,
    required this.name,
    required this.address,
    required this.hiveCount,
    required this.appliesTreatments,
    required this.createdAt,
  });

  factory Apiary.fromJson(Map<String, dynamic> json) {
    return Apiary(
      id: json['id'] ?? 0,
      name: json['nombre'] ?? json['name'] ?? 'Sin nombre',
      address:
          json['direccion'] ??
          json['address'] ??
          json['location'] ??
          'Sin dirección',
      hiveCount: json['cantidad_colmenas'] ?? json['hive_count'] ?? 0,
      appliesTreatments:
          json['aplica_tratamientos'] ?? json['applies_treatments'] ?? false,
      createdAt: _parseDate(json['fecha_creacion'] ?? json['created_at']),
    );
  }
}
