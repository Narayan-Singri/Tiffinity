enum DeliveryOrderStatus {
  newOrder,
  accepted,
  pickedFromRestaurant,
  atPickup,
  onTheWayToDrop,
  delivered,
}

class OrderedItem {
  final String name;
  final int quantity;

  OrderedItem({required this.name, required this.quantity});
}

class DeliveryOrder {
  final String id;
  final String restaurantName;
  final String restaurantAddress;
  final String customerName;
  final String customerAddress;
  final double pickupDistanceKm;
  final double dropDistanceKm;
  final double tripDistanceKm;
  final bool isPaidOnline;
  final double customerRating;
  final List<OrderedItem> items;
  final DeliveryOrderStatus status;

  DeliveryOrder({
    required this.id,
    required this.restaurantName,
    required this.restaurantAddress,
    required this.customerName,
    required this.customerAddress,
    required this.pickupDistanceKm,
    required this.dropDistanceKm,
    required this.tripDistanceKm,
    required this.isPaidOnline,
    required this.customerRating,
    required this.items,
    required this.status,
  });

  DeliveryOrder copyWith({
    String? id,
    String? restaurantName,
    String? restaurantAddress,
    String? customerName,
    String? customerAddress,
    double? pickupDistanceKm,
    double? dropDistanceKm,
    double? tripDistanceKm,
    bool? isPaidOnline,
    double? customerRating,
    List<OrderedItem>? items,
    DeliveryOrderStatus? status,
  }) {
    return DeliveryOrder(
      id: id ?? this.id,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantAddress: restaurantAddress ?? this.restaurantAddress,
      customerName: customerName ?? this.customerName,
      customerAddress: customerAddress ?? this.customerAddress,
      pickupDistanceKm: pickupDistanceKm ?? this.pickupDistanceKm,
      dropDistanceKm: dropDistanceKm ?? this.dropDistanceKm,
      tripDistanceKm: tripDistanceKm ?? this.tripDistanceKm,
      isPaidOnline: isPaidOnline ?? this.isPaidOnline,
      customerRating: customerRating ?? this.customerRating,
      items: items ?? this.items,
      status: status ?? this.status,
    );
  }
}

final dummyDeliveryOrder = DeliveryOrder(
  id: '5671002428',
  restaurantName: 'Burger Shop',
  restaurantAddress: 'Ground Floor, DT Mega Mall, DLF Phase 1, Gurugram',
  customerName: 'Shreni Dand',
  customerAddress:
      'B5/156, Second Floor, Galaxy Apartments, Near St. Mary\'s School, Sector 42, Gurugram',
  pickupDistanceKm: 0.2,
  dropDistanceKm: 4.4,
  tripDistanceKm: 4.6,
  isPaidOnline: true,
  customerRating: 4.9,
  items: [
    OrderedItem(name: 'Veg Burger', quantity: 2),
    OrderedItem(name: 'Chicken Burger', quantity: 1),
    OrderedItem(name: 'French Fries', quantity: 1),
  ],
  status: DeliveryOrderStatus.newOrder,
);
