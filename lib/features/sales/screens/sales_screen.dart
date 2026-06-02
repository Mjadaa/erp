import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../core/models/invoice_models.dart';
import '../../../core/models/crm_models.dart';
import '../../../core/models/inventory_models.dart';
import '../../../core/repositories/sales_repository.dart';
import '../../../core/repositories/crm_repository.dart';
import '../../../core/repositories/inventory_repository.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/invoice_pdf.dart';

// ─── Entry point ──────────────────────────────────────────────────────────────

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});
  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  bool _showNew = false;

  @override
  Widget build(BuildContext context) {
    if (_showNew) {
      return _NewInvoiceView(
        onBack: () => setState(() => _showNew = false),
        onSaved: () => setState(() => _showNew = false),
      );
    }
    return _InvoiceListView(
      onNew: () => setState(() => _showNew = true),
    );
  }
}

// ─── Invoice List ─────────────────────────────────────────────────────────────

class _InvoiceListView extends StatefulWidget {
  final VoidCallback onNew;
  const _InvoiceListView({required this.onNew});
  @override
  State<_InvoiceListView> createState() => _InvoiceListViewState();
}

class _InvoiceListViewState extends State<_InvoiceListView> {
  final _repo = SalesRepository();
  List<SalesInvoice> _invoices = [];
  Map<String, dynamic> _stats = {
    'revenue': 0.0,
    'collected': 0.0,
    'pending': 0.0,
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
        _invoices = results[0] as List<SalesInvoice>;
        _stats = results[1] as Map<String, dynamic>;
        _loading = false;
      });
    }
  }

  Future<void> _showInvoiceDetail(SalesInvoice invoice) async {
    if (invoice.id == null) return;
    final refreshNeeded = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _InvoiceDetailDialog(invoice: invoice),
    );
    if (refreshNeeded == true) _load();
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
                'no_invoices'.tr(),
                style: const TextStyle(color: AppColors.sidebarTextMuted),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemCount: _invoices.length,
              itemBuilder: (ctx, i) => _InvoiceRow(
                invoice: _invoices[i],
                onTap: () => _showInvoiceDetail(_invoices[i]),
              ),
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
          const Icon(Icons.shopping_cart_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(
            'sales'.tr(),
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
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final fmt = NumberFormat('#,##0.##');
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          _statCard(
            'monthly_revenue'.tr(),
            fmt.format(_stats['revenue']),
            AppColors.primary,
            Icons.trending_up_rounded,
          ),
          const SizedBox(width: 12),
          _statCard(
            'monthly_collected'.tr(),
            fmt.format(_stats['collected']),
            AppColors.success,
            Icons.check_circle_outline_rounded,
          ),
          const SizedBox(width: 12),
          _statCard(
            'monthly_pending'.tr(),
            fmt.format(_stats['pending']),
            AppColors.warning,
            Icons.hourglass_empty_rounded,
          ),
          const SizedBox(width: 12),
          _statCard(
            'invoice_count'.tr(),
            '${_stats['count']}',
            AppColors.info,
            Icons.receipt_long_rounded,
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
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
    final color = status == 'ALL'
        ? AppColors.primary
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
          Expanded(flex: 3, child: _hdr('customer'.tr())),
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

class _InvoiceRow extends StatelessWidget {
  final SalesInvoice invoice;
  final VoidCallback? onTap;
  const _InvoiceRow({required this.invoice, this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##');
    final row = Container(
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
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              invoice.customerName ?? '-',
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
    return onTap != null ? GestureDetector(onTap: onTap, child: row) : row;
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

// ─── New Invoice ──────────────────────────────────────────────────────────────

class _InvoiceLineItem {
  final Product product;
  int qty;
  double price;
  double discountPct;
  late final TextEditingController qtyCtrl;
  late final TextEditingController priceCtrl;
  late final TextEditingController discCtrl;

  _InvoiceLineItem({required this.product})
      : qty = 1,
        price = product.salePrice,
        discountPct = 0 {
    qtyCtrl = TextEditingController(text: '1');
    priceCtrl = TextEditingController(
      text: product.salePrice.toStringAsFixed(2),
    );
    discCtrl = TextEditingController(text: '0');
  }

  void dispose() {
    qtyCtrl.dispose();
    priceCtrl.dispose();
    discCtrl.dispose();
  }

  double get lineTotal => price * qty * (1 - discountPct / 100);
  double get lineCost => product.purchasePrice * qty;
  double get lineProfit => lineTotal - lineCost;
}

class _NewInvoiceView extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onSaved;
  const _NewInvoiceView({
    required this.onBack,
    required this.onSaved,
  });
  @override
  State<_NewInvoiceView> createState() => _NewInvoiceViewState();
}

class _NewInvoiceViewState extends State<_NewInvoiceView> {
  final _salesRepo = SalesRepository();
  final _crmRepo = CrmRepository();
  final _invRepo = InventoryRepository();

  final List<_InvoiceLineItem> _lines = [];
  List<Customer> _customers = [];
  List<Product> _searchResults = [];
  Customer? _selectedCustomer;
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
  double get _totalCost => _lines.fold(0.0, (s, l) => s + l.lineCost);
  double get _grossProfit => _totalAfterDiscount - _totalCost;
  double get _profitMarginPct =>
      _totalAfterDiscount > 0 ? (_grossProfit / _totalAfterDiscount) * 100 : 0;

  @override
  void initState() {
    super.initState();
    _paidCtrl.addListener(() => setState(() {}));
    _loadCustomers();
    _searchProducts('');
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

  Future<void> _loadCustomers() async {
    final list = await _crmRepo.getCustomers();
    if (mounted) setState(() => _customers = list);
  }

  Future<void> _searchProducts(String q) async {
    final results = await _invRepo.getProducts(
      search: q.trim().isEmpty ? null : q.trim(),
    );
    if (mounted) setState(() => _searchResults = results);
  }

  void _addProduct(Product p) {
    setState(() {
      final idx = _lines.indexWhere((l) => l.product.id == p.id);
      if (idx >= 0) {
        _lines[idx].qty++;
        _lines[idx].qtyCtrl.text = _lines[idx].qty.toString();
      } else {
        _lines.add(_InvoiceLineItem(product: p));
      }
      _searchCtrl.clear();
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

  Future<void> _saveInvoice() async {
    setState(() => _error = null);

    if (_selectedCustomer == null) {
      setState(() => _error = 'error_no_customer'.tr());
      return;
    }
    if (_lines.isEmpty) {
      setState(() => _error = 'error_no_items'.tr());
      return;
    }

    final userId = context.read<AuthProvider>().currentUser!.id;
    final total = _totalAfterDiscount;
    final paid = _paidAmount.clamp(0.0, total);
    final status = SalesInvoice.computeStatus(total, paid);

    final invoice = SalesInvoice(
      customerId: _selectedCustomer!.id!,
      userId: userId,
      date: _date,
      discount: _invoiceDiscount,
      totalAmount: total,
      paidAmount: paid,
      status: status,
      notes:
          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    final items = _lines
        .map(
          (l) => SalesItem(
            productId: l.product.id!,
            productName: l.product.name,
            quantity: l.qty,
            unitPrice: l.price,
            discount: l.discountPct,
            total: l.lineTotal,
            costPrice: l.product.purchasePrice,
          ),
        )
        .toList();

    setState(() => _saving = true);
    try {
      await _salesRepo.createInvoice(invoice, items);
      if (mounted) widget.onSaved();
    } catch (e, st) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString();
        });
      }
      // ignore: avoid_print
      print('SAVE_INVOICE_ERROR: $e\n$st');
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
          const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
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
      setState(
        () => _date = picked.toIso8601String().substring(0, 10),
      );
    }
  }

  // ── Left panel ──────────────────────────────────────────────────────────────

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
                    onPressed: () {
                      _searchCtrl.clear();
                      _searchProducts('');
                    },
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
          final noStock = p.stockQuantity <= 0;
          return ListTile(
            dense: true,
            leading: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                size: 15,
                color: AppColors.primary,
              ),
            ),
            title: Text(
              p.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${NumberFormat('#,##0.##').format(p.salePrice)}  •  ${p.stockQuantity} ${'in_stock'.tr()}',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: noStock
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dangerBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'out_of_stock'.tr(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.danger,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.add_circle_rounded,
                    color: AppColors.primary,
                  ),
            onTap: noStock ? null : () => _addProduct(p),
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
              Icons.shopping_cart_outlined,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.product.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${'cost'.tr()}: ${NumberFormat('#,##0.##').format(line.product.purchasePrice)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.sidebarTextMuted,
                  ),
                ),
              ],
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
                color: AppColors.primary,
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
    final fmt = NumberFormat('#,##0.##');
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
            fmt.format(_subtotal),
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

  // ── Right panel ─────────────────────────────────────────────────────────────

  Widget _buildRightPanel() {
    final fmt = NumberFormat('#,##0.##');

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer
            _label('customer'.tr()),
            const SizedBox(height: 8),
            DropdownButtonFormField<Customer>(
              value: _selectedCustomer,
              isExpanded: true,
              decoration: const InputDecoration(isDense: true),
              hint: Text(
                'select_customer'.tr(),
                style: const TextStyle(fontSize: 13),
              ),
              items: _customers
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.name, style: const TextStyle(fontSize: 13)),
                    ),
                  )
                  .toList(),
              onChanged: (c) => setState(() => _selectedCustomer = c),
            ),
            const SizedBox(height: 18),

            // Notes
            _label('notes'.tr()),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(hintText: 'notes_hint'.tr()),
            ),
            const SizedBox(height: 22),

            // Order summary card
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
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
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
                    color: AppColors.primary,
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
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
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
                    color: _remaining > 0 ? AppColors.danger : AppColors.success,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _statusBadge(
                        SalesInvoice.computeStatus(
                          _totalAfterDiscount,
                          _paidAmount,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Profit summary
            if (_lines.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.success.withAlpha(20),
                      AppColors.success.withAlpha(5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.success.withAlpha(50)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'profit_summary'.tr(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _summaryRow(
                      'gross_profit'.tr(),
                      fmt.format(_grossProfit),
                      color: _grossProfit >= 0
                          ? AppColors.success
                          : AppColors.danger,
                    ),
                    const SizedBox(height: 6),
                    _summaryRow(
                      'profit_margin'.tr(),
                      '${_profitMarginPct.toStringAsFixed(1)}%',
                      color: _profitMarginPct >= 0
                          ? AppColors.success
                          : AppColors.danger,
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
                label: Text('save_invoice'.tr()),
                onPressed: _saving ? null : _saveInvoice,
                style: FilledButton.styleFrom(
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
    final textColor = color ?? AppColors.sidebarTextMuted;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: size,
            color: textColor,
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

// ─── Invoice Detail Dialog ────────────────────────────────────────────────────

class _InvoiceDetailDialog extends StatefulWidget {
  final SalesInvoice invoice;
  const _InvoiceDetailDialog({required this.invoice});

  @override
  State<_InvoiceDetailDialog> createState() => _InvoiceDetailDialogState();
}

class _InvoiceDetailDialogState extends State<_InvoiceDetailDialog> {
  final _repo = SalesRepository();
  SalesInvoice? _detail;
  bool _loading = true;
  bool _paymentMode = false;
  final _payCtrl = TextEditingController();
  bool _saving = false;
  bool _printing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _payCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    final detail = await _repo.getInvoiceById(widget.invoice.id!);
    if (mounted) {
      setState(() {
        _detail = detail;
        _loading = false;
      });
    }
  }

  Future<void> _recordPayment() async {
    final amount = double.tryParse(_payCtrl.text) ?? 0;
    if (amount <= 0) {
      setState(() => _error = 'error_payment_amount'.tr());
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repo.recordPayment(widget.invoice.id!, amount);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'error_save_payment'.tr();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 640,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const Divider(height: 1),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildBody(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final inv = widget.invoice;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  inv.invoiceNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  inv.customerName ?? '',
                  style: const TextStyle(
                    color: AppColors.sidebarTextMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _statusChip(inv.status),
          const SizedBox(width: 4),
          IconButton(
            icon: _printing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.print_rounded),
            tooltip: 'print'.tr(),
            onPressed: _printing
                ? null
                : () async {
                    setState(() => _printing = true);
                    try {
                      await printSalesInvoice(_detail ?? inv);
                    } finally {
                      if (mounted) setState(() => _printing = false);
                    }
                  },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final detail = _detail ?? widget.invoice;
    final fmt = NumberFormat('#,##0.##');
    final remaining = detail.remainingAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _metaRow('invoice_date'.tr(), detail.date),
        if (detail.notes != null && detail.notes!.isNotEmpty)
          _metaRow('notes'.tr(), detail.notes!),
        const SizedBox(height: 16),
        Text(
          'invoice_items'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _buildItemsTable(detail.items, fmt),
        ),
        const SizedBox(height: 20),
        _totalRow('subtotal'.tr(), fmt.format(detail.totalAmount + detail.discount)),
        if (detail.discount > 0) ...[
          const SizedBox(height: 6),
          _totalRow('discount'.tr(), '- ${fmt.format(detail.discount)}',
              color: AppColors.danger),
        ],
        const SizedBox(height: 6),
        _totalRow('total'.tr(), fmt.format(detail.totalAmount),
            bold: true, size: 15),
        const SizedBox(height: 6),
        _totalRow('paid_amount'.tr(), fmt.format(detail.paidAmount),
            color: AppColors.success),
        const SizedBox(height: 6),
        _totalRow(
          'remaining'.tr(),
          fmt.format(remaining),
          color: remaining > 0 ? AppColors.danger : AppColors.success,
        ),
        if (detail.status != 'PAID') ...[
          const SizedBox(height: 20),
          if (!_paymentMode)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.payment_rounded, size: 16),
                label: Text('register_payment'.tr()),
                onPressed: () => setState(() {
                  _paymentMode = true;
                  _payCtrl.text = remaining.toStringAsFixed(2);
                }),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.info.withAlpha(60)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('payment_amount'.tr(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _payCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                          decoration: InputDecoration(
                            hintText: 'payment_amount_hint'.tr(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 9),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${'max_label'.tr()}: ${fmt.format(remaining)}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.sidebarTextMuted),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!,
                        style: const TextStyle(
                            color: AppColors.danger, fontSize: 12)),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() {
                            _paymentMode = false;
                            _error = null;
                          }),
                          child: Text('cancel'.tr()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          icon: _saving
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_rounded, size: 16),
                          label: Text('confirm_payment'.tr()),
                          onPressed: _saving ? null : _recordPayment,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildItemsTable(List<SalesItem> items, NumberFormat fmt) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('no_items_yet'.tr(),
            style: const TextStyle(color: AppColors.sidebarTextMuted)),
      );
    }
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: AppColors.contentBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
          ),
          child: Row(
            children: [
              Expanded(flex: 4, child: _th('product'.tr())),
              SizedBox(width: 50, child: _th('qty'.tr())),
              SizedBox(width: 90, child: _th('unit_price'.tr())),
              SizedBox(width: 56, child: _th('item_discount'.tr())),
              SizedBox(width: 90, child: _th('item_total'.tr())),
            ],
          ),
        ),
        ...items.map(
          (item) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.cardBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(item.productName,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                ),
                SizedBox(
                    width: 50,
                    child:
                        Text('${item.quantity}', style: const TextStyle(fontSize: 12))),
                SizedBox(
                    width: 90,
                    child: Text(fmt.format(item.unitPrice),
                        style: const TextStyle(fontSize: 12))),
                SizedBox(
                    width: 56,
                    child: Text('${item.discount.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.sidebarTextMuted))),
                SizedBox(
                    width: 90,
                    child: Text(fmt.format(item.total),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _th(String t) => Text(t,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.sidebarTextMuted));

  Widget _metaRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Text('$label: ',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.sidebarTextMuted)),
            Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _totalRow(String label, String value,
      {bool bold = false, Color? color, double size = 13}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: size, color: AppColors.sidebarTextMuted)),
        Text(value,
            style: TextStyle(
                fontSize: size,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                color: color ?? const Color(0xFF0F172A))),
      ],
    );
  }

  Widget _statusChip(String status) {
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label,
          style:
              TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}
