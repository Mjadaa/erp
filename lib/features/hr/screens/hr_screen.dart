import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/models/invoice_models.dart';
import '../../../core/repositories/hr_repository.dart';
import '../../../core/theme/app_theme.dart';

class HrScreen extends StatefulWidget {
  const HrScreen({super.key});
  @override
  State<HrScreen> createState() => _HrScreenState();
}

class _HrScreenState extends State<HrScreen> {
  final _repo = HrRepository();
  List<Employee> _employees = [];
  Map<String, dynamic> _stats = {'count': 0, 'totalSalaries': 0.0};
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
    final results = await Future.wait([
      _repo.getEmployees(search: _search.text.isEmpty ? null : _search.text),
      _repo.getStats(),
    ]);
    if (mounted) {
      setState(() {
        _employees = results[0] as List<Employee>;
        _stats = results[1] as Map<String, dynamic>;
        _loading = false;
      });
    }
  }

  Future<void> _showForm([Employee? existing]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _EmployeeDialog(
        existing: existing,
        onSave: (emp) async {
          if (existing == null) {
            await _repo.insertEmployee(emp);
          } else {
            await _repo.updateEmployee(emp);
          }
        },
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Employee emp) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('confirm_delete'.tr()),
        content: Text('${'delete_confirm_msg'.tr()} "${emp.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _repo.deleteEmployee(emp.id!);
      _load();
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
        _buildSearchRow(),
        const Divider(height: 1),
        _buildTableHeader(),
        const Divider(height: 1),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_employees.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'no_employees'.tr(),
                style: const TextStyle(color: AppColors.sidebarTextMuted),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemCount: _employees.length,
              itemBuilder: (ctx, i) => _EmployeeRow(
                employee: _employees[i],
                onEdit: () => _showForm(_employees[i]),
                onDelete: () => _delete(_employees[i]),
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
          const Icon(Icons.badge_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(
            'hr'.tr(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          FilledButton.icon(
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text('add_employee'.tr()),
            onPressed: () => _showForm(),
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
            'employees'.tr(),
            '${_stats['count']}',
            AppColors.primary,
            Icons.people_rounded,
          ),
          const SizedBox(width: 12),
          _statCard(
            'total_salaries'.tr(),
            fmt.format(_stats['totalSalaries']),
            AppColors.success,
            Icons.payments_rounded,
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
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
        ],
      ),
    );
  }

  Widget _buildSearchRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
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
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: AppColors.contentBg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 3, child: _hdr('employee_name'.tr())),
          Expanded(flex: 2, child: _hdr('position'.tr())),
          Expanded(flex: 2, child: _hdr('salary'.tr())),
          Expanded(flex: 2, child: _hdr('phone'.tr())),
          Expanded(flex: 2, child: _hdr('hire_date'.tr())),
          _hdr(''),
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

class _EmployeeRow extends StatelessWidget {
  final Employee employee;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _EmployeeRow({
    required this.employee,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##');
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      employee.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  employee.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              employee.position ?? '-',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.sidebarTextMuted,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              fmt.format(employee.salary),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              employee.phone ?? '-',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.sidebarTextMuted,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              employee.hireDate ?? '-',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.sidebarTextMuted,
              ),
            ),
          ),
          Row(
            children: [
              _iconBtn(Icons.edit_outlined, AppColors.info, onEdit),
              const SizedBox(width: 4),
              _iconBtn(
                Icons.delete_outline_rounded,
                AppColors.danger,
                onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) =>
      IconButton(
        icon: Icon(icon, size: 17, color: color),
        onPressed: onTap,
        style: IconButton.styleFrom(
          backgroundColor: color.withAlpha(15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      );
}

// ─── Employee Dialog ──────────────────────────────────────────────────────────

class _EmployeeDialog extends StatefulWidget {
  final Employee? existing;
  final Future<void> Function(Employee) onSave;
  const _EmployeeDialog({this.existing, required this.onSave});
  @override
  State<_EmployeeDialog> createState() => _EmployeeDialogState();
}

class _EmployeeDialogState extends State<_EmployeeDialog> {
  final _form = GlobalKey<FormState>();
  late TextEditingController _name,
      _position,
      _salary,
      _phone,
      _email,
      _nationalId,
      _hireDate;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _position = TextEditingController(text: e?.position ?? '');
    _salary = TextEditingController(
      text: e != null ? e.salary.toString() : '',
    );
    _phone = TextEditingController(text: e?.phone ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _nationalId = TextEditingController(text: e?.nationalId ?? '');
    _hireDate = TextEditingController(
      text: e?.hireDate ??
          DateTime.now().toIso8601String().substring(0, 10),
    );
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _position,
      _salary,
      _phone,
      _email,
      _nationalId,
      _hireDate,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);

    final emp = Employee(
      id: widget.existing?.id,
      name: _name.text.trim(),
      position: _position.text.trim().isEmpty ? null : _position.text.trim(),
      salary: double.tryParse(_salary.text) ?? 0,
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      nationalId:
          _nationalId.text.trim().isEmpty ? null : _nationalId.text.trim(),
      hireDate:
          _hireDate.text.trim().isEmpty ? null : _hireDate.text.trim(),
    );

    await widget.onSave(emp);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.existing == null
        ? 'add_employee'.tr()
        : 'edit_employee'.tr();

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field('employee_name'.tr(), _name, required: true),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _field('position'.tr(), _position)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      'salary'.tr(),
                      _salary,
                      required: true,
                      number: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _field('phone'.tr(), _phone)),
                  const SizedBox(width: 12),
                  Expanded(child: _field('email'.tr(), _email)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field('national_id'.tr(), _nationalId),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field('hire_date'.tr(), _hireDate),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr()),
        ),
        FilledButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text('save'.tr()),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    bool number = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: number
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          decoration: const InputDecoration(),
          validator: required
              ? (v) => (v == null || v.trim().isEmpty)
                  ? 'error_field_required'.tr()
                  : null
              : null,
        ),
      ],
    );
  }
}
