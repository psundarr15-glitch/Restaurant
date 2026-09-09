class MenuItem {
  final int id;
  final int? subCategoryId;
  final String name;
  final String? description;
  final String? image;
  final double price;
  final bool isVeg;
  final bool isAvailable;

  MenuItem({
    required this.id,
    this.subCategoryId,
    required this.name,
    this.description,
    this.image,
    required this.price,
    this.isVeg = true,
    this.isAvailable = true,
  });

  factory MenuItem.fromJson(Map<String, dynamic> j) => MenuItem(
        id: int.parse(j['id'].toString()),
        subCategoryId: j['sub_category_id'] != null ? int.tryParse(j['sub_category_id'].toString()) : null,
        name: j['name']?.toString() ?? '',
        description: j['description']?.toString(),
        image: (j['image']?.toString().isEmpty ?? true) ? null : j['image'].toString(),
        price: double.tryParse(j['price']?.toString() ?? '') ?? 0,
        isVeg: j['is_veg'] == true || j['is_veg'].toString() == '1',
        isAvailable: j['is_available'] == true || j['is_available'].toString() == '1',
      );

  MenuItem copyWith({bool? isAvailable}) => MenuItem(
        id: id,
        subCategoryId: subCategoryId,
        name: name,
        description: description,
        image: image,
        price: price,
        isVeg: isVeg,
        isAvailable: isAvailable ?? this.isAvailable,
      );
}
