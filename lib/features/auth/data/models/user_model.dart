class UserProfile {
  final int id;
  final String name;
  final String email;
  final String phone;
  final DateTime createdAt;
  final List<Apiary> apiaries;
  final String profilePicture;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.createdAt,
    required this.apiaries,
    required this.profilePicture,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['nombre'],
      email: json['email'],
      phone: json['phone'],
      createdAt: DateTime.parse(json['created_at']),
      apiaries: (json['apiarios'] as List? ?? [])
          .map((apiary) => Apiary.fromJson(apiary))
          .toList(),
      profilePicture: json['profile_picture'] ?? 'default_profile.jpg',
    );
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
      id: json['id'],
      name: json['nombre'],
      address: json['direccion'],
      hiveCount: json['cantidad_colmenas'],
      appliesTreatments: json['aplica_tratamientos'],
      createdAt: DateTime.parse(json['fecha_creacion']),
    );
  }
}
