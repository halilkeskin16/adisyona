class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String categoryId;
  final String companyId;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.companyId,
  });

  factory Product.fromMap(String id, Map<String, dynamic> data) {
    return Product(
      id: id,
      name: data['name'],
      description: data['description'],
      price: (data['price'] as num).toDouble(),
      categoryId: data['categoryId'],
      companyId: data['companyId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'categoryId': categoryId,
      'companyId': companyId,
    };
  }
}
