import '../database/database_helper.dart';
import '../models/invoice_models.dart';

class HrRepository {
  Future<List<Employee>> getEmployees({String? search}) async {
    final db = await DatabaseHelper.instance.database;
    if (search != null && search.isNotEmpty) {
      final rows = await db.rawQuery(
        'SELECT * FROM Employees WHERE name LIKE ? OR position LIKE ? ORDER BY name ASC',
        ['%$search%', '%$search%'],
      );
      return rows.map(Employee.fromMap).toList();
    }
    final rows = await db.query('Employees', orderBy: 'name ASC');
    return rows.map(Employee.fromMap).toList();
  }

  Future<int> insertEmployee(Employee e) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('Employees', e.toMap());
  }

  Future<void> updateEmployee(Employee e) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('Employees', e.toMap(), where: 'id=?', whereArgs: [e.id]);
  }

  Future<void> deleteEmployee(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('Employees', where: 'id=?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>> getStats() async {
    final db = await DatabaseHelper.instance.database;
    final r = await db.rawQuery(
      'SELECT COUNT(*) AS count, COALESCE(SUM(salary),0) AS totalSalaries FROM Employees',
    );
    return {
      'count': r.first['count'] as int,
      'totalSalaries': (r.first['totalSalaries'] as num).toDouble(),
    };
  }
}
