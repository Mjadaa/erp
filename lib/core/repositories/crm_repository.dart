import '../database/database_helper.dart';
import '../models/crm_models.dart';

class CrmRepository {
  // ── Customers ──────────────────────────────────────────────────────────────

  Future<List<Customer>> getCustomers({String? search}) async {
    final db = await DatabaseHelper.instance.database;
    if (search != null && search.isNotEmpty) {
      final rows = await db.rawQuery(
        "SELECT * FROM Customers WHERE name LIKE ? OR phone LIKE ? ORDER BY name ASC",
        ['%$search%', '%$search%'],
      );
      return rows.map(Customer.fromMap).toList();
    }
    final rows = await db.query('Customers', orderBy: 'name ASC');
    return rows.map(Customer.fromMap).toList();
  }

  Future<Customer?> getCustomerById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('Customers', where: 'id=?', whereArgs: [id]);
    return rows.isEmpty ? null : Customer.fromMap(rows.first);
  }

  Future<int> insertCustomer(Customer c) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('Customers', c.toMap());
  }

  Future<void> updateCustomer(Customer c) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('Customers', c.toMap(), where: 'id=?', whereArgs: [c.id]);
  }

  Future<void> deleteCustomer(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('Customers', where: 'id=?', whereArgs: [id]);
  }

  Future<int> getCustomerCount() async {
    final db = await DatabaseHelper.instance.database;
    final r = await db.rawQuery('SELECT COUNT(*) FROM Customers');
    return r.first.values.first as int;
  }

  Future<double> getTotalReceivables() async {
    final db = await DatabaseHelper.instance.database;
    final r = await db.rawQuery(
      'SELECT COALESCE(SUM(balance),0) FROM Customers WHERE balance > 0',
    );
    return (r.first.values.first as num?)?.toDouble() ?? 0;
  }

  // ── Suppliers ──────────────────────────────────────────────────────────────

  Future<List<Supplier>> getSuppliers({String? search}) async {
    final db = await DatabaseHelper.instance.database;
    if (search != null && search.isNotEmpty) {
      final rows = await db.rawQuery(
        "SELECT * FROM Suppliers WHERE name LIKE ? OR phone LIKE ? ORDER BY name ASC",
        ['%$search%', '%$search%'],
      );
      return rows.map(Supplier.fromMap).toList();
    }
    final rows = await db.query('Suppliers', orderBy: 'name ASC');
    return rows.map(Supplier.fromMap).toList();
  }

  Future<int> insertSupplier(Supplier s) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('Suppliers', s.toMap());
  }

  Future<void> updateSupplier(Supplier s) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('Suppliers', s.toMap(), where: 'id=?', whereArgs: [s.id]);
  }

  Future<void> deleteSupplier(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('Suppliers', where: 'id=?', whereArgs: [id]);
  }

  Future<double> getTotalPayables() async {
    final db = await DatabaseHelper.instance.database;
    final r = await db.rawQuery(
      'SELECT COALESCE(SUM(balance),0) FROM Suppliers WHERE balance > 0',
    );
    return (r.first.values.first as num?)?.toDouble() ?? 0;
  }
}
