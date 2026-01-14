// models/category_model.dart

class Category {
  final int id;
  final int messId;
  final String name;
  final int isReserved;
  final String categoryType;
  final int itemCount;
  final bool isDeletable;

  Category({
    required this.id,
    required this.messId,
    required this.name,
    required this.isReserved,
    required this.categoryType,
    required this.itemCount,
    required this.isDeletable,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      messId: int.tryParse(json['mess_id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      isReserved: int.tryParse(json['is_reserved']?.toString() ?? '0') ?? 0,
      categoryType: json['category_type']?.toString() ?? 'custom',
      itemCount: int.tryParse(json['item_count']?.toString() ?? '0') ?? 0,
      isDeletable:
          json['is_deletable'] == true ||
          json['is_deletable'] == 1 ||
          json['is_deletable']?.toString() == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mess_id': messId,
      'name': name,
      'is_reserved': isReserved,
      'category_type': categoryType,
      'item_count': itemCount,
      'is_deletable': isDeletable,
    };
  }

  // Helper getter
  bool get isDefaultCategory => messId == 0 || isReserved == 1;
}
