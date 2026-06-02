import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('erp_system.db');
    return _database!;
  }

  static String hashPassword(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  Future<Database> _initDB(String filePath) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, 'ERPSystem', filePath);
    final dir = Directory(join(dbPath.path, 'ERPSystem'));
    if (!await dir.exists()) await dir.create(recursive: true);

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 4,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      ),
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE Users ADD COLUMN mustChangePassword INTEGER NOT NULL DEFAULT 0',
      );
      final users = await db.query('Users');
      for (final user in users) {
        final pass = user['password'] as String;
        if (pass.length != 64) {
          await db.update('Users', {
            'password': hashPassword(pass),
            'mustChangePassword': 1,
          }, where: 'id = ?', whereArgs: [user['id']]);
        }
      }
    }
    if (oldVersion < 3) {
      for (final sql in _v3Alters) {
        try { await db.execute(sql); } catch (_) {}
      }
      await db.execute(_sqlJournalEntryLines);
      await _insertDefaultData(db);
    }
    if (oldVersion < 4) {
      try {
        await db.execute(
          'ALTER TABLE JournalEntries ADD COLUMN reference TEXT',
        );
      } catch (_) {}
      await _insertDefaultData(db);
    }
  }

  static const _v3Alters = [
    "ALTER TABLE Accounts ADD COLUMN code TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE SalesInvoices ADD COLUMN invoiceNumber TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE SalesInvoices ADD COLUMN discount REAL NOT NULL DEFAULT 0",
    "ALTER TABLE SalesInvoices ADD COLUMN notes TEXT",
    "ALTER TABLE SalesItems ADD COLUMN discount REAL NOT NULL DEFAULT 0",
    "ALTER TABLE SalesItems ADD COLUMN costPrice REAL NOT NULL DEFAULT 0",
    "ALTER TABLE PurchaseInvoices ADD COLUMN invoiceNumber TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE PurchaseInvoices ADD COLUMN notes TEXT",
    "ALTER TABLE PurchaseItems ADD COLUMN discount REAL NOT NULL DEFAULT 0",
    "ALTER TABLE PurchaseItems ADD COLUMN costPrice REAL NOT NULL DEFAULT 0",
    "ALTER TABLE Employees ADD COLUMN phone TEXT",
    "ALTER TABLE Employees ADD COLUMN email TEXT",
    "ALTER TABLE Employees ADD COLUMN nationalId TEXT",
  ];

  static const _sqlJournalEntryLines = '''
    CREATE TABLE IF NOT EXISTS JournalEntryLines (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      journalEntryId INTEGER NOT NULL,
      accountId INTEGER NOT NULL,
      debit REAL NOT NULL DEFAULT 0.0,
      credit REAL NOT NULL DEFAULT 0.0,
      description TEXT,
      FOREIGN KEY (journalEntryId) REFERENCES JournalEntries(id) ON DELETE CASCADE,
      FOREIGN KEY (accountId) REFERENCES Accounts(id)
    )
  ''';

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Roles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        permissions TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE Users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        roleId INTEGER NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1,
        mustChangePassword INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (roleId) REFERENCES Roles(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE Employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        position TEXT,
        salary REAL NOT NULL DEFAULT 0,
        hireDate TEXT,
        phone TEXT,
        email TEXT,
        nationalId TEXT,
        userId INTEGER,
        FOREIGN KEY (userId) REFERENCES Users(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE Customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        balance REAL NOT NULL DEFAULT 0.0
      )
    ''');
    await db.execute('''
      CREATE TABLE Suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        balance REAL NOT NULL DEFAULT 0.0
      )
    ''');
    await db.execute('''
      CREATE TABLE Categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE Warehouses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        location TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE Products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoryId INTEGER NOT NULL,
        name TEXT NOT NULL,
        barcode TEXT UNIQUE,
        purchasePrice REAL NOT NULL DEFAULT 0,
        salePrice REAL NOT NULL DEFAULT 0,
        stockQuantity INTEGER NOT NULL DEFAULT 0,
        minStockAlert INTEGER NOT NULL DEFAULT 5,
        FOREIGN KEY (categoryId) REFERENCES Categories(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE InventoryTransactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId INTEGER NOT NULL,
        warehouseId INTEGER NOT NULL DEFAULT 1,
        transactionType TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (productId) REFERENCES Products(id),
        FOREIGN KEY (warehouseId) REFERENCES Warehouses(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE SalesInvoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceNumber TEXT NOT NULL DEFAULT '',
        customerId INTEGER NOT NULL,
        userId INTEGER NOT NULL,
        date TEXT NOT NULL,
        discount REAL NOT NULL DEFAULT 0,
        totalAmount REAL NOT NULL,
        paidAmount REAL NOT NULL,
        status TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (customerId) REFERENCES Customers(id),
        FOREIGN KEY (userId) REFERENCES Users(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE SalesItems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        unitPrice REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL,
        costPrice REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (invoiceId) REFERENCES SalesInvoices(id) ON DELETE CASCADE,
        FOREIGN KEY (productId) REFERENCES Products(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE PurchaseInvoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceNumber TEXT NOT NULL DEFAULT '',
        supplierId INTEGER NOT NULL,
        userId INTEGER NOT NULL,
        date TEXT NOT NULL,
        discount REAL NOT NULL DEFAULT 0,
        totalAmount REAL NOT NULL,
        paidAmount REAL NOT NULL,
        status TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY (supplierId) REFERENCES Suppliers(id),
        FOREIGN KEY (userId) REFERENCES Users(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE PurchaseItems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoiceId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        unitPrice REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL,
        costPrice REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (invoiceId) REFERENCES PurchaseInvoices(id) ON DELETE CASCADE,
        FOREIGN KEY (productId) REFERENCES Products(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE Accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL DEFAULT '',
        accountName TEXT NOT NULL,
        accountType TEXT NOT NULL,
        balance REAL NOT NULL DEFAULT 0.0
      )
    ''');
    await db.execute('''
      CREATE TABLE JournalEntries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        description TEXT NOT NULL,
        totalDebit REAL NOT NULL,
        totalCredit REAL NOT NULL,
        reference TEXT
      )
    ''');
    await db.execute(_sqlJournalEntryLines);

    await _insertDefaultData(db);
  }

  static Future _insertDefaultData(Database db) async {
    // Admin role + user
    final roleCount = (await db.rawQuery('SELECT COUNT(*) FROM Roles'))
        .first
        .values
        .first as int;
    if (roleCount == 0) {
      await db.execute(
        "INSERT INTO Roles (id,name,permissions) VALUES (1,'Admin','ALL')",
      );
      await db.insert('Users', {
        'username': 'admin',
        'password': hashPassword('admin123'),
        'roleId': 1,
        'mustChangePassword': 1,
      });
    }

    // Default category & warehouse
    final catCount = (await db.rawQuery('SELECT COUNT(*) FROM Categories'))
        .first
        .values
        .first as int;
    if (catCount == 0) {
      await db.execute("INSERT INTO Categories (id,name) VALUES (1,'عام')");
      await db.execute(
        "INSERT INTO Warehouses (id,name,location) VALUES (1,'المستودع الرئيسي',NULL)",
      );
    }

    // Chart of Accounts
    final accCount = (await db.rawQuery('SELECT COUNT(*) FROM Accounts'))
        .first
        .values
        .first as int;
    if (accCount == 0) {
      final accounts = [
        {'id': 1, 'code': '1001', 'accountName': 'النقدية', 'accountType': 'ASSET', 'balance': 0.0},
        {'id': 2, 'code': '1100', 'accountName': 'العملاء / الذمم المدينة', 'accountType': 'ASSET', 'balance': 0.0},
        {'id': 3, 'code': '1200', 'accountName': 'مخزون البضاعة', 'accountType': 'ASSET', 'balance': 0.0},
        {'id': 4, 'code': '2000', 'accountName': 'الموردون / الذمم الدائنة', 'accountType': 'LIABILITY', 'balance': 0.0},
        {'id': 5, 'code': '3000', 'accountName': 'رأس المال', 'accountType': 'EQUITY', 'balance': 0.0},
        {'id': 6, 'code': '4000', 'accountName': 'إيرادات المبيعات', 'accountType': 'REVENUE', 'balance': 0.0},
        {'id': 7, 'code': '5000', 'accountName': 'تكلفة البضاعة المباعة', 'accountType': 'EXPENSE', 'balance': 0.0},
        {'id': 8, 'code': '5100', 'accountName': 'مصاريف الرواتب', 'accountType': 'EXPENSE', 'balance': 0.0},
        {'id': 9, 'code': '5200', 'accountName': 'مصاريف تشغيلية عامة', 'accountType': 'EXPENSE', 'balance': 0.0},
      ];
      for (final a in accounts) {
        await db.insert('Accounts', a);
      }
    }
  }

  Future close() async => (await instance.database).close();
}
