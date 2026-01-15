class Category {
  final int id;
  final int messId;
  final String name;
  final int isReserved;
  final String categoryType;
  final int itemCount;
  final String? createdAt;
  final String? updatedAt;

  Category({
    required this.id,
    required this.messId,
    required this.name,
    required this.isReserved,
    required this.categoryType,
    required this.itemCount,
    this.createdAt,
    this.updatedAt,
  });

  // ✅ Check if category can be deleted (non-reserved categories only)
  bool get isDeletable => isReserved == 0;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      messId:
          json['mess_id'] is int
              ? json['mess_id']
              : int.parse(json['mess_id'].toString()),
      name: json['name'].toString(),
      isReserved:
          json['is_reserved'] is int
              ? json['is_reserved']
              : int.parse(json['is_reserved'].toString()),
      categoryType: json['category_type'].toString(),
      itemCount:
          json['item_count'] is int
              ? json['item_count']
              : int.parse(json['item_count'].toString()),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
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
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
