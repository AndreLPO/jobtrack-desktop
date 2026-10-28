import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/time/local_date.dart';
import '../../applications/models/follow_up_policy.dart';

/// "8 dias desde a candidatura" (RN-FU-09).
String daysSinceText(FollowUpBase base, LocalDate today) {
  if (base.kind == FollowUpBaseKind.manual) {
    return 'Data definida manualmente';
  }
  final days = base.date.daysUntil(today);
  final amount = switch (days) {
    0 => 'Hoje',
    1 => '1 dia',
    _ => '$days dias',
  };
  final since = switch (base.kind) {
    FollowUpBaseKind.applicationDate => 'a candidatura',
    FollowUpBaseKind.lastContact => 'o último contato',
    FollowUpBaseKind.interview => 'a entrevista',
    FollowUpBaseKind.statusChange => 'a mudança de status',
    FollowUpBaseKind.jobClosing => 'o encerramento da vaga',
    FollowUpBaseKind.manual => '',
  };
  return days == 0 ? '$amount: $since' : '$amount desde $since';
}

/// Indicador compacto da situação de acompanhamento, com ícone e texto
/// (não depende só de cor).
class FollowUpIndicator extends StatelessWidget {
  const FollowUpIndicator({
    super.key,
    required this.state,
    required this.today,
  });

  final FollowUpState state;
  final LocalDate today;

  @override
  Widget build(BuildContext context) {
    final (IconData? icon, String text, Color color) = switch (state) {
      FollowUpDue(:final dueDate) => (
        Icons.notifications_active_outlined,
        dueDate == today ? 'Hoje' : 'Vencido',
        AppColors.warningText,
      ),
      FollowUpScheduled(:final dueDate) => (
        Icons.schedule,
        'Em ${formatDate(dueDate)}',
        AppColors.textSecondary,
      ),
      FollowUpSuggestClose() => (
        Icons.flag_outlined,
        'Sugerido encerrar',
        AppColors.warningText,
      ),
      FollowUpNotApplicable() => (null, '—', AppColors.textSecondary),
    };
    final style = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: color);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
        ],
        Flexible(
          child: Text(text, style: style, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
