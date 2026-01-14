// models/weekly_menu_model.dart

class WeeklyMenuItem {
  final int id;
  final int messId;
  final int menuItemId;
  final String weekStartDate;
  final Map<String, int?> days; // {monday: 1, tuesday: 0, ...}
  final double price;
  final int? categoryId;
  final String? categoryName;
  final String itemName;
  final String? description;
  final String? imageUrl;
  final String itemType;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WeeklyMenuItem({
    required this.id,
    required this.messId,
    required this.menuItemId,
    required this.weekStartDate,
    required this.days,
    required this.price,
    this.categoryId,
    this.categoryName,
    required this.itemName,
    this.description,
    this.imageUrl,
    required this.itemType,
    this.createdAt,
    this.updatedAt,
  });

  factory WeeklyMenuItem.fromJson(Map<String, dynamic> json) {
    final daysJson = json['days'] as Map<String, dynamic>?;
    final days = <String, int?>{
      'monday': daysJson?['monday'],
      'tuesday': daysJson?['tuesday'],
      'wednesday': daysJson?['wednesday'],
      'thursday': daysJson?['thursday'],
      'friday': daysJson?['friday'],
      'saturday': daysJson?['saturday'],
      'sunday': daysJson?['sunday'],
    };

    return WeeklyMenuItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      messId: int.tryParse(json['mess_id']?.toString() ?? '0') ?? 0,
      menuItemId: int.tryParse(json['menu_item_id']?.toString() ?? '0') ?? 0,
      weekStartDate: json['week_start_date']?.toString() ?? '',
      days: days,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      categoryId:
          json['category_id'] != null
              ? int.tryParse(json['category_id'].toString())
              : null,
      categoryName: json['category_name']?.toString(),
      itemName: json['item_name']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString(),
      itemType: json['item_type']?.toString() ?? 'veg',
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString())
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at'].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mess_id': messId,
      'menu_item_id': menuItemId,
      'week_start_date': weekStartDate,
      'days': days,
      'price': price,
      'category_id': categoryId,
      'category_name': categoryName,
      'item_name': itemName,
      'description': description,
      'image_url': imageUrl,
      'item_type': itemType,
    };
  }

  // Helper: Check if available on a specific day
  bool isAvailableOn(String day) {
    return days[day.toLowerCase()] == 1;
  }

  // Helper: Get availability status text
  String getAvailabilityText(String day) {
    final status = days[day.toLowerCase()];
    if (status == null) return 'Not Scheduled';
    if (status == 1) return 'Available';
    return 'Unavailable';
  }
}

class TodaysMenuItem {
  final int id;
  final int menuItemId;
  final String itemName;
  final String? description;
  final String? imageUrl;
  final String itemType;
  final double price;
  final int? categoryId;
  final String? categoryName;

  TodaysMenuItem({
    required this.id,
    required this.menuItemId,
    required this.itemName,
    this.description,
    this.imageUrl,
    required this.itemType,
    required this.price,
    this.categoryId,
    this.categoryName,
  });

  factory TodaysMenuItem.fromJson(Map<String, dynamic> json) {
    return TodaysMenuItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      menuItemId: int.tryParse(json['menu_item_id']?.toString() ?? '0') ?? 0,
      itemName: json['item_name']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['image_url']?.toString(),
      itemType: json['item_type']?.toString() ?? 'veg',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      categoryId:
          json['category_id'] != null
              ? int.tryParse(json['category_id'].toString())
              : null,
      categoryName: json['category_name']?.toString(),
    );
  }
}
