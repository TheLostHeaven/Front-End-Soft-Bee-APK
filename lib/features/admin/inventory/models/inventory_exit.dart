class InventoryExit {
  final int id;
  final int insumoId;
  final String nombreInsumo;
  final int cantidad;
  final String persona;
  final DateTime fecha;

  InventoryExit({
    required this.id,
    required this.insumoId,
    required this.nombreInsumo,
    required this.cantidad,
    required this.persona,
    required this.fecha,
  });

  factory InventoryExit.fromJson(Map<String, dynamic> json) {
    return InventoryExit(
      id: json['id'] ?? 0,
      insumoId: json['item_id'] ?? 0,
      nombreInsumo: json['item_name'] ?? '',
      cantidad: json['quantity'] ?? 0,
      persona: json['person'] ?? '',
      fecha: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': insumoId,
      'item_name': nombreInsumo,
      'quantity': cantidad,
      'person': persona,
      'date': fecha.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {'item_id': insumoId, 'quantity': cantidad, 'person': persona};
  }
}
