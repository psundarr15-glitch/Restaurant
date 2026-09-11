class Manager {
  final int id;
  final String name;
  final String email;
  final int? restaurantId;

  Manager({required this.id, required this.name, required this.email, this.restaurantId});

  factory Manager.fromJson(Map<String, dynamic> j) => Manager(
        id: int.parse(j['id'].toString()),
        name: j['name']?.toString() ?? '',
        email: j['email']?.toString() ?? '',
        restaurantId: j['restaurant_id'] != null ? int.tryParse(j['restaurant_id'].toString()) : null,
      );
}
