import 'dart:convert';

class ShoppingItem {
  final String id;
  final String name;
  final DateTime? targetDate;
  final bool isCustom;

  ShoppingItem({
    required this.id,
    required this.name,
    this.targetDate,
    this.isCustom = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetDate': targetDate?.toIso8601String(),
      'isCustom': isCustom,
    };
  }

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id'],
      name: map['name'],
      targetDate: map['targetDate'] != null ? DateTime.parse(map['targetDate']) : null,
      isCustom: map['isCustom'] ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory ShoppingItem.fromJson(String source) => ShoppingItem.fromMap(json.decode(source));
}
