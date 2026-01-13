// models/category_model.dart

class Category {
  final String name;
  final int itemCount;

  Category({required this.name, required this.itemCount});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      name: json['name']?.toString() ?? '',
      itemCount: int.tryParse(json['item_count']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'item_count': itemCount};
  }

  // Reserved category check
  bool get isReserved => name == 'Daily Menu Items';
}
