class Category {
  final String id;
  final String name;
  final String companyId;

  Category({
    required this.id,
    required this.name,
    required this.companyId,
  });

  factory Category.fromMap(String id, Map<String, dynamic> data) {
    return Category(
      id: id,
      name: data['name'],
      companyId: data['companyId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'companyId': companyId,
    };
  }
}
