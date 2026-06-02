import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorKey;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorKey = null);

    final error = await context.read<AuthProvider>().login(
      _usernameController.text,
      _passwordController.text,
    );

    if (error != null && mounted) setState(() => _errorKey = error);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      body: Row(
        children: [
          // ── Left branding panel ──────────────────────────────
          const Expanded(flex: 42, child: _BrandingPanel()),

          // ── Right form panel ─────────────────────────────────
          Expanded(
            flex: 58,
            child: _FormPanel(
              formKey: _formKey,
              usernameController: _usernameController,
              passwordController: _passwordController,
              obscurePassword: _obscurePassword,
              errorKey: _errorKey,
              isLoading: isLoading,
              onToggleObscure: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              onSubmit: _submit,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Branding Panel
// ─────────────────────────────────────────────────────────────────────────────

class _BrandingPanel extends StatelessWidget {
  const _BrandingPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.loginGradient,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -60,
            right: -60,
            child: _DecorativeCircle(size: 240, opacity: 0.06),
          ),
          Positioned(
            bottom: 60,
            left: -80,
            child: _DecorativeCircle(size: 300, opacity: 0.05),
          ),
          Positioned(
            top: 180,
            left: -40,
            child: _DecorativeCircle(size: 160, opacity: 0.08),
          ),
          Positioned(
            bottom: -40,
            right: 60,
            child: _DecorativeCircle(size: 180, opacity: 0.06),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withAlpha(30),
                    ),
                  ),
                  child: const Icon(
                    Icons.business_center_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 32),

                // App title
                Text(
                  'app_title'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'branding_tagline'.tr(),
                  style: TextStyle(
                    color: Colors.white.withAlpha(160),
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),

                const Spacer(),

                // Feature bullets
                _FeatureBullet(
                  icon: Icons.shield_rounded,
                  label: 'branding_feature_1'.tr(),
                ),
                const SizedBox(height: 18),
                _FeatureBullet(
                  icon: Icons.speed_rounded,
                  label: 'branding_feature_2'.tr(),
                ),
                const SizedBox(height: 18),
                _FeatureBullet(
                  icon: Icons.bar_chart_rounded,
                  label: 'branding_feature_3'.tr(),
                ),

                const SizedBox(height: 48),

                // Version
                Text(
                  'v1.0.0',
                  style: TextStyle(
                    color: Colors.white.withAlpha(80),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _DecorativeCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withAlpha((opacity * 255).round()),
          width: 1.5,
        ),
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureBullet({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(18),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white.withAlpha(220), size: 20),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withAlpha(200),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form Panel
// ─────────────────────────────────────────────────────────────────────────────

class _FormPanel extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final String? errorKey;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  const _FormPanel({
    required this.formKey,
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.errorKey,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          // Language toggle top-right
          Positioned(
            top: 24,
            right: 24,
            child: _LanguageToggle(),
          ),

          // Centered form
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 80),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Heading
                      Text(
                        'login_heading'.tr(),
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'login_subtitle'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.sidebarTextMuted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Username
                      _FieldLabel(label: 'username'.tr()),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          hintText: 'username_hint'.tr(),
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'error_field_required'.tr()
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // Password
                      _FieldLabel(label: 'password'.tr()),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'password_hint'.tr(),
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: onToggleObscure,
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => onSubmit(),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'error_field_required'.tr()
                            : null,
                      ),

                      // Error banner
                      if (errorKey != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.dangerBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.danger.withAlpha(60),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.danger,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  errorKey!.tr(),
                                  style: const TextStyle(
                                    color: AppColors.danger,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: isLoading ? null : onSubmit,
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'login'.tr(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Footer divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(color: colorScheme.outlineVariant),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'login_footer_hint'.tr(),
                              style: const TextStyle(
                                color: AppColors.sidebarTextMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(color: colorScheme.outlineVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0F172A),
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    return OutlinedButton.icon(
      icon: const Icon(Icons.language_rounded, size: 16),
      label: Text(
        isAr ? 'English' : 'عربي',
        style: const TextStyle(fontSize: 13),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.sidebarTextMuted,
        side: const BorderSide(color: AppColors.cardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      onPressed: () {
        context.setLocale(
          isAr ? const Locale('en', 'US') : const Locale('ar', 'SA'),
        );
      },
    );
  }
}
