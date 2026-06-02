import '../database/database_helper.dart';
import '../models/inventory_models.dart';

class InventoryRepository {
  Future<List<Category>> getCategories() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('Categories', orderBy: 'name ASC');
    return rows.map(Category.fromMap).toList();
  }

  Future<int> insertCategory(Category c) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('Categories', c.toMap());
  }

  Future<void> updateCategory(Category c) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('Categories', c.toMap(), where: 'id=?', whereArgs: [c.id]);
  }

  Future<void> deleteCategory(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('Categories', where: 'id=?', whereArgs: [id]);
  }

  Future<List<Warehouse>> getWarehouses() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('Warehouses', orderBy: 'name ASC');
    return rows.map(Warehouse.fromMap).toList();
  }

  Future<int> insertWarehouse(Warehouse w) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('Warehouses', w.toMap());
  }

  Future<void> updateWarehouse(Warehouse w) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('Warehouses', w.toMap(), where: 'id=?', whereArgs: [w.id]);
  }

  Future<void> deleteWarehouse(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('Warehouses', where: 'id=?', whereArgs: [id]);
  }

  Future<List<Product>> getProducts({String? search, int? categoryId}) async {
    final db = await DatabaseHelper.instance.database;
    final where = <String>[];
    final args = <dynamic>[];
    if (search != null && search.isNotEmpty) {
      where.add('(p.name LIKE ? OR p.barcode LIKE ?)');
      args.addAll(['%$search%', '%$search%']);
    }
    if (categoryId != null) {
      where.add('p.categoryId = ?');
      args.add(categoryId);
    }
    final whereStr = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final rows = await db.rawQuery('''
      SELECT p.*, c.name AS categoryName
      FROM Products p
      LEFT JOIN Categories c ON p.categoryId = c.id
      $whereStr
      ORDER BY p.name ASC
    ''', args);
    return rows.map(Product.fromMap).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT p.*, c.name AS categoryName
      FROM Products p
      LEFT JOIN Categories c ON p.categoryId = c.id
      WHERE p.id = ?
    ''', [id]);
    return rows.isEmpty ? null : Product.fromMap(rows.first);
  }

  Future<int> insertProduct(Product p) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('Products', p.toMap());
  }

  Future<void> updateProduct(Product p) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('Products', p.toMap(), where: 'id=?', whereArgs: [p.id]);
  }

  Future<void> deleteProduct(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('Products', where: 'id=?', whereArgs: [id]);
  }

  Future<List<Product>> getLowStockProducts() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT p.*, c.name AS categoryName
      FROM Products p
      LEFT JOIN Categories c ON p.categoryId = c.id
      WHERE p.stockQuantity <= p.minStockAlert
      ORDER BY p.stockQuantity ASC
    ''');
    return rows.map(Product.fromMap).toList();
  }

  Future<int> getLowStockCount() async {
    final db = await DatabaseHelper.instance.database;
    final r = await db.rawQuery(
      'SELECT COUNT(*) FROM Products WHERE stockQuantity <= minStockAlert',
    );
    return r.first.values.first as int;
  }
}
