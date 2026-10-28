import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../models/application_status.dart';
import 'labels.dart';

/// Badge discreto de status. Sempre exibe o texto, e a cor só reforça.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final background = status.isClosed
        ? AppColors.statusClosed
        : status.indicatesResponse
        ? AppColors.statusResponded
        : AppColors.statusOpen;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: status.isClosed
              ? AppColors.textSecondary
              : AppColors.textPrimary,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
