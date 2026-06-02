import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorKey;

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _errorKey = null;
      _isLoading = true;
    });

    final error = await context.read<AuthProvider>().changePassword(_newCtrl.text);

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (error != null) setState(() => _errorKey = error);
  }

  @override
  Widget build(BuildContext context) {
    final username =
        context.watch<AuthProvider>().currentUser?.username ?? '';

    return Scaffold(
      body: Row(
        children: [
          // Left accent panel
          Container(
            width: 6,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primary, Color(0xFF7C3AED)],
              ),
            ),
          ),

          // Main content
          Expanded(
            child: Container(
              color: AppColors.contentBg,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      children: [
                        // Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.cardBorder),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withAlpha(12),
                                blurRadius: 32,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Card header strip
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 28,
                                ),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF0F172A),
                                      Color(0xFF1E3A5F),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(18),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.lock_reset_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'change_password_title'.tr(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'change_password_subtitle'.tr(
                                              namedArgs: {'username': username},
                                            ),
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withAlpha(160),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Form body
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    32, 32, 32, 32),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Security tip
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: AppColors.infoBg,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: AppColors.info.withAlpha(50),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.info_outline_rounded,
                                              color: AppColors.info,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'change_password_tip'.tr(),
                                                style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 24),

                                      // New password
                                      _FieldLabel(
                                        label: 'new_password'.tr(),
                                      ),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _newCtrl,
                                        obscureText: _obscureNew,
                                        decoration: InputDecoration(
                                          hintText:
                                              'new_password_hint'.tr(),
                                          prefixIcon: const Icon(
                                            Icons.lock_outline_rounded,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscureNew
                                                  ? Icons
                                                      .visibility_off_outlined
                                                  : Icons
                                                      .visibility_outlined,
                                            ),
                                            onPressed: () => setState(
                                              () => _obscureNew = !_obscureNew,
                                            ),
                                          ),
                                        ),
                                        textInputAction: TextInputAction.next,
                                        validator: (v) {
                                          if (v == null || v.isEmpty) {
                                            return 'error_field_required'.tr();
                                          }
                                          if (v.length < 6) {
                                            return 'error_password_too_short'
                                                .tr();
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 20),

                                      // Confirm password
                                      _FieldLabel(
                                        label: 'confirm_password'.tr(),
                                      ),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _confirmCtrl,
                                        obscureText: _obscureConfirm,
                                        decoration: InputDecoration(
                                          hintText:
                                              'confirm_password_hint'.tr(),
                                          prefixIcon: const Icon(
                                            Icons.lock_outline_rounded,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscureConfirm
                                                  ? Icons
                                                      .visibility_off_outlined
                                                  : Icons
                                                      .visibility_outlined,
                                            ),
                                            onPressed: () => setState(
                                              () => _obscureConfirm =
                                                  !_obscureConfirm,
                                            ),
                                          ),
                                        ),
                                        textInputAction: TextInputAction.done,
                                        onFieldSubmitted: (_) => _submit(),
                                        validator: (v) {
                                          if (v == null || v.isEmpty) {
                                            return 'error_field_required'.tr();
                                          }
                                          if (v != _newCtrl.text) {
                                            return 'error_passwords_mismatch'
                                                .tr();
                                          }
                                          return null;
                                        },
                                      ),

                                      // Error
                                      if (_errorKey != null) ...[
                                        const SizedBox(height: 16),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.dangerBg,
                                            borderRadius:
                                                BorderRadius.circular(10),
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
                                                  _errorKey!.tr(),
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

                                      SizedBox(
                                        width: double.infinity,
                                        height: 52,
                                        child: FilledButton(
                                          onPressed:
                                              _isLoading ? null : _submit,
                                          child: _isLoading
                                              ? const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : Text(
                                                  'save_password'.tr(),
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
