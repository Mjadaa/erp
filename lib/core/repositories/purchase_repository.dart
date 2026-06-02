import '../database/database_helper.dart';
import '../models/invoice_models.dart';

const _accCash = 1;
const _accInventory = 3;
const _accAP = 4;

class PurchaseRepository {
  Future<String> _nextNumber(dynamic db) async {
    final year = DateTime.now().year;
    final r = await db.rawQuery(
      'SELECT COUNT(*) FROM PurchaseInvoices WHERE invoiceNumber LIKE ?',
      ['PO-$year-%'],
    );
    final count = (r.first.values.first as int) + 1;
    return 'PO-$year-${count.toString().padLeft(4, '0')}';
  }

  /// Purchase invoice:
  ///  DR Inventory     = totalAmount
  ///  CR Cash          = paidAmount
  ///  CR AP (Supplier) = remaining
  Future<int> createInvoice(PurchaseInvoice invoice, List<PurchaseItem> items) async {
    final db = await DatabaseHelper.instance.database;

    // Safety: ensure default warehouse + accounts exist (idempotent)
    await db.execute(
      "INSERT OR IGNORE INTO Warehouses (id,name,location) VALUES (1,'المستودع الرئيسي',NULL)",
    );
    for (final row in [
      "(1,'1001','النقدية','ASSET',0.0)",
      "(3,'1200','مخزون البضاعة','ASSET',0.0)",
      "(4,'2000','الموردون / الذمم الدائنة','LIABILITY',0.0)",
    ]) {
      await db.execute(
        'INSERT OR IGNORE INTO Accounts (id,code,accountName,accountType,balance) VALUES $row',
      );
    }

    return await db.transaction((txn) async {
      final invNum = await _nextNumber(txn);
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final date = invoice.date.isNotEmpty ? invoice.date : today;

      final invoiceId = await txn.insert('PurchaseInvoices', {
        'invoiceNumber': invNum,
        'supplierId': invoice.supplierId,
        'userId': invoice.userId,
        'date': date,
        'discount': invoice.discount,
        'totalAmount': invoice.totalAmount,
        'paidAmount': invoice.paidAmount,
        'status': invoice.status,
        'notes': invoice.notes,
      });

      for (final item in items) {
        await txn.insert('PurchaseItems', {
          'invoiceId': invoiceId,
          'productId': item.productId,
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
          'discount': item.discount,
          'total': item.total,
          'costPrice': item.unitPrice,
        });

        // Increase stock + update purchase price
        await txn.rawUpdate(
          'UPDATE Products SET stockQuantity = stockQuantity + ?, purchasePrice = ? WHERE id = ?',
          [item.quantity, item.unitPrice, item.productId],
        );

        await txn.insert('InventoryTransactions', {
          'productId': item.productId,
          'warehouseId': 1,
          'transactionType': 'IN',
          'quantity': item.quantity,
          'date': date,
          'notes': 'فاتورة مشتريات: $invNum',
        });
      }

      final remaining = invoice.totalAmount - invoice.paidAmount;
      if (remaining > 0) {
        await txn.rawUpdate(
          'UPDATE Suppliers SET balance = balance + ? WHERE id = ?',
          [remaining, invoice.supplierId],
        );
      }

      // Journal entry
      final entryId = await txn.insert('JournalEntries', {
        'date': date,
        'description': 'فاتورة مشتريات: $invNum',
        'totalDebit': invoice.totalAmount,
        'totalCredit': invoice.totalAmount,
        'reference': invNum,
      });

      Future<void> line(int acc, double dr, double cr) => txn.insert(
        'JournalEntryLines',
        {'journalEntryId': entryId, 'accountId': acc, 'debit': dr, 'credit': cr},
      );

      await line(_accInventory, invoice.totalAmount, 0);
      await txn.rawUpdate(
        'UPDATE Accounts SET balance = balance + ? WHERE id = ?',
        [invoice.totalAmount, _accInventory],
      );

      if (invoice.paidAmount > 0) {
        await line(_accCash, 0, invoice.paidAmount);
        await txn.rawUpdate(
          'UPDATE Accounts SET balance = balance - ? WHERE id = ?',
          [invoice.paidAmount, _accCash],
        );
      }
      if (remaining > 0) {
        await line(_accAP, 0, remaining);
        await txn.rawUpdate(
          'UPDATE Accounts SET balance = balance + ? WHERE id = ?',
          [remaining, _accAP],
        );
      }

      return invoiceId;
    });
  }

  Future<List<PurchaseInvoice>> getInvoices({String? status, String? search}) async {
    final db = await DatabaseHelper.instance.database;
    final where = <String>[];
    final args = <dynamic>[];
    if (status != null && status != 'ALL') {
      where.add('pi.status = ?');
      args.add(status);
    }
    if (search != null && search.isNotEmpty) {
      where.add('(s.name LIKE ? OR pi.invoiceNumber LIKE ?)');
      args.addAll(['%$search%', '%$search%']);
    }
    final whereStr = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final rows = await db.rawQuery('''
      SELECT pi.*, s.name AS supplierName
      FROM PurchaseInvoices pi
      LEFT JOIN Suppliers s ON pi.supplierId = s.id
      $whereStr
      ORDER BY pi.id DESC
    ''', args);
    return rows.map((m) => PurchaseInvoice.fromMap(m)).toList();
  }

  Future<Map<String, dynamic>> getMonthlyStats() async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final prefix = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final r = await db.rawQuery('''
      SELECT COALESCE(SUM(totalAmount),0) AS total,
             COALESCE(SUM(paidAmount),0)  AS paid,
             COUNT(*) AS count
      FROM PurchaseInvoices WHERE date LIKE ?
    ''', ['$prefix%']);
    final row = r.first;
    return {
      'total': (row['total'] as num).toDouble(),
      'paid': (row['paid'] as num).toDouble(),
      'count': row['count'] as int,
    };
  }
}
