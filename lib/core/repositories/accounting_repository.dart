import '../database/database_helper.dart';
import '../models/invoice_models.dart';

class AccountingRepository {
  Future<List<Account>> getAccounts() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery(
      'SELECT * FROM Accounts ORDER BY code ASC',
    );
    return rows.map(Account.fromMap).toList();
  }

  Future<List<Map<String, dynamic>>> getJournalEntries({
    String? search,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final where = <String>[];
    final args = <dynamic>[];
    if (search != null && search.isNotEmpty) {
      where.add('(description LIKE ? OR reference LIKE ?)');
      args.addAll(['%$search%', '%$search%']);
    }
    final whereStr = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final rows = await db.rawQuery('''
      SELECT * FROM JournalEntries
      $whereStr
      ORDER BY id DESC
    ''', args);
    return rows.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getEntryLines(int entryId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT jel.*, a.accountName, a.code
      FROM JournalEntryLines jel
      LEFT JOIN Accounts a ON jel.accountId = a.id
      WHERE jel.journalEntryId = ?
      ORDER BY jel.id ASC
    ''', [entryId]);
    return rows.cast<Map<String, dynamic>>();
  }
}
