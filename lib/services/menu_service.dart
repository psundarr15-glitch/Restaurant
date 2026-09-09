import 'dart:io';
import '../config/api_config.dart';
import '../models/menu_item.dart';
import '../models/category.dart';
import 'api_client.dart';

class MenuData {
  final List<MenuItem> items;
  final Map<String, List<MenuItem>> grouped;
  MenuData({required this.items, required this.grouped});
}

class CategoryData {
  final List<Category> categories;
  final List<SubCategory> subCategories;
  CategoryData({required this.categories, required this.subCategories});
}

class MenuService {
  static Future<MenuData> menu() async {
    final res = await ApiClient.get(ApiConfig.menu);
    final items = (res['items'] as List<dynamic>? ?? []).map((e) => MenuItem.fromJson(e)).toList();

    final grouped = <String, List<MenuItem>>{};
    final rawMenu = res['menu'];
    if (rawMenu is Map) {
      rawMenu.forEach((key, value) {
        grouped[key.toString()] = (value as List<dynamic>).map((e) => MenuItem.fromJson(e)).toList();
      });
    }
    return MenuData(items: items, grouped: grouped);
  }

  static Future<CategoryData> categories() async {
    final res = await ApiClient.get(ApiConfig.categories);
    return CategoryData(
      categories: (res['categories'] as List<dynamic>? ?? []).map((e) => Category.fromJson(e)).toList(),
      subCategories: (res['sub_categories'] as List<dynamic>? ?? []).map((e) => SubCategory.fromJson(e)).toList(),
    );
  }

  static Future<SubCategory> addSubCategory({required int categoryId, required String name}) async {
    final res = await ApiClient.post(ApiConfig.addSubCategory, {'category_id': categoryId, 'name': name});
    return SubCategory.fromJson(res['sub_category'] as Map<String, dynamic>);
  }

  static Future<MenuItem> add({
    required String name,
    String? description,
    required double price,
    int? subCategoryId,
    bool isVeg = true,
    bool isAvailable = true,
    File? image,
  }) async {
    final fields = {
      'name': name,
      'description': description,
      'price': price,
      'sub_category_id': subCategoryId,
      'is_veg': isVeg ? 1 : 0,
      'is_available': isAvailable ? 1 : 0,
    };
    final res = await ApiClient.postMultipart(
      ApiConfig.menuAdd,
      fields,
      files: image != null ? {'image': image} : null,
    );
    return MenuItem.fromJson(res['item'] as Map<String, dynamic>);
  }

  static Future<MenuItem> update(
    int id, {
    required String name,
    String? description,
    required double price,
    int? subCategoryId,
    bool isVeg = true,
    bool isAvailable = true,
    File? image,
  }) async {
    final fields = {
      'name': name,
      'description': description,
      'price': price,
      'sub_category_id': subCategoryId,
      'is_veg': isVeg ? 1 : 0,
      'is_available': isAvailable ? 1 : 0,
    };
    final res = await ApiClient.postMultipart(
      ApiConfig.menuUpdate(id),
      fields,
      files: image != null ? {'image': image} : null,
    );
    return MenuItem.fromJson(res['item'] as Map<String, dynamic>);
  }

  static Future<void> delete(int id) => ApiClient.post(ApiConfig.menuDelete(id));

  static Future<bool> toggleAvailability(int id) async {
    final res = await ApiClient.post(ApiConfig.menuToggleAvailability(id));
    return res['is_available'] == true;
  }
}
