import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/shell/app_shell.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../applications/models/application_query.dart';
import '../../applications/models/application_status.dart';
import '../../applications/models/dashboard_metrics.dart';
import '../../applications/views/labels.dart';
import '../viewmodels/dashboard_controller.dart';

class DashboardPage extends GetView<DashboardController> {
  const DashboardPage({super.key});

  Future<void> _newApplication() async {
    final saved = await Get.toNamed(AppRoutes.newApplication);
    if (saved == true) await controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.dashboard,
      title: 'Dashboard',
      child: Obx(() {
        switch (controller.status.value) {
          case DashboardStatus.loading:
            return const LoadingView();
          case DashboardStatus.error:
            return MessageView(
              title: 'Não foi possível carregar os indicadores.',
              message: 'Seus registros não foram alterados.',
              actionLabel: 'Tentar novamente',
              onAction: controller.load,
            );
          case DashboardStatus.ready:
            final metrics = controller.metrics.value!;
            if (metrics.total == 0 && controller.unreadableCount.value == 0) {
              return MessageView(
                title: 'Nenhuma candidatura cadastrada.',
                message:
                    'Os indicadores aparecem aqui assim que você registrar '
                    'suas candidaturas.',
                actionLabel: 'Cadastrar candidatura',
                onAction: _newApplication,
              );
            }
            return _DashboardBody(
              metrics: metrics,
              maxAttempts: controller.settings.value.maxAttempts,
              unreadable: controller.unreadableCount.value,
            );
        }
      }),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.metrics,
    required this.maxAttempts,
    required this.unreadable,
  });

  final DashboardMetrics metrics;
  final int maxAttempts;
  final int unreadable;

  /// Abre a listagem já filtrada (D-57).
  void _openList(ApplicationFilter filter) =>
      Get.offAllNamed(AppRoutes.applications, arguments: filter);

  void _openFollowUps() => Get.offAllNamed(AppRoutes.followUps);

  @override
  Widget build(BuildContext context) {
    final week = metrics.week;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (unreadable > 0) ...[
            WarningBanner(
              message: unreadable == 1
                  ? '1 registro não pôde ser lido e não entra nos '
                        'indicadores.'
                  : '$unreadable registros não puderam ser lidos e não '
                        'entram nos indicadores.',
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            children: [
              _MetricCard(
                value: metrics.thisWeek,
                label: 'Candidaturas na semana',
                scope: '${formatDate(week.start)} a ${formatDate(week.end)}',
                onTap: () => _openList(
                  ApplicationFilter(from: week.start, to: week.end),
                ),
              ),
              _MetricCard(
                value: metrics.responded,
                label: 'Com resposta',
                scope: 'Total de candidaturas',
              ),
              _MetricCard(
                value: metrics.awaitingResponse,
                label: 'Aguardando resposta',
                scope: 'Total, candidaturas ativas',
              ),
              _MetricCard(
                value: metrics.dueFollowUps,
                label: 'Acompanhamentos pendentes',
                scope: 'Prazo atingido',
                highlight: metrics.dueFollowUps > 0,
                onTap: _openFollowUps,
              ),
              _MetricCard(
                value: metrics.suggestClose,
                label: 'Sugerido encerrar',
                scope: '$maxAttempts tentativas sem resposta',
                onTap: _openFollowUps,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionCard(
            title: 'Resumo por status (total: ${metrics.total})',
            child: Column(
              children: [
                for (final status in ApplicationStatus.values)
                  _StatusRow(
                    status: status,
                    count: metrics.byStatus[status]!,
                    total: metrics.total,
                    onTap: () =>
                        _openList(ApplicationFilter(statuses: {status})),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Número em destaque, rótulo e escopo explícito (§8).
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
    required this.scope,
    this.onTap,
    this.highlight = false,
  });

  final int value;
  final String label;
  final String scope;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 220,
      child: Card(
        color: highlight ? AppColors.warningSubtle : null,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$value',
                        style: textTheme.displaySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (onTap != null)
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textSecondary,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(label, style: textTheme.titleSmall),
                Text(
                  scope,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
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

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.status,
    required this.count,
    required this.total,
    required this.onTap,
  });

  final ApplicationStatus status;
  final int count;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final share = total == 0 ? 0.0 : count / total;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            SizedBox(width: 200, child: Text(status.label)),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Container(
                  height: 8,
                  color: AppColors.statusOpen,
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: share,
                    child: Container(color: AppColors.accent),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 48,
              child: Text(
                '$count',
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
