/// This restaurant's own profile, as the manager sees/edits it (raw DB
/// fields from Api\ManagerApiController::restaurant() — unlike the
/// customer app's Restaurant model, there's no is_open/liked_by_me/
/// distance_km here since those are customer-facing computed fields
/// this endpoint doesn't need).
class Restaurant {
  final int id;
  final String name;
  final String? ownerName;
  final String? ownerPhone;
  final String? phone;
  final String? description;
  final String? cuisine;
  final String? restaurantType;
  final String foodType;
  final String? image;
  final String? logo;
  final double rating;
  final int ratingCount;
  final int prepTimeMin;
  final int prepTimeMax;
  final double costForTwo;
  final String? discountLabel;
  final String? address;
  final double? lat;
  final double? lng;
  final bool isActive;
  final String? openingTime;
  final String? closingTime;
  final String? fssaiNumber;
  final String? tinNumber;
  final String? fssaiCertificate;
  final String? tinCertificate;
  final String? bankAccountNumber;
  final String? bankIfsc;
  final String? bankAccountHolder;

  Restaurant({
    required this.id,
    required this.name,
    this.ownerName,
    this.ownerPhone,
    this.phone,
    this.description,
    this.cuisine,
    this.restaurantType,
    this.foodType = 'both',
    this.image,
    this.logo,
    this.rating = 0,
    this.ratingCount = 0,
    this.prepTimeMin = 20,
    this.prepTimeMax = 40,
    this.costForTwo = 0,
    this.discountLabel,
    this.address,
    this.lat,
    this.lng,
    this.isActive = true,
    this.openingTime,
    this.closingTime,
    this.fssaiNumber,
    this.tinNumber,
    this.fssaiCertificate,
    this.tinCertificate,
    this.bankAccountNumber,
    this.bankIfsc,
    this.bankAccountHolder,
  });

  factory Restaurant.fromJson(Map<String, dynamic> j) => Restaurant(
        id: int.parse(j['id'].toString()),
        name: j['name']?.toString() ?? '',
        ownerName: j['owner_name']?.toString(),
        ownerPhone: j['owner_phone']?.toString(),
        phone: j['phone']?.toString(),
        description: j['description']?.toString(),
        cuisine: j['cuisine']?.toString(),
        restaurantType: j['restaurant_type']?.toString(),
        foodType: j['food_type']?.toString() ?? 'both',
        image: (j['image']?.toString().isEmpty ?? true) ? null : j['image'].toString(),
        logo: (j['logo']?.toString().isEmpty ?? true) ? null : j['logo'].toString(),
        rating: double.tryParse(j['rating']?.toString() ?? '') ?? 0,
        ratingCount: int.tryParse(j['rating_count']?.toString() ?? '') ?? 0,
        prepTimeMin: int.tryParse(j['prep_time_min']?.toString() ?? '') ?? 20,
        prepTimeMax: int.tryParse(j['prep_time_max']?.toString() ?? '') ?? 40,
        costForTwo: double.tryParse(j['cost_for_two']?.toString() ?? '') ?? 0,
        discountLabel: (j['discount_label']?.toString().isEmpty ?? true) ? null : j['discount_label'].toString(),
        address: j['address']?.toString(),
        lat: j['lat'] != null ? double.tryParse(j['lat'].toString()) : null,
        lng: j['lng'] != null ? double.tryParse(j['lng'].toString()) : null,
        isActive: j['is_active'] == true || j['is_active'].toString() == '1',
        openingTime: j['opening_time']?.toString(),
        closingTime: j['closing_time']?.toString(),
        fssaiNumber: j['fssai_number']?.toString(),
        tinNumber: j['tin_number']?.toString(),
        fssaiCertificate: j['fssai_certificate']?.toString(),
        tinCertificate: j['tin_certificate']?.toString(),
        bankAccountNumber: j['bank_account_number']?.toString(),
        bankIfsc: j['bank_ifsc']?.toString(),
        bankAccountHolder: j['bank_account_holder']?.toString(),
      );
}
