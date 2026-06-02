class SalesInvoice {
  final int? id;
  final String invoiceNumber;
  final int customerId;
  final int userId;
  final String date;
  final double discount; // flat amount
  final double totalAmount;
  final double paidAmount;
  final String status; // PAID | PARTIAL | UNPAID
  final String? notes;
  // joined
  final String? customerName;
  final List<SalesItem> items;

  const SalesInvoice({
    this.id,
    this.invoiceNumber = '',
    required this.customerId,
    required this.userId,
    required this.date,
    this.discount = 0,
    required this.totalAmount,
    required this.paidAmount,
    required this.status,
    this.notes,
    this.customerName,
    this.items = const [],
  });

  double get remainingAmount => totalAmount - paidAmount;

  static String computeStatus(double total, double paid) {
    if (paid >= total) return 'PAID';
    if (paid > 0) return 'PARTIAL';
    return 'UNPAID';
  }

  factory SalesInvoice.fromMap(Map<String, dynamic> m, {List<SalesItem>? items}) =>
      SalesInvoice(
        id: m['id'] as int?,
        invoiceNumber: m['invoiceNumber'] as String? ?? '',
        customerId: m['customerId'] as int,
        userId: m['userId'] as int,
        date: m['date'] as String,
        discount: (m['discount'] as num?)?.toDouble() ?? 0,
        totalAmount: (m['totalAmount'] as num).toDouble(),
        paidAmount: (m['paidAmount'] as num).toDouble(),
        status: m['status'] as String,
        notes: m['notes'] as String?,
        customerName: m['customerName'] as String?,
        items: items ?? const [],
      );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'invoiceNumber': invoiceNumber,
    'customerId': customerId,
    'userId': userId,
    'date': date,
    'discount': discount,
    'totalAmount': totalAmount,
    'paidAmount': paidAmount,
    'status': status,
    if (notes != null) 'notes': notes,
  };
}

class SalesItem {
  final int? id;
  final int invoiceId;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double discount; // percentage per item
  final double total;
  final double costPrice;

  const SalesItem({
    this.id,
    this.invoiceId = 0,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0,
    required this.total,
    required this.costPrice,
  });

  double get totalCost => costPrice * quantity;
  double get profitAmount => total - totalCost;
  double get profitMargin => total > 0 ? (profitAmount / total) * 100 : 0;

  factory SalesItem.fromMap(Map<String, dynamic> m) => SalesItem(
    id: m['id'] as int?,
    invoiceId: m['invoiceId'] as int? ?? 0,
    productId: m['productId'] as int,
    productName: m['productName'] as String? ?? '',
    quantity: m['quantity'] as int,
    unitPrice: (m['unitPrice'] as num).toDouble(),
    discount: (m['discount'] as num?)?.toDouble() ?? 0,
    total: (m['total'] as num).toDouble(),
    costPrice: (m['costPrice'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'invoiceId': invoiceId,
    'productId': productId,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'discount': discount,
    'total': total,
    'costPrice': costPrice,
  };
}

// ─── Purchase Invoice ─────────────────────────────────────────────────────────

class PurchaseInvoice {
  final int? id;
  final String invoiceNumber;
  final int supplierId;
  final int userId;
  final String date;
  final double discount;
  final double totalAmount;
  final double paidAmount;
  final String status;
  final String? notes;
  // joined
  final String? supplierName;
  final List<PurchaseItem> items;

  const PurchaseInvoice({
    this.id,
    this.invoiceNumber = '',
    required this.supplierId,
    required this.userId,
    required this.date,
    this.discount = 0,
    required this.totalAmount,
    required this.paidAmount,
    required this.status,
    this.notes,
    this.supplierName,
    this.items = const [],
  });

  double get remainingAmount => totalAmount - paidAmount;

  factory PurchaseInvoice.fromMap(Map<String, dynamic> m, {List<PurchaseItem>? items}) =>
      PurchaseInvoice(
        id: m['id'] as int?,
        invoiceNumber: m['invoiceNumber'] as String? ?? '',
        supplierId: m['supplierId'] as int,
        userId: m['userId'] as int,
        date: m['date'] as String,
        discount: (m['discount'] as num?)?.toDouble() ?? 0,
        totalAmount: (m['totalAmount'] as num).toDouble(),
        paidAmount: (m['paidAmount'] as num).toDouble(),
        status: m['status'] as String,
        notes: m['notes'] as String?,
        supplierName: m['supplierName'] as String?,
        items: items ?? const [],
      );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'invoiceNumber': invoiceNumber,
    'supplierId': supplierId,
    'userId': userId,
    'date': date,
    'discount': discount,
    'totalAmount': totalAmount,
    'paidAmount': paidAmount,
    'status': status,
    if (notes != null) 'notes': notes,
  };
}

class PurchaseItem {
  final int? id;
  final int invoiceId;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double discount;
  final double total;

  const PurchaseItem({
    this.id,
    this.invoiceId = 0,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0,
    required this.total,
  });

  factory PurchaseItem.fromMap(Map<String, dynamic> m) => PurchaseItem(
    id: m['id'] as int?,
    invoiceId: m['invoiceId'] as int? ?? 0,
    productId: m['productId'] as int,
    productName: m['productName'] as String? ?? '',
    quantity: m['quantity'] as int,
    unitPrice: (m['unitPrice'] as num).toDouble(),
    discount: (m['discount'] as num?)?.toDouble() ?? 0,
    total: (m['total'] as num).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'invoiceId': invoiceId,
    'productId': productId,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'discount': discount,
    'total': total,
    'costPrice': unitPrice,
  };
}

// ─── Account ──────────────────────────────────────────────────────────────────

class Account {
  final int? id;
  final String code;
  final String accountName;
  final String accountType; // ASSET | LIABILITY | EQUITY | REVENUE | EXPENSE
  final double balance;

  const Account({
    this.id,
    required this.code,
    required this.accountName,
    required this.accountType,
    this.balance = 0,
  });

  factory Account.fromMap(Map<String, dynamic> m) => Account(
    id: m['id'] as int?,
    code: m['code'] as String? ?? '',
    accountName: m['accountName'] as String,
    accountType: m['accountType'] as String,
    balance: (m['balance'] as num?)?.toDouble() ?? 0,
  );
}

// ─── Employee ─────────────────────────────────────────────────────────────────

class Employee {
  final int? id;
  final String name;
  final String? position;
  final double salary;
  final String? hireDate;
  final String? phone;
  final String? email;
  final String? nationalId;

  const Employee({
    this.id,
    required this.name,
    this.position,
    required this.salary,
    this.hireDate,
    this.phone,
    this.email,
    this.nationalId,
  });

  factory Employee.fromMap(Map<String, dynamic> m) => Employee(
    id: m['id'] as int?,
    name: m['name'] as String,
    position: m['position'] as String?,
    salary: (m['salary'] as num?)?.toDouble() ?? 0,
    hireDate: m['hireDate'] as String?,
    phone: m['phone'] as String?,
    email: m['email'] as String?,
    nationalId: m['nationalId'] as String?,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    if (position != null) 'position': position,
    'salary': salary,
    if (hireDate != null) 'hireDate': hireDate,
    if (phone != null) 'phone': phone,
    if (email != null) 'email': email,
    if (nationalId != null) 'nationalId': nationalId,
  };

  Employee copyWith({
    int? id, String? name, String? position, double? salary,
    String? hireDate, String? phone, String? email, String? nationalId,
  }) => Employee(
    id: id ?? this.id,
    name: name ?? this.name,
    position: position ?? this.position,
    salary: salary ?? this.salary,
    hireDate: hireDate ?? this.hireDate,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    nationalId: nationalId ?? this.nationalId,
  );
}
