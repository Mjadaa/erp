import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../../core/repositories/sales_repository.dart';
import '../../../core/repositories/crm_repository.dart';
import '../../../core/repositories/inventory_repository.dart';
import '../../../core/models/inventory_models.dart';
import '../../../core/providers/update_provider.dart';
import '../../../core/theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNewSale;
  const DashboardScreen({super.key, this.onNewSale});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _salesRepo = SalesRepository();
  final _crmRepo = CrmRepository();
  final _invRepo = InventoryRepository();

  Map<String, dynamic> _salesStats = {
    'revenue': 0.0,
    'collected': 0.0,
    'pending': 0.0,
    'count': 0,
  };
  int _customerCount = 0;
  int _lowStockCount = 0;
  List<Map<String, dynamic>> _weeklySales = [];
  List<Product> _lowStockProducts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _salesRepo.getMonthlyStats(),
      _crmRepo.getCustomerCount(),
      _invRepo.getLowStockCount(),
      _salesRepo.getWeeklySales(),
      _invRepo.getLowStockProducts(),
    ]);
    if (mounted) {
      setState(() {
        _salesStats = results[0] as Map<String, dynamic>;
        _customerCount = results[1] as int;
        _lowStockCount = results[2] as int;
        _weeklySales = results[3] as List<Map<String, dynamic>>;
        _lowStockProducts = results[4] as List<Product>;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final fmt = NumberFormat('#,##0.##');
    final revenue = (_salesStats['revenue'] as double?) ?? 0;
    final count = (_salesStats['count'] as int?) ?? 0;

    final updateProvider = context.watch<UpdateProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (updateProvider.updateAvailable)
            _UpdateBanner(
              version: updateProvider.latestVersion,
              onInstall: updateProvider.installUpdate,
            ),
          if (updateProvider.updateAvailable) const SizedBox(height: 16),
          _DashboardHeader(onRefresh: _load, onNewSale: widget.onNewSale),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  title: 'kpi_revenue'.tr(),
                  value: fmt.format(revenue),
                  unit: 'currency_symbol'.tr(),
                  badge: '$count ${'kpi_invoices_unit'.tr()}',
                  isPositive: revenue > 0,
                  icon: Icons.attach_money_rounded,
                  gradient: AppColors.kpiRevenue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _KpiCard(
                  title: 'kpi_invoices'.tr(),
                  value: '$count',
                  unit: 'kpi_invoices_unit'.tr(),
                  badge: fmt.format(_salesStats['pending'] as double? ?? 0),
                  isPositive: count > 0,
                  icon: Icons.receipt_long_rounded,
                  gradient: AppColors.kpiSales,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _KpiCard(
                  title: 'kpi_customers'.tr(),
                  value: '$_customerCount',
                  unit: 'kpi_customers_unit'.tr(),
                  badge: '',
                  isPositive: _customerCount > 0,
                  icon: Icons.people_alt_rounded,
                  gradient: AppColors.kpiCustomers,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _KpiCard(
                  title: 'kpi_stock_alerts'.tr(),
                  value: '$_lowStockCount',
                  unit: 'kpi_stock_unit'.tr(),
                  badge: 'kpi_stock_warning'.tr(),
                  isPositive: _lowStockCount == 0,
                  icon: Icons.inventory_2_rounded,
                  gradient: AppColors.kpiStock,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _RevenueChart(weeklySales: _weeklySales),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _SalesStatusChart(stats: _salesStats),
              ),
            ],
          ),
          if (_lowStockProducts.isNotEmpty) ...[
            const SizedBox(height: 24),
            _LowStockPanel(products: _lowStockProducts),
          ],
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback? onNewSale;
  const _DashboardHeader({required this.onRefresh, this.onNewSale});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat.yMMMMEEEEd(
      context.locale.toString(),
    ).format(now);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'dashboard_greeting'.tr(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.sidebarTextMuted,
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: onRefresh,
              tooltip: 'refresh',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.cardBorder),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('new_sale'.tr()),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
              onPressed: onNewSale,
            ),
          ],
        ),
      ],
    );
  }
}

// ─── KPI Card ─────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String badge;
  final bool isPositive;
  final IconData icon;
  final List<Color> gradient;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.badge,
    required this.isPositive,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              if (badge.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive
                            ? Icons.trending_up_rounded
                            : Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$unit  •  $title',
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Revenue Chart ────────────────────────────────────────────────────────────

class _RevenueChart extends StatelessWidget {
  final List<Map<String, dynamic>> weeklySales;
  const _RevenueChart({required this.weeklySales});

  @override
  Widget build(BuildContext context) {
    // Build spots from real data; fill missing days with 0
    final now = DateTime.now();
    final spots = <FlSpot>[];
    double maxY = 1;

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dateStr = day.toIso8601String().substring(0, 10);
      final row = weeklySales.firstWhere(
        (r) => r['date'] == dateStr,
        orElse: () => {'date': dateStr, 'total': 0.0},
      );
      final total = (row['total'] as num).toDouble();
      spots.add(FlSpot((6 - i).toDouble(), total));
      if (total > maxY) maxY = total;
    }

    // Day labels (abbreviated)
    final days = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return DateFormat('E', context.locale.toString()).format(day);
    });

    return _ChartCard(
      title: 'chart_revenue_title'.tr(),
      subtitle: 'chart_revenue_subtitle'.tr(),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => const FlLine(
                color: AppColors.cardBorder,
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48,
                  getTitlesWidget: (value, _) => Text(
                    NumberFormat.compact().format(value),
                    style: const TextStyle(
                      color: AppColors.sidebarTextMuted,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    final i = value.toInt();
                    if (i < 0 || i >= days.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        days[i],
                        style: const TextStyle(
                          color: AppColors.sidebarTextMuted,
                          fontSize: 11,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.3,
                color: AppColors.primary,
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withAlpha(40),
                      AppColors.primary.withAlpha(0),
                    ],
                  ),
                ),
              ),
            ],
            minX: 0,
            maxX: 6,
            minY: 0,
            maxY: maxY * 1.2,
          ),
        ),
      ),
    );
  }
}

// ─── Sales Status Chart ───────────────────────────────────────────────────────

class _SalesStatusChart extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _SalesStatusChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final revenue = (stats['revenue'] as double?) ?? 0;
    final collected = (stats['collected'] as double?) ?? 0;
    final pending = (stats['pending'] as double?) ?? 0;

    final paidPct = revenue > 0 ? (collected / revenue * 100) : 0.0;
    final pendingPct = revenue > 0 ? (pending / revenue * 100) : 0.0;
    final unpaidPct = (100 - paidPct - pendingPct).clamp(0.0, 100.0);

    final fmt = NumberFormat('#,##0.##');

    return _ChartCard(
      title: 'chart_status_title'.tr(),
      subtitle: 'chart_status_subtitle'.tr(),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 44,
                sections: [
                  PieChartSectionData(
                    value: paidPct > 0 ? paidPct : (revenue == 0 ? 100 : 0),
                    color: revenue == 0
                        ? AppColors.cardBorder
                        : AppColors.success,
                    radius: 32,
                    showTitle: false,
                  ),
                  if (pendingPct > 0)
                    PieChartSectionData(
                      value: pendingPct,
                      color: AppColors.warning,
                      radius: 28,
                      showTitle: false,
                    ),
                  if (unpaidPct > 0)
                    PieChartSectionData(
                      value: unpaidPct,
                      color: AppColors.danger,
                      radius: 24,
                      showTitle: false,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Legend(
            color: AppColors.success,
            label: 'status_paid'.tr(),
            value: fmt.format(collected),
          ),
          const SizedBox(height: 8),
          _Legend(
            color: AppColors.warning,
            label: 'status_partial'.tr(),
            value: fmt.format(pending),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _Legend({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.sidebarTextMuted,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.sidebarTextMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

// ─── Update Banner ────────────────────────────────────────────────────────────

class _UpdateBanner extends StatelessWidget {
  final String version;
  final VoidCallback onInstall;
  const _UpdateBanner({required this.version, required this.onInstall});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withAlpha(60),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.system_update_alt_rounded,
              color: Colors.white, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'update_available_title'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${'update_available_subtitle'.tr()} $version',
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1D4ED8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: onInstall,
            child: Text('update_install_now'.tr(),
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─── Low Stock Panel ──────────────────────────────────────────────────────────

class _LowStockPanel extends StatelessWidget {
  final List<Product> products;
  const _LowStockPanel({required this.products});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE4B5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8ED),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFD97706), size: 20),
                const SizedBox(width: 10),
                Text(
                  'low_stock_alert_title'.tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF92400E),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${products.length} ${'kpi_stock_unit'.tr()}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          // Product rows
          ...products.map((p) => _LowStockRow(product: p)),
        ],
      ),
    );
  }
}

class _LowStockRow extends StatelessWidget {
  final Product product;
  const _LowStockRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final pct =
        product.minStockAlert > 0 ? product.stockQuantity / product.minStockAlert : 0.0;
    final barColor = product.stockQuantity == 0
        ? AppColors.danger
        : const Color(0xFFD97706);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: barColor.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.inventory_2_outlined, color: barColor, size: 18),
          ),
          const SizedBox(width: 12),
          // Name + bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation(barColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Qty badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${product.stockQuantity}',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: barColor),
              ),
              Text(
                '${'low_stock_min'.tr()} ${product.minStockAlert}',
                style: const TextStyle(
                    fontSize: 10, color: AppColors.sidebarTextMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
