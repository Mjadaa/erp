import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/models/inventory_models.dart';
import '../../../core/repositories/inventory_repository.dart';
import '../../../core/theme/app_theme.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _repo = InventoryRepository();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(tabController: _tab),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _ProductsTab(repo: _repo),
              _CategoriesTab(repo: _repo),
              _WarehousesTab(repo: _repo),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final TabController tabController;
  const _Header({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                'inventory'.tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.sidebarTextMuted,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            tabs: [
              Tab(text: 'products'.tr()),
              Tab(text: 'categories'.tr()),
              Tab(text: 'warehouses'.tr()),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Products Tab ─────────────────────────────────────────────────────────────

class _ProductsTab extends StatefulWidget {
  final InventoryRepository repo;
  const _ProductsTab({required this.repo});
  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  List<Product> _products = [];
  List<Category> _categories = [];
  bool _loading = true;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final p = await widget.repo.getProducts(search: _search.text);
    final c = await widget.repo.getCategories();
    if (mounted) setState(() { _products = p; _categories = c; _loading = false; });
  }

  Future<void> _showForm([Product? existing]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ProductDialog(
        product: existing,
        categories: _categories,
        repo: widget.repo,
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Product p) async {
    final ok = await _confirmDelete(context, p.name);
    if (!ok) return;
    await widget.repo.deleteProduct(p.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      hintText: 'search_products'.tr(),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (_) => _load(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('add_product'.tr()),
                onPressed: () => _showForm(),
              ),
            ],
          ),
        ),
        // Table header
        _TableHeader(columns: [
          'product_name'.tr(), 'category'.tr(), 'stock'.tr(),
          'purchase_price'.tr(), 'sale_price'.tr(), 'profit_margin'.tr(), '',
        ]),
        // Rows
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _products.isEmpty
                  ? _EmptyState(message: 'no_products'.tr())
                  : ListView.builder(
                      itemCount: _products.length,
                      itemBuilder: (_, i) {
                        final p = _products[i];
                        return _ProductRow(
                          product: p,
                          onEdit: () => _showForm(p),
                          onDelete: () => _delete(p),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ProductRow({required this.product, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isLow = product.isLowStock;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
        color: isLow ? AppColors.warningBg.withAlpha(60) : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      if (product.barcode != null)
                        Text(product.barcode!, style: const TextStyle(color: AppColors.sidebarTextMuted, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              product.categoryName ?? '-',
              style: const TextStyle(color: AppColors.sidebarTextMuted, fontSize: 12),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isLow ? AppColors.warningBg : AppColors.successBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLow) const Icon(Icons.warning_amber_rounded, size: 12, color: AppColors.warning),
                      if (isLow) const SizedBox(width: 4),
                      Text(
                        '${product.stockQuantity}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: isLow ? AppColors.warning : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _PriceCell(product.purchasePrice)),
          Expanded(child: _PriceCell(product.salePrice)),
          Expanded(
            child: Text(
              '${product.profitMargin.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: product.profitMargin >= 20 ? AppColors.success : AppColors.warning,
              ),
            ),
          ),
          Row(
            children: [
              _ActionIcon(Icons.edit_outlined, AppColors.info, onEdit),
              const SizedBox(width: 4),
              _ActionIcon(Icons.delete_outline_rounded, AppColors.danger, onDelete),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductDialog extends StatefulWidget {
  final Product? product;
  final List<Category> categories;
  final InventoryRepository repo;
  const _ProductDialog({this.product, required this.categories, required this.repo});
  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final _form = GlobalKey<FormState>();
  late TextEditingController _name, _barcode, _buyPrice, _sellPrice, _stock, _minStock;
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?.name ?? '');
    _barcode = TextEditingController(text: p?.barcode ?? '');
    _buyPrice = TextEditingController(text: p?.purchasePrice.toStringAsFixed(2) ?? '0.00');
    _sellPrice = TextEditingController(text: p?.salePrice.toStringAsFixed(2) ?? '0.00');
    _stock = TextEditingController(text: '${p?.stockQuantity ?? 0}');
    _minStock = TextEditingController(text: '${p?.minStockAlert ?? 5}');
    _categoryId = p?.categoryId ?? (widget.categories.isNotEmpty ? widget.categories.first.id : null);
    _buyPrice.addListener(() => setState(() {}));
    _sellPrice.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_name, _barcode, _buyPrice, _sellPrice, _stock, _minStock]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _margin {
    final buy = double.tryParse(_buyPrice.text) ?? 0;
    final sell = double.tryParse(_sellPrice.text) ?? 0;
    return sell > 0 ? ((sell - buy) / sell) * 100 : 0;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final p = Product(
      id: widget.product?.id,
      categoryId: _categoryId!,
      name: _name.text.trim(),
      barcode: _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
      purchasePrice: double.parse(_buyPrice.text),
      salePrice: double.parse(_sellPrice.text),
      stockQuantity: int.parse(_stock.text),
      minStockAlert: int.parse(_minStock.text),
    );
    if (widget.product == null) {
      await widget.repo.insertProduct(p);
    } else {
      await widget.repo.updateProduct(p);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return AlertDialog(
      title: Text(isEdit ? 'edit_product'.tr() : 'add_product'.tr()),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FormRow(children: [
                  _DialogField(label: 'product_name'.tr(), ctrl: _name, required: true),
                  _DialogField(label: 'barcode'.tr(), ctrl: _barcode),
                ]),
                const SizedBox(height: 14),
                _DialogLabel('category'.tr()),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  value: _categoryId,
                  decoration: const InputDecoration(),
                  items: widget.categories.map((c) =>
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ).toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                  validator: (v) => v == null ? 'error_field_required'.tr() : null,
                ),
                const SizedBox(height: 14),
                _FormRow(children: [
                  _DialogField(
                    label: 'purchase_price'.tr(),
                    ctrl: _buyPrice,
                    keyboardType: TextInputType.number,
                    required: true,
                  ),
                  _DialogField(
                    label: 'sale_price'.tr(),
                    ctrl: _sellPrice,
                    keyboardType: TextInputType.number,
                    required: true,
                  ),
                ]),
                const SizedBox(height: 8),
                // Profit margin badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _margin >= 20 ? AppColors.successBg : AppColors.warningBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.trending_up_rounded,
                        size: 16,
                        color: _margin >= 20 ? AppColors.success : AppColors.warning,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${'profit_margin'.tr()}: ${_margin.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _margin >= 20 ? AppColors.success : AppColors.warning,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _FormRow(children: [
                  _DialogField(
                    label: 'current_stock'.tr(),
                    ctrl: _stock,
                    keyboardType: TextInputType.number,
                    required: true,
                  ),
                  _DialogField(
                    label: 'min_stock_alert'.tr(),
                    ctrl: _minStock,
                    keyboardType: TextInputType.number,
                    required: true,
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr())),
        FilledButton(onPressed: _save, child: Text('save'.tr())),
      ],
    );
  }
}

// ─── Categories Tab ───────────────────────────────────────────────────────────

class _CategoriesTab extends StatefulWidget {
  final InventoryRepository repo;
  const _CategoriesTab({required this.repo});
  @override
  State<_CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<_CategoriesTab> {
  List<Category> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await widget.repo.getCategories();
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  Future<void> _showForm([Category? existing]) async {
    final ctrl = TextEditingController(text: existing?.name ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'add_category'.tr() : 'edit_category'.tr()),
        content: SizedBox(
          width: 340,
          child: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(labelText: 'category_name'.tr()),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr())),
          FilledButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              if (existing == null) {
                await widget.repo.insertCategory(Category(name: ctrl.text.trim()));
              } else {
                await widget.repo.updateCategory(existing.copyWith(name: ctrl.text.trim()));
              }
              if (context.mounted) Navigator.pop(context, true);
            },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_items.length} ${'categories'.tr()}',
                  style: const TextStyle(color: AppColors.sidebarTextMuted, fontSize: 13)),
              FilledButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('add_category'.tr()),
                onPressed: () => _showForm(),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final c = _items[i];
                    return ListTile(
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.label_outline_rounded, size: 18, color: AppColors.primary),
                      ),
                      title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ActionIcon(Icons.edit_outlined, AppColors.info, () => _showForm(c)),
                          _ActionIcon(Icons.delete_outline_rounded, AppColors.danger, () async {
                            final ok = await _confirmDelete(context, c.name);
                            if (ok) { await widget.repo.deleteCategory(c.id!); _load(); }
                          }),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── Warehouses Tab ───────────────────────────────────────────────────────────

class _WarehousesTab extends StatefulWidget {
  final InventoryRepository repo;
  const _WarehousesTab({required this.repo});
  @override
  State<_WarehousesTab> createState() => _WarehousesTabState();
}

class _WarehousesTabState extends State<_WarehousesTab> {
  List<Warehouse> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await widget.repo.getWarehouses();
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  Future<void> _showForm([Warehouse? existing]) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final locCtrl = TextEditingController(text: existing?.location ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'add_warehouse'.tr() : 'edit_warehouse'.tr()),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, autofocus: true, decoration: InputDecoration(labelText: 'warehouse_name'.tr())),
              const SizedBox(height: 14),
              TextField(controller: locCtrl, decoration: InputDecoration(labelText: 'warehouse_location'.tr())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr())),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final w = Warehouse(id: existing?.id, name: nameCtrl.text.trim(), location: locCtrl.text.trim().isEmpty ? null : locCtrl.text.trim());
              if (existing == null) await widget.repo.insertWarehouse(w);
              else await widget.repo.updateWarehouse(w);
              nameCtrl.dispose(); locCtrl.dispose();
              if (context.mounted) Navigator.pop(context, true);
            },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_items.length} ${'warehouses'.tr()}',
                  style: const TextStyle(color: AppColors.sidebarTextMuted, fontSize: 13)),
              FilledButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('add_warehouse'.tr()),
                onPressed: () => _showForm(),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final w = _items[i];
                    return ListTile(
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: AppColors.info.withAlpha(15), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.warehouse_outlined, size: 18, color: AppColors.info),
                      ),
                      title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: w.location != null ? Text(w.location!) : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ActionIcon(Icons.edit_outlined, AppColors.info, () => _showForm(w)),
                          _ActionIcon(Icons.delete_outline_rounded, AppColors.danger, () async {
                            final ok = await _confirmDelete(context, w.name);
                            if (ok) { await widget.repo.deleteWarehouse(w.id!); _load(); }
                          }),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

Future<bool> _confirmDelete(BuildContext context, String name) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('confirm_delete'.tr()),
      content: Text('${'delete_confirm_msg'.tr()} "$name"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('cancel'.tr())),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.pop(context, true),
          child: Text('delete'.tr()),
        ),
      ],
    ),
  );
  return result == true;
}

class _TableHeader extends StatelessWidget {
  final List<String> columns;
  const _TableHeader({required this.columns});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.contentBg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: columns.asMap().entries.map((e) {
          final isLast = e.key == columns.length - 1;
          return isLast
              ? Text(e.value, style: _headerStyle)
              : Expanded(
                  child: Text(e.value, style: _headerStyle),
                );
        }).toList(),
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.sidebarTextMuted,
    letterSpacing: 0.4,
  );
}

class _PriceCell extends StatelessWidget {
  final double price;
  const _PriceCell(this.price);
  @override
  Widget build(BuildContext context) => Text(
    NumberFormat('#,##0.##').format(price),
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  );
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionIcon(this.icon, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(icon, size: 18, color: color),
    onPressed: onTap,
    style: IconButton.styleFrom(
      backgroundColor: color.withAlpha(15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox_rounded, size: 56, color: AppColors.cardBorder),
        const SizedBox(height: 12),
        Text(message, style: const TextStyle(color: AppColors.sidebarTextMuted)),
      ],
    ),
  );
}

class _FormRow extends StatelessWidget {
  final List<Widget> children;
  const _FormRow({required this.children});
  @override
  Widget build(BuildContext context) => Row(
    children: children
        .expand((w) => [Expanded(child: w), const SizedBox(width: 14)])
        .toList()
      ..removeLast(),
  );
}

class _DialogField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final bool required;
  final TextInputType? keyboardType;
  const _DialogField({required this.label, required this.ctrl, this.required = false, this.keyboardType});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _DialogLabel(label),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: const InputDecoration(),
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'error_field_required'.tr() : null : null,
      ),
    ],
  );
}

class _DialogLabel extends StatelessWidget {
  final String text;
  const _DialogLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
  );
}
