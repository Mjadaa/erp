class Category {
  final int? id;
  final String name;

  const Category({this.id, required this.name});

  factory Category.fromMap(Map<String, dynamic> m) =>
      Category(id: m['id'] as int?, name: m['name'] as String);

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
  };

  Category copyWith({int? id, String? name}) =>
      Category(id: id ?? this.id, name: name ?? this.name);
}

class Warehouse {
  final int? id;
  final String name;
  final String? location;

  const Warehouse({this.id, required this.name, this.location});

  factory Warehouse.fromMap(Map<String, dynamic> m) => Warehouse(
    id: m['id'] as int?,
    name: m['name'] as String,
    location: m['location'] as String?,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    if (location != null) 'location': location,
  };

  Warehouse copyWith({int? id, String? name, String? location}) => Warehouse(
    id: id ?? this.id,
    name: name ?? this.name,
    location: location ?? this.location,
  );
}

class Product {
  final int? id;
  final int categoryId;
  final String name;
  final String? barcode;
  final double purchasePrice;
  final double salePrice;
  final int stockQuantity;
  final int minStockAlert;
  // joined
  final String? categoryName;

  const Product({
    this.id,
    required this.categoryId,
    required this.name,
    this.barcode,
    required this.purchasePrice,
    required this.salePrice,
    this.stockQuantity = 0,
    this.minStockAlert = 5,
    this.categoryName,
  });

  bool get isLowStock => stockQuantity <= minStockAlert;

  double get profitMargin =>
      salePrice > 0 ? ((salePrice - purchasePrice) / salePrice) * 100 : 0;

  double get profitAmount => salePrice - purchasePrice;

  factory Product.fromMap(Map<String, dynamic> m) => Product(
    id: m['id'] as int?,
    categoryId: m['categoryId'] as int,
    name: m['name'] as String,
    barcode: m['barcode'] as String?,
    purchasePrice: (m['purchasePrice'] as num).toDouble(),
    salePrice: (m['salePrice'] as num).toDouble(),
    stockQuantity: m['stockQuantity'] as int? ?? 0,
    minStockAlert: m['minStockAlert'] as int? ?? 5,
    categoryName: m['categoryName'] as String?,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'categoryId': categoryId,
    'name': name,
    if (barcode != null) 'barcode': barcode,
    'purchasePrice': purchasePrice,
    'salePrice': salePrice,
    'stockQuantity': stockQuantity,
    'minStockAlert': minStockAlert,
  };

  Product copyWith({
    int? id,
    int? categoryId,
    String? name,
    String? barcode,
    double? purchasePrice,
    double? salePrice,
    int? stockQuantity,
    int? minStockAlert,
    String? categoryName,
  }) => Product(
    id: id ?? this.id,
    categoryId: categoryId ?? this.categoryId,
    name: name ?? this.name,
    barcode: barcode ?? this.barcode,
    purchasePrice: purchasePrice ?? this.purchasePrice,
    salePrice: salePrice ?? this.salePrice,
    stockQuantity: stockQuantity ?? this.stockQuantity,
    minStockAlert: minStockAlert ?? this.minStockAlert,
    categoryName: categoryName ?? this.categoryName,
  );
}
