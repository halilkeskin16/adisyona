class Area {
  final String id;
  final String name;
  final String companyId;

  Area({
    required this.id,
    required this.name,
    required this.companyId,
  });

  factory Area.fromMap(String id, Map<String, dynamic> data) {
    return Area(
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
