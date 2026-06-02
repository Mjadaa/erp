import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_theme.dart';

class ComingSoonScreen extends StatelessWidget {
  final String moduleKey;
  final IconData icon;

  const ComingSoonScreen({
    super.key,
    required this.moduleKey,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(12),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.primary.withAlpha(30),
                width: 2,
              ),
            ),
            child: Icon(icon, size: 48, color: AppColors.primary.withAlpha(160)),
          ),
          const SizedBox(height: 24),
          Text(
            moduleKey.tr(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'coming_soon'.tr(),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.sidebarTextMuted,
            ),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.construction_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'under_construction'.tr(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
