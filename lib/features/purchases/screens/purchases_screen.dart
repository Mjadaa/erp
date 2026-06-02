import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../core/models/invoice_models.dart';
import '../../../core/models/crm_models.dart';
import '../../../core/models/inventory_models.dart';
import '../../../core/repositories/purchase_repository.dart';
import '../../../core/repositories/crm_repository.dart';
import '../../../core/repositories/inventory_repository.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

// ─── Entry point ──────────────────────────────────────────────────────────────

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});
  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  bool _showNew = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: _showNew
          ? _NewPurchaseView(
              key: const ValueKey('new'),
              onBack: () => setState(() => _showNew = false),
              onSaved: () => setState(() => _showNew = false),
            )
          : _PurchaseListView(
              key: const ValueKey('list'),
              onNew: () => setState(() => _showNew = true),
            ),
    );
  }
}

// ─── Purchase Invoice List ────────────────────────────────────────────────────

class _PurchaseListView extends StatefulWidget {
  final VoidCallback onNew;
  const _PurchaseListView({super.key, required this.onNew});
  @override
  State<_PurchaseListView> createState() => _PurchaseListViewState();
}

class _PurchaseListViewState extends State<_PurchaseListView> {
  final _repo = PurchaseRepository();
  List<PurchaseInvoice> _invoices = [];
  Map<String, dynamic> _stats = {
    'total': 0.0,
    'paid': 0.0,
    'count': 0,
  };
  bool _loading = true;
  String _statusFilter = 'ALL';
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
    final results = await Future.wait([
      _repo.getInvoices(
        status: _statusFilter == 'ALL' ? null : _statusFilter,
        search: _search.text.isEmpty ? null : _search.text,
      ),
      _repo.getMonthlyStats(),
    ]);
    if (mounted) {
      setState(() {
        _invoices = results[0] as List<PurchaseInvoice>;
        _stats = results[1] as Map<String, dynamic>;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const Divider(height: 1),
        _buildStatsRow(),
        const Divider(height: 1),
        _buildFilterRow(),
        const Divider(height: 1),
        _buildTableHeader(),
        const Divider(height: 1),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_invoices.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'no_purchase_invoices'.tr(),
                style: const TextStyle(color: AppColors.sidebarTextMuted),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemCount: _invoices.length,
              itemBuilder: (ctx, i) => _PurchaseRow(invoice: _invoices[i]),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          const Icon(Icons.local_shipping_rounded, color: Color(0xFF7C3AED)),
          const SizedBox(width: 10),
          Text(
            'purchases'.tr(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          FilledButton.icon(
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text('new_invoice'.tr()),
            onPressed: widget.onNew,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final fmt = NumberFormat('#,##0.##');
    final debt = (_stats['total'] as double) - (_stats['paid'] as double);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          _statCard(
            'monthly_purchases'.tr(),
            fmt.format(_stats['total']),
            const Color(0xFF7C3AED),
            Icons.receipt_long_rounded,
          ),
          const SizedBox(width: 12),
          _statCard(
            'monthly_paid'.tr(),
            fmt.format(_stats['paid']),
            AppColors.success,
            Icons.check_circle_outline_rounded,
          ),
          const SizedBox(width: 12),
          _statCard(
            'monthly_debt'.tr(),
            fmt.format(debt),
            AppColors.warning,
            Icons.hourglass_empty_rounded,
          ),
          const SizedBox(width: 12),
          _statCard(
            'purchase_count'.tr(),
            '${_stats['count']}',
            AppColors.info,
            Icons.numbers_rounded,
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'search'.tr(),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (_) => _load(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          for (final s in ['ALL', 'PAID', 'PARTIAL', 'UNPAID'])
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: _filterChip(s),
            ),
        ],
      ),
    );
  }

  Widget _filterChip(String status) {
    final selected = _statusFilter == status;
    final label = status == 'ALL'
        ? 'all'.tr()
        : status == 'PAID'
            ? 'status_paid'.tr()
            : status == 'PARTIAL'
                ? 'status_partial'.tr()
                : 'status_unpaid'.tr();
    const purple = Color(0xFF7C3AED);
    final color = status == 'ALL'
        ? purple
        : status == 'PAID'
            ? AppColors.success
            : status == 'PARTIAL'
                ? AppColors.warning
                : AppColors.danger;

    return GestureDetector(
      onTap: () {
        setState(() => _statusFilter = status);
        _load();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withAlpha(15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : color.withAlpha(60)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: AppColors.contentBg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 2, child: _hdr('invoice_number'.tr())),
          Expanded(flex: 3, child: _hdr('supplier'.tr())),
          Expanded(flex: 2, child: _hdr('invoice_date'.tr())),
          Expanded(flex: 2, child: _hdr('total'.tr())),
          Expanded(flex: 2, child: _hdr('paid_amount'.tr())),
          Expanded(flex: 2, child: _hdr('status'.tr())),
        ],
      ),
    );
  }

  Widget _hdr(String t) => Text(
        t,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.sidebarTextMuted,
          letterSpacing: 0.4,
        ),
      );
}

class _PurchaseRow extends StatelessWidget {
  final PurchaseInvoice invoice;
  const _PurchaseRow({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##');
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              invoice.invoiceNumber,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7C3AED),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              invoice.supplierName ?? '-',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              invoice.date,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.sidebarTextMuted,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              fmt.format(invoice.totalAmount),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              fmt.format(invoice.paidAmount),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.sidebarTextMuted,
              ),
            ),
          ),
          Expanded(flex: 2, child: _statusBadge(invoice.status)),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final isPaid = status == 'PAID';
    final isPartial = status == 'PARTIAL';
    final label = isPaid
        ? 'status_paid'.tr()
        : isPartial
            ? 'status_partial'.tr()
            : 'status_unpaid'.tr();
    final fg = isPaid
        ? AppColors.success
        : isPartial
            ? AppColors.warning
            : AppColors.danger;
    final bg = isPaid
        ? AppColors.successBg
        : isPartial
            ? AppColors.warningBg
            : AppColors.dangerBg;

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );
  }
}

// ─── New Purchase Invoice ─────────────────────────────────────────────────────

class _PurchaseLineItem {
  final Product product;
  int qty;
  double price;
  double discountPct;
  late final TextEditingController qtyCtrl;
  late final TextEditingController priceCtrl;
  late final TextEditingController discCtrl;

  _PurchaseLineItem({required this.product})
      : qty = 1,
        price = product.purchasePrice,
        discountPct = 0 {
    qtyCtrl = TextEditingController(text: '1');
    priceCtrl = TextEditingController(
      text: product.purchasePrice.toStringAsFixed(2),
    );
    discCtrl = TextEditingController(text: '0');
  }

  void dispose() {
    qtyCtrl.dispose();
    priceCtrl.dispose();
    discCtrl.dispose();
  }

  double get lineTotal => price * qty * (1 - discountPct / 100);
}

class _NewPurchaseView extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSaved;
  const _NewPurchaseView({
    super.key,
    required this.onBack,
    required this.onSaved,
  });
  @override
  State<_NewPurchaseView> createState() => _NewPurchaseViewState();
}

class _NewPurchaseViewState extends State<_NewPurchaseView> {
  final _purchRepo = PurchaseRepository();
  final _crmRepo = CrmRepository();
  final _invRepo = InventoryRepository();

  final List<_PurchaseLineItem> _lines = [];
  List<Supplier> _suppliers = [];
  List<Product> _searchResults = [];
  Supplier? _selectedSupplier;
  String _date = DateTime.now().toIso8601String().substring(0, 10);
  double _invoiceDiscount = 0;
  final _paidCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _discountCtrl = TextEditingController(text: '0');
  final _searchCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  double get _subtotal => _lines.fold(0.0, (s, l) => s + l.lineTotal);
  double get _totalAfterDiscount =>
      (_subtotal - _invoiceDiscount).clamp(0.0, double.infinity);
  double get _paidAmount => double.tryParse(_paidCtrl.text) ?? 0;
  double get _remaining =>
      (_totalAfterDiscount - _paidAmount).clamp(0.0, double.infinity);

  @override
  void initState() {
    super.initState();
    _paidCtrl.addListener(() => setState(() {}));
    _loadSuppliers();
  }

  @override
  void dispose() {
    for (final l in _lines) {
      l.dispose();
    }
    _paidCtrl.dispose();
    _notesCtrl.dispose();
    _discountCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    final list = await _crmRepo.getSuppliers();
    if (mounted) setState(() => _suppliers = list);
  }

  Future<void> _searchProducts(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final results = await _invRepo.getProducts(search: q.trim());
    if (mounted) setState(() => _searchResults = results);
  }

  void _addProduct(Product p) {
    setState(() {
      final idx = _lines.indexWhere((l) => l.product.id == p.id);
      if (idx >= 0) {
        _lines[idx].qty++;
        _lines[idx].qtyCtrl.text = _lines[idx].qty.toString();
      } else {
        _lines.add(_PurchaseLineItem(product: p));
      }
      _searchCtrl.clear();
      _searchResults = [];
    });
    _syncPaid();
  }

  void _removeLine(int i) {
    final line = _lines[i];
    setState(() => _lines.removeAt(i));
    line.dispose();
    _syncPaid();
  }

  void _syncPaid() {
    _paidCtrl.text = _totalAfterDiscount.toStringAsFixed(2);
  }

  Future<void> _savePurchase() async {
    setState(() => _error = null);

    if (_selectedSupplier == null) {
      setState(() => _error = 'error_no_supplier'.tr());
      return;
    }
    if (_lines.isEmpty) {
      setState(() => _error = 'error_no_items'.tr());
      return;
    }

    final userId = context.read<AuthProvider>().currentUser!.id;
    final total = _totalAfterDiscount;
    final paid = _paidAmount.clamp(0.0, total);
    final invoice = PurchaseInvoice(
      supplierId: _selectedSupplier!.id!,
      userId: userId,
      date: _date,
      discount: _invoiceDiscount,
      totalAmount: total,
      paidAmount: paid,
      status: paid >= total
          ? 'PAID'
          : paid > 0
              ? 'PARTIAL'
              : 'UNPAID',
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    final items = _lines
        .map(
          (l) => PurchaseItem(
            productId: l.product.id!,
            productName: l.product.name,
            quantity: l.qty,
            unitPrice: l.price,
            discount: l.discountPct,
            total: l.lineTotal,
          ),
        )
        .toList();

    setState(() => _saving = true);
    try {
      await _purchRepo.createInvoice(invoice, items);
      if (mounted) widget.onSaved();
    } catch (e, st) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString();
        });
      }
      // ignore: avoid_print
      print('SAVE_PURCHASE_ERROR: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(),
        const Divider(height: 1),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: _buildLeftPanel()),
              Container(width: 1, color: AppColors.cardBorder),
              SizedBox(width: 320, child: _buildRightPanel()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 24, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: widget.onBack,
            tooltip: 'back'.tr(),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.local_shipping_rounded,
            color: Color(0xFF7C3AED),
          ),
          const SizedBox(width: 8),
          Text(
            'new_invoice'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          Text(
            _date,
            style: const TextStyle(
              color: AppColors.sidebarTextMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today_rounded, size: 14),
            label: Text('invoice_date'.tr()),
            onPressed: _pickDate,
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(_date),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked.toIso8601String().substring(0, 10));
    }
  }

  Widget _buildLeftPanel() {
    return Container(
      color: AppColors.contentBg,
      child: Column(
        children: [
          _buildProductSearch(),
          if (_searchResults.isNotEmpty) _buildSearchResults(),
          const Divider(height: 1),
          _buildItemsHeader(),
          const Divider(height: 1),
          Expanded(child: _buildItemsTable()),
          const Divider(height: 1),
          _buildSubtotalFooter(),
        ],
      ),
    );
  }

  Widget _buildProductSearch() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: SizedBox(
        height: 42,
        child: TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'search_product'.tr(),
            prefixIcon: const Icon(Icons.search, size: 18),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() {
                      _searchCtrl.clear();
                      _searchResults = [];
                    }),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
          onChanged: _searchProducts,
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      color: Colors.white,
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _searchResults.length,
        itemBuilder: (ctx, i) {
          final p = _searchResults[i];
          return ListTile(
            dense: true,
            leading: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                size: 15,
                color: Color(0xFF7C3AED),
              ),
            ),
            title: Text(
              p.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${'purchase_price'.tr()}: ${NumberFormat('#,##0.##').format(p.purchasePrice)}',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: const Icon(
              Icons.add_circle_rounded,
              color: Color(0xFF7C3AED),
            ),
            onTap: () => _addProduct(p),
          );
        },
      ),
    );
  }

  Widget _buildItemsHeader() {
    return Container(
      color: AppColors.contentBg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 4, child: _hdr('product'.tr())),
          SizedBox(width: 72, child: _hdr('qty'.tr())),
          SizedBox(width: 96, child: _hdr('unit_price'.tr())),
          SizedBox(width: 72, child: _hdr('item_discount'.tr())),
          SizedBox(width: 96, child: _hdr('item_total'.tr())),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _hdr(String t) => Text(
        t,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.sidebarTextMuted,
          letterSpacing: 0.4,
        ),
      );

  Widget _buildItemsTable() {
    if (_lines.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 48,
              color: AppColors.sidebarTextMuted.withAlpha(80),
            ),
            const SizedBox(height: 10),
            Text(
              'no_items_yet'.tr(),
              style: const TextStyle(
                color: AppColors.sidebarTextMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemCount: _lines.length,
      itemBuilder: (ctx, i) => _buildLineRow(i),
    );
  }

  Widget _buildLineRow(int i) {
    final line = _lines[i];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              line.product.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 72,
            child: _lineField(
              line.qtyCtrl,
              onChanged: (v) {
                final n = int.tryParse(v);
                if (n != null && n > 0) {
                  setState(() => line.qty = n);
                  _syncPaid();
                }
              },
            ),
          ),
          SizedBox(
            width: 96,
            child: _lineField(
              line.priceCtrl,
              onChanged: (v) {
                final n = double.tryParse(v);
                if (n != null && n >= 0) {
                  setState(() => line.price = n);
                  _syncPaid();
                }
              },
            ),
          ),
          SizedBox(
            width: 72,
            child: _lineField(
              line.discCtrl,
              onChanged: (v) {
                final n = double.tryParse(v);
                if (n != null && n >= 0 && n <= 100) {
                  setState(() => line.discountPct = n);
                  _syncPaid();
                }
              },
            ),
          ),
          SizedBox(
            width: 96,
            child: Text(
              NumberFormat('#,##0.##').format(line.lineTotal),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7C3AED),
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 16,
                color: AppColors.danger,
              ),
              onPressed: () => _removeLine(i),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.dangerBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineField(
    TextEditingController ctrl, {
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 13),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildSubtotalFooter() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'subtotal'.tr(),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.sidebarTextMuted,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            NumberFormat('#,##0.##').format(_subtotal),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    final fmt = NumberFormat('#,##0.##');

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('supplier'.tr()),
            const SizedBox(height: 8),
            DropdownButtonFormField<Supplier>(
              value: _selectedSupplier,
              isExpanded: true,
              decoration: const InputDecoration(isDense: true),
              hint: Text(
                'select_supplier'.tr(),
                style: const TextStyle(fontSize: 13),
              ),
              items: _suppliers
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.name, style: const TextStyle(fontSize: 13)),
                    ),
                  )
                  .toList(),
              onChanged: (s) => setState(() => _selectedSupplier = s),
            ),
            const SizedBox(height: 18),

            _label('notes'.tr()),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(hintText: 'notes_hint'.tr()),
            ),
            const SizedBox(height: 22),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.contentBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  _summaryRow('subtotal'.tr(), fmt.format(_subtotal)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'discount'.tr(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.sidebarTextMuted,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: _discountCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 7,
                            ),
                          ),
                          onChanged: (v) => setState(() {
                            _invoiceDiscount = double.tryParse(v) ?? 0;
                            _syncPaid();
                          }),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _summaryRow(
                    'total'.tr(),
                    fmt.format(_totalAfterDiscount),
                    bold: true,
                    color: const Color(0xFF7C3AED),
                    size: 16,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'paid_amount'.tr(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.sidebarTextMuted,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _paidCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 7,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _summaryRow(
                    'remaining'.tr(),
                    fmt.format(_remaining),
                    color:
                        _remaining > 0 ? AppColors.danger : AppColors.success,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [_statusBadge()],
                  ),
                ],
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 15,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text('save_purchase'.tr()),
                onPressed: _saving ? null : _savePurchase,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Text(
        t,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
      );

  Widget _summaryRow(
    String label,
    String value, {
    bool bold = false,
    Color? color,
    double size = 13,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: size,
            color: color ?? AppColors.sidebarTextMuted,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: size,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: color ?? const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge() {
    final paid = _paidAmount;
    final total = _totalAfterDiscount;
    final isPaid = paid >= total && total > 0;
    final isPartial = paid > 0 && paid < total;
    final label = isPaid
        ? 'status_paid'.tr()
        : isPartial
            ? 'status_partial'.tr()
            : 'status_unpaid'.tr();
    final fg = isPaid
        ? AppColors.success
        : isPartial
            ? AppColors.warning
            : AppColors.danger;
    final bg = isPaid
        ? AppColors.successBg
        : isPartial
            ? AppColors.warningBg
            : AppColors.dangerBg;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}
