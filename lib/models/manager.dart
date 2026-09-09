class Manager {
  final int id;
  final String name;
  final String email;

  Manager({required this.id, required this.name, required this.email});

  factory Manager.fromJson(Map<String, dynamic> j) => Manager(
        id: int.parse(j['id'].toString()),
        name: j['name']?.toString() ?? '',
        email: j['email']?.toString() ?? '',
      );
}
