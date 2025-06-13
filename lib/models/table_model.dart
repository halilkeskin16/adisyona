class TableModel {
  final String id;
  final String name;
  final String areaId;
  final String companyId;

  TableModel({
    required this.id,
    required this.name,
    required this.areaId,
    required this.companyId,
  });

  factory TableModel.fromMap(String id, Map<String, dynamic> data) {
    return TableModel(
      id: id,
      name: data['name'],
      areaId: data['areaId'],
      companyId: data['companyId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'areaId': areaId,
      'companyId': companyId,
    };
  }
}
