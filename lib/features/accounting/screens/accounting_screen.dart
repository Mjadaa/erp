import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/models/invoice_models.dart';
import '../../../core/repositories/accounting_repository.dart';
import '../../../core/theme/app_theme.dart';

class AccountingScreen extends StatefulWidget {
  const AccountingScreen({super.key});
  @override
  State<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends State<AccountingScreen>
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
        _AccountingHeader(tabController: _tab),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: const [
              _ChartOfAccountsTab(),
              _JournalEntriesTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountingHeader extends StatelessWidget {
  final TabController tabController;
  const _AccountingHeader({required this.tabController});

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
              const Icon(
                Icons.account_balance_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'accounting'.tr(),
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
              Tab(text: 'accounts'.tr()),
              Tab(text: 'journal_entries'.tr()),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Chart of Accounts ────────────────────────────────────────────────────────

class _ChartOfAccountsTab extends StatefulWidget {
  const _ChartOfAccountsTab();
  @override
  State<_ChartOfAccountsTab> createState() => _ChartOfAccountsTabState();
}

class _ChartOfAccountsTabState extends State<_ChartOfAccountsTab> {
  final _repo = AccountingRepository();
  List<Account> _accounts = [];
  bool _loading = true;

  static const _typeOrder = [
    'ASSET',
    'LIABILITY',
    'EQUITY',
    'REVENUE',
    'EXPENSE',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final loaded = await _repo.getAccounts();
    if (mounted) setState(() { _accounts = loaded; _loading = false; });
  }

  Map<String, List<Account>> get _grouped {
    final map = <String, List<Account>>{};
    for (final t in _typeOrder) {
      map[t] = _accounts.where((a) => a.accountType == t).toList();
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final grouped = _grouped;
    final fmt = NumberFormat('#,##0.##');

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (final type in _typeOrder)
          if (grouped[type]!.isNotEmpty) ...[
            _TypeHeader(type: type),
            const SizedBox(height: 8),
            _AccountsCard(
              accounts: grouped[type]!,
              fmt: fmt,
            ),
            const SizedBox(height: 16),
          ],
      ],
    );
  }
}

class _TypeHeader extends StatelessWidget {
  final String type;
  const _TypeHeader({required this.type});

  static const _icons = {
    'ASSET': Icons.account_balance_wallet_rounded,
    'LIABILITY': Icons.credit_card_rounded,
    'EQUITY': Icons.pie_chart_rounded,
    'REVENUE': Icons.trending_up_rounded,
    'EXPENSE': Icons.trending_down_rounded,
  };

  static const _colors = {
    'ASSET': AppColors.primary,
    'LIABILITY': AppColors.danger,
    'EQUITY': Color(0xFF7C3AED),
    'REVENUE': AppColors.success,
    'EXPENSE': AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    final label = _typeLabel(type);
    final color = _colors[type] ?? AppColors.sidebarTextMuted;
    final icon = _icons[type] ?? Icons.folder_rounded;

    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  String _typeLabel(String t) {
    switch (t) {
      case 'ASSET': return 'type_asset'.tr();
      case 'LIABILITY': return 'type_liability'.tr();
      case 'EQUITY': return 'type_equity'.tr();
      case 'REVENUE': return 'type_revenue'.tr();
      case 'EXPENSE': return 'type_expense'.tr();
      default: return t;
    }
  }
}

class _AccountsCard extends StatelessWidget {
  final List<Account> accounts;
  final NumberFormat fmt;
  const _AccountsCard({required this.accounts, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.contentBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: _hdr('account_code'.tr()),
                ),
                Expanded(child: _hdr('account_name'.tr())),
                SizedBox(
                  width: 120,
                  child: _hdr('balance'.tr()),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (int i = 0; i < accounts.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _AccountRow(account: accounts[i], fmt: fmt),
          ],
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

class _AccountRow extends StatelessWidget {
  final Account account;
  final NumberFormat fmt;
  const _AccountRow({required this.account, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final hasBalance = account.balance != 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              account.code,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.sidebarTextMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              account.accountName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              hasBalance ? fmt.format(account.balance) : '-',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: hasBalance ? AppColors.primary : AppColors.sidebarTextMuted,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Journal Entries ──────────────────────────────────────────────────────────

class _JournalEntriesTab extends StatefulWidget {
  const _JournalEntriesTab();
  @override
  State<_JournalEntriesTab> createState() => _JournalEntriesTabState();
}

class _JournalEntriesTabState extends State<_JournalEntriesTab> {
  final _repo = AccountingRepository();
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;
  final _search = TextEditingController();
  final Set<int> _expanded = {};

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
    final loaded = await _repo.getJournalEntries(
      search: _search.text.isEmpty ? null : _search.text,
    );
    if (mounted) setState(() { _entries = loaded; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
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
        const Divider(height: 1),
        _buildTableHeader(),
        const Divider(height: 1),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_entries.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'no_journal_entries'.tr(),
                style: const TextStyle(color: AppColors.sidebarTextMuted),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemCount: _entries.length,
              itemBuilder: (ctx, i) => _EntryCard(
                entry: _entries[i],
                repo: _repo,
                expanded: _expanded.contains(_entries[i]['id'] as int),
                onToggle: () {
                  final id = _entries[i]['id'] as int;
                  setState(() {
                    if (_expanded.contains(id)) {
                      _expanded.remove(id);
                    } else {
                      _expanded.add(id);
                    }
                  });
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: AppColors.contentBg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 90, child: _hdr('entry_date'.tr())),
          Expanded(child: _hdr('description'.tr())),
          SizedBox(width: 80, child: _hdr('reference'.tr())),
          SizedBox(width: 100, child: _hdr('debit'.tr())),
          SizedBox(width: 100, child: _hdr('credit'.tr())),
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
}

class _EntryCard extends StatefulWidget {
  final Map<String, dynamic> entry;
  final AccountingRepository repo;
  final bool expanded;
  final VoidCallback onToggle;

  const _EntryCard({
    required this.entry,
    required this.repo,
    required this.expanded,
    required this.onToggle,
  });

  @override
  State<_EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<_EntryCard> {
  List<Map<String, dynamic>> _lines = [];
  bool _loadingLines = false;

  @override
  void didUpdateWidget(_EntryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded && !oldWidget.expanded && _lines.isEmpty) {
      _fetchLines();
    }
  }

  Future<void> _fetchLines() async {
    setState(() => _loadingLines = true);
    final lines = await widget.repo.getEntryLines(
      widget.entry['id'] as int,
    );
    if (mounted) setState(() { _lines = lines; _loadingLines = false; });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##');
    final entry = widget.entry;
    final totalDebit = (entry['totalDebit'] as num?)?.toDouble() ?? 0;

    return Column(
      children: [
        InkWell(
          onTap: widget.onToggle,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    entry['date'] as String? ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.sidebarTextMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    entry['description'] as String? ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    entry['reference'] as String? ?? '-',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    fmt.format(totalDebit),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    fmt.format(totalDebit),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Icon(
                    widget.expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.sidebarTextMuted,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.expanded)
          Container(
            color: AppColors.contentBg,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: _loadingLines
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : _LinesTable(lines: _lines, fmt: fmt),
          ),
      ],
    );
  }
}

class _LinesTable extends StatelessWidget {
  final List<Map<String, dynamic>> lines;
  final NumberFormat fmt;
  const _LinesTable({required this.lines, required this.fmt});

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.contentBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                SizedBox(width: 50, child: _hdr('account_code'.tr())),
                Expanded(child: _hdr('account_name'.tr())),
                SizedBox(width: 100, child: _hdr('debit'.tr())),
                SizedBox(width: 100, child: _hdr('credit'.tr())),
              ],
            ),
          ),
          const Divider(height: 1),
          for (int i = 0; i < lines.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      lines[i]['code'] as String? ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.sidebarTextMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      lines[i]['accountName'] as String? ?? '-',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: _amountCell(
                      (lines[i]['debit'] as num?)?.toDouble() ?? 0,
                      AppColors.primary,
                      fmt,
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: _amountCell(
                      (lines[i]['credit'] as num?)?.toDouble() ?? 0,
                      AppColors.success,
                      fmt,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _amountCell(double value, Color color, NumberFormat fmt) {
    if (value == 0) {
      return const Text(
        '-',
        style: TextStyle(color: AppColors.sidebarTextMuted, fontSize: 12),
        textAlign: TextAlign.end,
      );
    }
    return Text(
      fmt.format(value),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      textAlign: TextAlign.end,
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
