class InventoryItem {
  final int id;
  final String itemName;
  final int quantity;
  final String unit;
  final int apiaryId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool sincronizado;

  InventoryItem({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.unit,
    required this.apiaryId,
    required this.createdAt,
    required this.updatedAt,
    this.sincronizado = true,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] ?? 0,
      itemName: json['item_name'] ?? '',
      quantity: json['quantity'] ?? 0,
      unit: json['unit'] ?? 'unit',
      apiaryId: json['apiary_id'] ?? 1,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      sincronizado: json['sincronizado'] == 1 ? true : false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_name': itemName,
      'quantity': quantity,
      'unit': unit,
      'apiary_id': apiaryId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sincronizado': sincronizado ? 1 : 0,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': itemName,
      'quantity': quantity,
      'unit': unit,
      'apiary_id': apiaryId,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {'item_name': itemName, 'quantity': quantity, 'unit': unit};
  }

  InventoryItem copyWith({
    int? id,
    String? itemName,
    int? quantity,
    String? unit,
    int? apiaryId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? sincronizado,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      apiaryId: apiaryId ?? this.apiaryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sincronizado: sincronizado ?? this.sincronizado,
    );
  }

  // Convertir a Map para compatibilidad con tu código existente
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': itemName,
      'cantidad': quantity.toString(),
      'unidad': unit,
      'sincronizado': sincronizado ? 1 : 0,
    };
  }

  // Crear desde Map para compatibilidad con tu código existente
  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] ?? 0,
      itemName: map['nombre'] ?? '',
      quantity: int.tryParse(map['cantidad']?.toString() ?? '0') ?? 0,
      unit: map['unidad'] ?? 'unit',
      apiaryId: 1, // Default apiary ID
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      sincronizado: map['sincronizado'] == 1 ? true : false,
    );
  }
}
