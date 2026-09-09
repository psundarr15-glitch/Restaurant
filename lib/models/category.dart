class Category {
  final int id;
  final String name;
  Category({required this.id, required this.name});
  factory Category.fromJson(Map<String, dynamic> j) =>
      Category(id: int.parse(j['id'].toString()), name: j['name']?.toString() ?? '');
}

class SubCategory {
  final int id;
  final int categoryId;
  final String name;
  SubCategory({required this.id, required this.categoryId, required this.name});
  factory SubCategory.fromJson(Map<String, dynamic> j) => SubCategory(
        id: int.parse(j['id'].toString()),
        categoryId: int.tryParse(j['category_id']?.toString() ?? '') ?? 0,
        name: j['name']?.toString() ?? '',
      );
}
