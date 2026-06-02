class Customer {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final double balance; // positive = they owe us (AR)

  const Customer({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.balance = 0.0,
  });

  factory Customer.fromMap(Map<String, dynamic> m) => Customer(
    id: m['id'] as int?,
    name: m['name'] as String,
    phone: m['phone'] as String?,
    email: m['email'] as String?,
    address: m['address'] as String?,
    balance: (m['balance'] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    if (phone != null) 'phone': phone,
    if (email != null) 'email': email,
    if (address != null) 'address': address,
    'balance': balance,
  };

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? balance,
  }) => Customer(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    address: address ?? this.address,
    balance: balance ?? this.balance,
  );
}

class Supplier {
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final double balance; // positive = we owe them (AP)

  const Supplier({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.balance = 0.0,
  });

  factory Supplier.fromMap(Map<String, dynamic> m) => Supplier(
    id: m['id'] as int?,
    name: m['name'] as String,
    phone: m['phone'] as String?,
    email: m['email'] as String?,
    address: m['address'] as String?,
    balance: (m['balance'] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    if (phone != null) 'phone': phone,
    if (email != null) 'email': email,
    if (address != null) 'address': address,
    'balance': balance,
  };

  Supplier copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? balance,
  }) => Supplier(
    id: id ?? this.id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    address: address ?? this.address,
    balance: balance ?? this.balance,
  );
}
