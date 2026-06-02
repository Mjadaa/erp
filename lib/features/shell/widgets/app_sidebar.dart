import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class SidebarItem {
  final String labelKey;
  final IconData icon;
  final String? permission;

  const SidebarItem({
    required this.labelKey,
    required this.icon,
    this.permission,
  });
}

class AppSidebar extends StatelessWidget {
  final List<SidebarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const AppSidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          _SidebarHeader(),
          const _SidebarDivider(),
          Expanded(
            child: _SidebarNav(
              items: items,
              selectedIndex: selectedIndex,
              onItemSelected: onItemSelected,
            ),
          ),
          const _SidebarDivider(),
          _SidebarUserSection(),
        ],
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _SidebarHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.business_center_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'app_title'.tr(),
                  style: const TextStyle(
                    color: AppColors.sidebarTextActive,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'app_subtitle'.tr(),
                  style: const TextStyle(
                    color: AppColors.sidebarTextMuted,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nav ─────────────────────────────────────────────────────────────────────

class _SidebarNav extends StatelessWidget {
  final List<SidebarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const _SidebarNav({
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      children: [
        // Section label
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Text(
            'nav_main'.tr().toUpperCase(),
            style: const TextStyle(
              color: AppColors.sidebarTextMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final active = index == selectedIndex;

          return _NavItem(
            item: item,
            active: active,
            onTap: () => onItemSelected(index),
          );
        }),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final SidebarItem item;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: active ? AppColors.sidebarActiveBg : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: active
                  ? Border(
                      right: const BorderSide(
                        color: AppColors.sidebarAccent,
                        width: 3,
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 19,
                  color: active
                      ? AppColors.sidebarAccent
                      : AppColors.sidebarTextMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.labelKey.tr(),
                    style: TextStyle(
                      color: active
                          ? AppColors.sidebarTextActive
                          : AppColors.sidebarText,
                      fontSize: 13.5,
                      fontWeight:
                          active ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (active)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.sidebarAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── User section ─────────────────────────────────────────────────────────────

class _SidebarUserSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    final isAr = context.locale.languageCode == 'ar';

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // User card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.sidebarActiveBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      (user?.username ?? '?')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.username ?? '',
                        style: const TextStyle(
                          color: AppColors.sidebarTextActive,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user?.roleName ?? '',
                        style: const TextStyle(
                          color: AppColors.sidebarTextMuted,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: _SidebarActionButton(
                  icon: Icons.person_rounded,
                  label: 'profile'.tr(),
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const _ProfileDialog(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SidebarActionButton(
                  icon: Icons.language_rounded,
                  label: isAr ? 'EN' : 'ع',
                  onTap: () {
                    context.setLocale(
                      isAr
                          ? const Locale('en', 'US')
                          : const Locale('ar', 'SA'),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SidebarActionButton(
                  icon: Icons.logout_rounded,
                  label: 'logout'.tr(),
                  isDestructive: true,
                  onTap: () => auth.logout(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SidebarActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SidebarActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? const Color(0xFFF87171)
        : AppColors.sidebarTextMuted;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.sidebarActiveBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarDivider extends StatelessWidget {
  const _SidebarDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.sidebarDivider,
    );
  }
}

// ─── Profile Dialog ───────────────────────────────────────────────────────────

class _ProfileDialog extends StatefulWidget {
  const _ProfileDialog();

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  late final TextEditingController _usernameCtrl;
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _savingUsername = false;
  bool _savingPassword = false;
  String? _usernameError;
  String? _passwordError;
  bool _usernameSuccess = false;
  bool _passwordSuccess = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _usernameCtrl = TextEditingController(text: user?.username ?? '');
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveUsername() async {
    setState(() {
      _savingUsername = true;
      _usernameError = null;
      _usernameSuccess = false;
    });
    final error = await context.read<AuthProvider>().updateUsername(_usernameCtrl.text);
    if (mounted) {
      setState(() {
        _savingUsername = false;
        if (error != null) {
          _usernameError = error.tr();
        } else {
          _usernameSuccess = true;
        }
      });
    }
  }

  Future<void> _savePassword() async {
    setState(() {
      _passwordError = null;
      _passwordSuccess = false;
    });
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      setState(() => _passwordError = 'error_passwords_mismatch'.tr());
      return;
    }
    setState(() => _savingPassword = true);
    final error = await context.read<AuthProvider>().changePassword(_newPassCtrl.text);
    if (mounted) {
      setState(() {
        _savingPassword = false;
        if (error != null) {
          _passwordError = error.tr();
        } else {
          _passwordSuccess = true;
          _newPassCtrl.clear();
          _confirmPassCtrl.clear();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(user),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAccountInfo(user),
                    const Divider(height: 28),
                    _buildUsernameSection(),
                    const Divider(height: 28),
                    _buildPasswordSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AuthUser user) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                user.username[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  user.roleName,
                  style: const TextStyle(
                    color: AppColors.sidebarTextMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'profile_title'.tr(),
            style: const TextStyle(
              color: AppColors.sidebarTextMuted,
              fontSize: 12,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfo(AuthUser user) {
    final permsText = user.isAdmin
        ? 'all_permissions'.tr()
        : user.permissions
            .split(',')
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'profile_info'.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text(
                'permissions_label'.tr(),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.sidebarTextMuted,
                ),
              ),
            ),
            Expanded(
              child: Text(
                permsText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUsernameSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'change_username'.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _usernameCtrl,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(labelText: 'new_username'.tr(), isDense: true),
        ),
        if (_usernameError != null) ...[
          const SizedBox(height: 6),
          Text(_usernameError!,
              style: const TextStyle(color: AppColors.danger, fontSize: 12)),
        ],
        if (_usernameSuccess) ...[
          const SizedBox(height: 6),
          Text('profile_updated'.tr(),
              style: const TextStyle(color: AppColors.success, fontSize: 12)),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _savingUsername ? null : _saveUsername,
            child: _savingUsername
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text('update_username'.tr()),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'change_password_title'.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _newPassCtrl,
          obscureText: _obscurePass,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            labelText: 'new_password'.tr(),
            isDense: true,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePass
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 18,
              ),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _confirmPassCtrl,
          obscureText: _obscureConfirm,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            labelText: 'confirm_password'.tr(),
            isDense: true,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: 18,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ),
        if (_passwordError != null) ...[
          const SizedBox(height: 6),
          Text(_passwordError!,
              style: const TextStyle(color: AppColors.danger, fontSize: 12)),
        ],
        if (_passwordSuccess) ...[
          const SizedBox(height: 6),
          Text('password_updated'.tr(),
              style: const TextStyle(color: AppColors.success, fontSize: 12)),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _savingPassword ? null : _savePassword,
            child: _savingPassword
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text('save_password'.tr()),
          ),
        ),
      ],
    );
  }
}
