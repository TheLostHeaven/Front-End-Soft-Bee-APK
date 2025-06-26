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
      name: json['nombre'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      apiaries: (json['apiaries'] as List? ?? [])
          .map((apiary) => Apiary.fromJson(apiary))
          .toList(),
      profilePicture: json['profile_picture'] ?? 'default_profile.jpg',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': name,
      'email': email,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
      'apiaries': apiaries.map((apiary) => apiary.toJson()).toList(),
      'profile_picture': profilePicture,
    };
  }

  // Método para obtener la URL completa de la imagen de perfil
  String get profilePictureUrl {
    if (profilePicture == 'default_profile.jpg') {
      return 'images/userSoftbee.png'; // Asset local
    }
    return 'https://softbee-back-end.onrender.com/api/uploads/$profilePicture';
  }

  // Método para crear una copia con campos modificados
  UserProfile copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    DateTime? createdAt,
    List<Apiary>? apiaries,
    String? profilePicture,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      apiaries: apiaries ?? this.apiaries,
      profilePicture: profilePicture ?? this.profilePicture,
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
      id: json['id'] ?? 0,
      name: json['nombre'] ?? json['name'] ?? '',
      address: json['direccion'] ?? json['address'] ?? json['location'] ?? '',
      hiveCount: json['cantidad_colmenas'] ?? json['hive_count'] ?? 0,
      appliesTreatments:
          json['aplica_tratamientos'] ?? json['applies_treatments'] ?? false,
      createdAt: DateTime.parse(
        json['fecha_creacion'] ??
            json['created_at'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': name,
      'direccion': address,
      'cantidad_colmenas': hiveCount,
      'aplica_tratamientos': appliesTreatments,
      'fecha_creacion': createdAt.toIso8601String(),
    };
  }
}
