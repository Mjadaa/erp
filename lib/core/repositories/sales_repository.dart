import '../database/database_helper.dart';
import '../models/invoice_models.dart';

/// Fixed account IDs from Chart of Accounts (see database_helper.dart defaults)
const _accCash = 1;
const _accAR = 2;
const _accInventory = 3;
const _accRevenue = 6;
const _accCOGS = 7;

class SalesRepository {
  Future<String> _nextInvoiceNumber(dynamic db) async {
    final year = DateTime.now().year;
    final r = await db.rawQuery(
      'SELECT COUNT(*) FROM SalesInvoices WHERE invoiceNumber LIKE ?',
      ['INV-$year-%'],
    );
    final count = (r.first.values.first as int) + 1;
    return 'INV-$year-${count.toString().padLeft(4, '0')}';
  }

  /// Creates a sales invoice atomically:
  /// 1. Insert invoice + items
  /// 2. Reduce product stock
  /// 3. Update customer AR balance
  /// 4. Create double-entry journal entry
  Future<int> createInvoice(SalesInvoice invoice, List<SalesItem> items) async {
    final db = await DatabaseHelper.instance.database;

    // Safety: ensure default warehouse + accounts exist (idempotent)
    await db.execute(
      "INSERT OR IGNORE INTO Warehouses (id,name,location) VALUES (1,'المستودع الرئيسي',NULL)",
    );
    for (final row in [
      "(1,'1001','النقدية','ASSET',0.0)",
      "(2,'1100','العملاء / الذمم المدينة','ASSET',0.0)",
      "(3,'1200','مخزون البضاعة','ASSET',0.0)",
      "(6,'4000','إيرادات المبيعات','REVENUE',0.0)",
      "(7,'5000','تكلفة البضاعة المباعة','EXPENSE',0.0)",
    ]) {
      await db.execute(
        'INSERT OR IGNORE INTO Accounts (id,code,accountName,accountType,balance) VALUES $row',
      );
    }

    return await db.transaction((txn) async {
      final invoiceNumber = await _nextInvoiceNumber(txn);
      final today = DateTime.now().toIso8601String().substring(0, 10);

      // ── 1. Insert invoice ───────────────────────────────────────────────
      final invoiceId = await txn.insert('SalesInvoices', {
        'invoiceNumber': invoiceNumber,
        'customerId': invoice.customerId,
        'userId': invoice.userId,
        'date': invoice.date.isNotEmpty ? invoice.date : today,
        'discount': invoice.discount,
        'totalAmount': invoice.totalAmount,
        'paidAmount': invoice.paidAmount,
        'status': invoice.status,
        'notes': invoice.notes,
      });

      // ── 2. Insert items, reduce stock, record inventory movements ───────
      double totalCost = 0;
      for (final item in items) {
        await txn.insert('SalesItems', {
          'invoiceId': invoiceId,
          'productId': item.productId,
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
          'discount': item.discount,
          'total': item.total,
          'costPrice': item.costPrice,
        });

        await txn.rawUpdate(
          'UPDATE Products SET stockQuantity = stockQuantity - ? WHERE id = ?',
          [item.quantity, item.productId],
        );

        await txn.insert('InventoryTransactions', {
          'productId': item.productId,
          'warehouseId': 1,
          'transactionType': 'OUT',
          'quantity': item.quantity,
          'date': invoice.date.isNotEmpty ? invoice.date : today,
          'notes': 'فاتورة مبيعات: $invoiceNumber',
        });

        totalCost += item.costPrice * item.quantity;
      }

      // ── 3. Update customer AR balance (if credit/partial) ────────────────
      final remaining = invoice.totalAmount - invoice.paidAmount;
      if (remaining > 0) {
        await txn.rawUpdate(
          'UPDATE Customers SET balance = balance + ? WHERE id = ?',
          [remaining, invoice.customerId],
        );
      }

      // ── 4. Double-entry journal entry ────────────────────────────────────
      //
      //  DR Cash             = paidAmount
      //  DR AR               = remaining
      //  CR Revenue          = totalAmount
      //  DR COGS             = totalCost
      //  CR Inventory        = totalCost
      //
      final totalDebit = invoice.totalAmount + totalCost;
      final entryId = await txn.insert('JournalEntries', {
        'date': invoice.date.isNotEmpty ? invoice.date : today,
        'description': 'فاتورة مبيعات: $invoiceNumber',
        'totalDebit': totalDebit,
        'totalCredit': totalDebit,
        'reference': invoiceNumber,
      });

      Future<void> addLine(int accountId, double debit, double credit) =>
          txn.insert('JournalEntryLines', {
            'journalEntryId': entryId,
            'accountId': accountId,
            'debit': debit,
            'credit': credit,
          });

      if (invoice.paidAmount > 0) {
        await addLine(_accCash, invoice.paidAmount, 0);
        await txn.rawUpdate(
          'UPDATE Accounts SET balance = balance + ? WHERE id = ?',
          [invoice.paidAmount, _accCash],
        );
      }
      if (remaining > 0) {
        await addLine(_accAR, remaining, 0);
        await txn.rawUpdate(
          'UPDATE Accounts SET balance = balance + ? WHERE id = ?',
          [remaining, _accAR],
        );
      }
      await addLine(_accRevenue, 0, invoice.totalAmount);
      await txn.rawUpdate(
        'UPDATE Accounts SET balance = balance + ? WHERE id = ?',
        [invoice.totalAmount, _accRevenue],
      );
      if (totalCost > 0) {
        await addLine(_accCOGS, totalCost, 0);
        await addLine(_accInventory, 0, totalCost);
        await txn.rawUpdate(
          'UPDATE Accounts SET balance = balance + ? WHERE id = ?',
          [totalCost, _accCOGS],
        );
        await txn.rawUpdate(
          'UPDATE Accounts SET balance = balance - ? WHERE id = ?',
          [totalCost, _accInventory],
        );
      }

      return invoiceId;
    });
  }

  Future<List<SalesInvoice>> getInvoices({String? status, String? search}) async {
    final db = await DatabaseHelper.instance.database;
    final where = <String>[];
    final args = <dynamic>[];
    if (status != null && status != 'ALL') {
      where.add('si.status = ?');
      args.add(status);
    }
    if (search != null && search.isNotEmpty) {
      where.add('(c.name LIKE ? OR si.invoiceNumber LIKE ?)');
      args.addAll(['%$search%', '%$search%']);
    }
    final whereStr = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final rows = await db.rawQuery('''
      SELECT si.*, c.name AS customerName
      FROM SalesInvoices si
      LEFT JOIN Customers c ON si.customerId = c.id
      $whereStr
      ORDER BY si.id DESC
    ''', args);
    return rows.map((m) => SalesInvoice.fromMap(m)).toList();
  }

  Future<SalesInvoice?> getInvoiceById(int id) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT si.*, c.name AS customerName
      FROM SalesInvoices si
      LEFT JOIN Customers c ON si.customerId = c.id
      WHERE si.id = ?
    ''', [id]);
    if (rows.isEmpty) return null;

    final itemRows = await db.rawQuery('''
      SELECT sit.*, p.name AS productName
      FROM SalesItems sit
      LEFT JOIN Products p ON sit.productId = p.id
      WHERE sit.invoiceId = ?
    ''', [id]);

    return SalesInvoice.fromMap(
      rows.first,
      items: itemRows.map(SalesItem.fromMap).toList(),
    );
  }

  Future<Map<String, dynamic>> getMonthlyStats() async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final prefix = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final r = await db.rawQuery('''
      SELECT
        COALESCE(SUM(totalAmount),0) AS revenue,
        COALESCE(SUM(paidAmount),0)  AS collected,
        COUNT(*)                      AS count
      FROM SalesInvoices
      WHERE date LIKE ?
    ''', ['$prefix%']);

    final row = r.first;
    final revenue = (row['revenue'] as num).toDouble();
    final collected = (row['collected'] as num).toDouble();
    return {
      'revenue': revenue,
      'collected': collected,
      'pending': revenue - collected,
      'count': row['count'] as int,
    };
  }

  Future<List<Map<String, dynamic>>> getWeeklySales() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT date, COALESCE(SUM(totalAmount),0) AS total
      FROM SalesInvoices
      WHERE date >= date('now','-6 days')
      GROUP BY date
      ORDER BY date ASC
    ''');
    return rows.cast<Map<String, dynamic>>();
  }

  Future<void> recordPayment(int invoiceId, double amount) async {
    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      final rows = await txn.rawQuery(
        'SELECT * FROM SalesInvoices WHERE id = ?',
        [invoiceId],
      );
      if (rows.isEmpty) return;

      final row = rows.first;
      final totalAmount = (row['totalAmount'] as num).toDouble();
      final currentPaid = (row['paidAmount'] as num).toDouble();
      final customerId = row['customerId'] as int;
      final invoiceNumber = row['invoiceNumber'] as String;

      final newPaid = (currentPaid + amount).clamp(0.0, totalAmount);
      final actualPayment = newPaid - currentPaid;
      if (actualPayment <= 0) return;

      final newStatus = SalesInvoice.computeStatus(totalAmount, newPaid);

      await txn.rawUpdate(
        'UPDATE SalesInvoices SET paidAmount = ?, status = ? WHERE id = ?',
        [newPaid, newStatus, invoiceId],
      );

      await txn.rawUpdate(
        'UPDATE Customers SET balance = balance - ? WHERE id = ?',
        [actualPayment, customerId],
      );

      final today = DateTime.now().toIso8601String().substring(0, 10);
      final entryId = await txn.insert('JournalEntries', {
        'date': today,
        'description': 'دفعة على فاتورة: $invoiceNumber',
        'totalDebit': actualPayment,
        'totalCredit': actualPayment,
        'reference': invoiceNumber,
      });

      await txn.insert('JournalEntryLines', {
        'journalEntryId': entryId,
        'accountId': _accCash,
        'debit': actualPayment,
        'credit': 0.0,
      });
      await txn.insert('JournalEntryLines', {
        'journalEntryId': entryId,
        'accountId': _accAR,
        'debit': 0.0,
        'credit': actualPayment,
      });

      await txn.rawUpdate(
        'UPDATE Accounts SET balance = balance + ? WHERE id = ?',
        [actualPayment, _accCash],
      );
      await txn.rawUpdate(
        'UPDATE Accounts SET balance = balance - ? WHERE id = ?',
        [actualPayment, _accAR],
      );
    });
  }
}
