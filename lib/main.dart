import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'core/database/database_helper.dart';
import 'core/providers/auth_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/change_password_screen.dart';
import 'features/shell/widgets/app_sidebar.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/inventory/screens/inventory_screen.dart';
import 'features/crm/screens/crm_screen.dart';
import 'features/sales/screens/sales_screen.dart';
import 'features/purchases/screens/purchases_screen.dart';
import 'features/accounting/screens/accounting_screen.dart';
import 'features/hr/screens/hr_screen.dart';
import 'core/providers/update_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await DatabaseHelper.instance.database;

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar', 'SA'), Locale('en', 'US')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar', 'SA'),
      startLocale: const Locale('ar', 'SA'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => UpdateProvider()),
        ],
        child: const ERPApp(),
      ),
    ),
  );
}

class ERPApp extends StatelessWidget {
  const ERPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ERP System',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      home: const AppRoot(),
    );
  }
}

// Decides which top-level screen to show.
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) return const LoginScreen();
    if (auth.currentUser!.mustChangePassword) return const ChangePasswordScreen();
    return const MainShell();
  }
}

// ─── Main Shell ───────────────────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UpdateProvider>().checkForUpdates();
    });
  }

  static const _navItems = [
    SidebarItem(
      labelKey: 'dashboard',
      icon: Icons.dashboard_rounded,
    ),
    SidebarItem(
      labelKey: 'inventory',
      icon: Icons.inventory_2_rounded,
      permission: 'inventory',
    ),
    SidebarItem(
      labelKey: 'crm',
      icon: Icons.people_alt_rounded,
      permission: 'crm',
    ),
    SidebarItem(
      labelKey: 'sales',
      icon: Icons.shopping_cart_rounded,
      permission: 'sales',
    ),
    SidebarItem(
      labelKey: 'purchases',
      icon: Icons.local_shipping_rounded,
      permission: 'purchases',
    ),
    SidebarItem(
      labelKey: 'accounting',
      icon: Icons.account_balance_rounded,
      permission: 'accounting',
    ),
    SidebarItem(
      labelKey: 'hr',
      icon: Icons.people_rounded,
      permission: 'hr',
    ),
  ];

  List<SidebarItem> _visibleItems(AuthProvider auth) {
    return _navItems
        .where((item) =>
            item.permission == null ||
            auth.currentUser!.hasPermission(item.permission!))
        .toList();
  }

  Widget _buildContent(SidebarItem item, List<SidebarItem> visibleItems) {
    switch (item.labelKey) {
      case 'dashboard':
        return DashboardScreen(
          onNewSale: () {
            final idx = visibleItems.indexWhere((i) => i.labelKey == 'sales');
            if (idx >= 0) setState(() => _selectedIndex = idx);
          },
        );
      case 'inventory':
        return const InventoryScreen();
      case 'crm':
        return const CrmScreen();
      case 'sales':
        return const SalesScreen();
      case 'purchases':
        return const PurchasesScreen();
      case 'accounting':
        return const AccountingScreen();
      case 'hr':
        return const HrScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final items = _visibleItems(auth);
    final clampedIndex = _selectedIndex.clamp(0, items.length - 1);

    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            items: items,
            selectedIndex: clampedIndex,
            onItemSelected: (i) => setState(() => _selectedIndex = i),
          ),
          // Vertical divider
          Container(width: 1, color: AppColors.sidebarDivider),
          // Content
          Expanded(
            child: Container(
              color: AppColors.contentBg,
              child: _buildContent(items[clampedIndex], items),
            ),
          ),
        ],
      ),
    );
  }
}
