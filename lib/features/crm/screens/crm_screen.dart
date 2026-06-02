import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/models/crm_models.dart';
import '../../../core/repositories/crm_repository.dart';
import '../../../core/theme/app_theme.dart';

class CrmScreen extends StatefulWidget {
  const CrmScreen({super.key});
  @override
  State<CrmScreen> createState() => _CrmScreenState();
}

class _CrmScreenState extends State<CrmScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
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
        _CrmHeader(tabController: _tab),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: const [
              _CustomersTab(),
              _SuppliersTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _CrmHeader extends StatelessWidget {
  final TabController tabController;
  const _CrmHeader({required this.tabController});

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
              const Icon(Icons.people_alt_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Text('crm'.tr(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.sidebarTextMuted,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            tabs: [Tab(text: 'customers'.tr()), Tab(text: 'suppliers'.tr())],
          ),
        ],
      ),
    );
  }
}

// ─── Customers Tab ────────────────────────────────────────────────────────────

class _CustomersTab extends StatefulWidget {
  const _CustomersTab();
  @override
  State<_CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends State<_CustomersTab> {
  final _repo = CrmRepository();
  List<Customer> items = [];
  bool _loading = true;
  final _search = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final loaded = await _repo.getCustomers(search: _search.text);
    if (mounted) setState(() { items = loaded; _loading = false; });
  }

  Future<void> _showForm([Customer? existing]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ContactDialog(
        title: existing == null ? 'add_customer'.tr() : 'edit_customer'.tr(),
        name: existing?.name,
        phone: existing?.phone,
        email: existing?.email,
        address: existing?.address,
        onSave: (name, phone, email, address) async {
          final c = Customer(id: existing?.id, name: name, phone: phone, email: email, address: address, balance: existing?.balance ?? 0);
          if (existing == null) await _repo.insertCustomer(c);
          else await _repo.updateCustomer(c);
        },
      ),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return _ContactList(
      items: items,
      loading: _loading,
      search: _search,
      onSearch: (_) => _load(),
      addLabel: 'add_customer'.tr(),
      onAdd: () => _showForm(),
      onEdit: (i) => _showForm(items[i]),
      onDelete: (i) async {
        final ok = await _confirmDelete(context, items[i].name);
        if (ok) { await _repo.deleteCustomer(items[i].id!); _load(); }
      },
      emptyMsg: 'no_customers'.tr(),
      icon: Icons.person_rounded,
      iconColor: AppColors.primary,
    );
  }
}

// ─── Suppliers Tab ────────────────────────────────────────────────────────────

class _SuppliersTab extends StatefulWidget {
  const _SuppliersTab();
  @override
  State<_SuppliersTab> createState() => _SuppliersTabState();
}

class _SuppliersTabState extends State<_SuppliersTab> {
  final _repo = CrmRepository();
  List<Supplier> items = [];
  bool _loading = true;
  final _search = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final loaded = await _repo.getSuppliers(search: _search.text);
    if (mounted) setState(() { items = loaded; _loading = false; });
  }

  Future<void> _showForm([Supplier? existing]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ContactDialog(
        title: existing == null ? 'add_supplier'.tr() : 'edit_supplier'.tr(),
        name: existing?.name,
        phone: existing?.phone,
        email: existing?.email,
        address: existing?.address,
        onSave: (name, phone, email, address) async {
          final s = Supplier(id: existing?.id, name: name, phone: phone, email: email, address: address, balance: existing?.balance ?? 0);
          if (existing == null) await _repo.insertSupplier(s);
          else await _repo.updateSupplier(s);
        },
      ),
    );
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return _ContactList(
      items: items,
      loading: _loading,
      search: _search,
      onSearch: (_) => _load(),
      addLabel: 'add_supplier'.tr(),
      onAdd: () => _showForm(),
      onEdit: (i) => _showForm(items[i]),
      onDelete: (i) async {
        final ok = await _confirmDelete(context, items[i].name);
        if (ok) { await _repo.deleteSupplier(items[i].id!); _load(); }
      },
      emptyMsg: 'no_suppliers'.tr(),
      icon: Icons.local_shipping_rounded,
      iconColor: const Color(0xFF7C3AED),
    );
  }
}

// ─── Shared list widget ───────────────────────────────────────────────────────

class _ContactList extends StatelessWidget {
  final List items;
  final bool loading;
  final TextEditingController search;
  final ValueChanged<String> onSearch;
  final String addLabel;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;
  final String emptyMsg;
  final IconData icon;
  final Color iconColor;

  const _ContactList({
    required this.items,
    required this.loading,
    required this.search,
    required this.onSearch,
    required this.addLabel,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.emptyMsg,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: search,
                    decoration: InputDecoration(
                      hintText: 'search'.tr(),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: onSearch,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(addLabel),
                onPressed: onAdd,
              ),
            ],
          ),
        ),
        // Table header
        Container(
          color: AppColors.contentBg,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            children: [
              Expanded(flex: 3, child: _hdr('contact_name'.tr())),
              Expanded(flex: 2, child: _hdr('phone'.tr())),
              Expanded(flex: 2, child: _hdr('email'.tr())),
              Expanded(flex: 2, child: _hdr('balance'.tr())),
              _hdr(''),
            ],
          ),
        ),
        const Divider(height: 1),
        if (loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (items.isEmpty)
          Expanded(child: Center(child: Text(emptyMsg, style: const TextStyle(color: AppColors.sidebarTextMuted))))
        else
          Expanded(
            child: ListView.separated(
              separatorBuilder: (_, index) => const Divider(height: 1),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i];
                final name = item is Customer ? item.name : (item as Supplier).name;
                final phone = item is Customer ? item.phone : (item as Supplier).phone;
                final email = item is Customer ? item.email : (item as Supplier).email;
                final balance = item is Customer ? item.balance : (item as Supplier).balance;
                final hasDebt = balance > 0;

                return Container(
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
                                color: iconColor.withAlpha(15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  name[0].toUpperCase(),
                                  style: TextStyle(fontWeight: FontWeight.w700, color: iconColor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                      Expanded(flex: 2, child: _cell(phone ?? '-')),
                      Expanded(flex: 2, child: _cell(email ?? '-')),
                      Expanded(
                        flex: 2,
                        child: hasDebt
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.dangerBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  NumberFormat('#,##0.##').format(balance),
                                  style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.successBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'settled'.tr(),
                                  style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 12),
                                ),
                              ),
                      ),
                      Row(
                        children: [
                          _iconBtn(Icons.edit_outlined, AppColors.info, () => onEdit(i)),
                          const SizedBox(width: 4),
                          _iconBtn(Icons.delete_outline_rounded, AppColors.danger, () => onDelete(i)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _hdr(String t) => Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.sidebarTextMuted, letterSpacing: 0.4));
  Widget _cell(String t) => Text(t, style: const TextStyle(fontSize: 12, color: AppColors.sidebarTextMuted));
  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => IconButton(
    icon: Icon(icon, size: 17, color: color),
    onPressed: onTap,
    style: IconButton.styleFrom(backgroundColor: color.withAlpha(15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
  );
}

// ─── Contact dialog ───────────────────────────────────────────────────────────

class _ContactDialog extends StatefulWidget {
  final String title;
  final String? name, phone, email, address;
  final Future<void> Function(String name, String? phone, String? email, String? address) onSave;
  const _ContactDialog({required this.title, this.name, this.phone, this.email, this.address, required this.onSave});
  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  final _form = GlobalKey<FormState>();
  late TextEditingController _name, _phone, _email, _address;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.name ?? '');
    _phone = TextEditingController(text: widget.phone ?? '');
    _email = TextEditingController(text: widget.email ?? '');
    _address = TextEditingController(text: widget.address ?? '');
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _address]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    await widget.onSave(
      _name.text.trim(),
      _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      _email.text.trim().isEmpty ? null : _email.text.trim(),
      _address.text.trim().isEmpty ? null : _address.text.trim(),
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field('contact_name'.tr(), _name, required: true),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _field('phone'.tr(), _phone)),
                const SizedBox(width: 14),
                Expanded(child: _field('email'.tr(), _email)),
              ]),
              const SizedBox(height: 14),
              _field('address'.tr(), _address),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr())),
        FilledButton(
          onPressed: _loading ? null : _save,
          child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('save'.tr()),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl, {bool required = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          decoration: const InputDecoration(),
          validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'error_field_required'.tr() : null : null,
        ),
      ],
    );
  }
}

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
