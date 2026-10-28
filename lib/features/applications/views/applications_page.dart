import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/shell/app_shell.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/time/local_date.dart';
import '../../follow_ups/views/follow_up_labels.dart';
import '../models/application.dart';
import '../models/follow_up_policy.dart';
import '../viewmodels/applications_controller.dart';
import 'application_details_page.dart';
import 'applications_toolbar.dart';
import 'labels.dart';
import 'status_badge.dart';

class ApplicationsPage extends GetView<ApplicationsController> {
  const ApplicationsPage({super.key});

  Future<void> _openForm(BuildContext context, String route) async {
    // As rotas do GetX são dinâmicas; o formulário devolve `true` ao salvar.
    final saved = await Get.toNamed(route);
    if (saved != true) return;
    await controller.load();
    if (context.mounted) showFeedback(context, 'Candidatura salva.');
  }

  /// Detalhes (D-51). Ao voltar, recarrega: status e dados podem ter
  /// mudado.
  Future<void> _openDetails(BuildContext context, Application app) async {
    final result = await Get.toNamed(AppRoutes.applicationDetailsPath(app.id));
    await controller.load();
    if (result == detailsDeletedResult && context.mounted) {
      showFeedback(context, 'Candidatura excluída.');
    }
  }

  Future<void> _delete(BuildContext context, Application application) async {
    final confirmed = await confirm(
      context,
      title: 'Excluir candidatura?',
      message:
          '${application.details.companyName} — '
          '${application.details.jobTitle}\n\n'
          'O histórico de status e os contatos também serão excluídos. '
          'Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!confirmed) return;
    final deleted = await controller.delete(application.id);
    if (!context.mounted) return;
    showFeedback(
      context,
      deleted
          ? 'Candidatura excluída.'
          : 'Não foi possível excluir a candidatura. Tente novamente.',
      error: !deleted,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.applications,
      title: 'Candidaturas',
      actions: [
        FilledButton.icon(
          onPressed: () => _openForm(context, AppRoutes.newApplication),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Nova candidatura'),
        ),
      ],
      child: Obx(() {
        switch (controller.status.value) {
          case ListStatus.loading:
            return const LoadingView();
          case ListStatus.error:
            return MessageView(
              title: 'Não foi possível carregar as candidaturas.',
              message: 'Seus registros não foram alterados.',
              actionLabel: 'Tentar novamente',
              onAction: controller.load,
            );
          case ListStatus.ready:
            return _buildReady(context);
        }
      }),
    );
  }

  Widget _buildReady(BuildContext context) {
    final applications = controller.applications;
    final unreadable = controller.unreadableCount.value;
    final visible = controller.visible;
    if (applications.isEmpty && unreadable == 0) {
      return MessageView(
        title: 'Nenhuma candidatura cadastrada.',
        message:
            'Registre as vagas às quais você se candidatou para '
            'acompanhar respostas e prazos.',
        actionLabel: 'Cadastrar primeira candidatura',
        onAction: () => _openForm(context, AppRoutes.newApplication),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (unreadable > 0) ...[
          WarningBanner(
            message: unreadable == 1
                ? '1 registro não pôde ser lido e não aparece na lista. '
                      'Ele foi mantido sem alterações.'
                : '$unreadable registros não puderam ser lidos e não '
                      'aparecem na lista. Eles foram mantidos sem alterações.',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        ApplicationsToolbar(
          filter: controller.filter.value,
          sort: controller.sort.value,
          onFilterChanged: controller.setFilter,
          onSortChanged: controller.setSort,
        ),
        const SizedBox(height: AppSpacing.md),
        _ResultSummary(
          shown: visible.length,
          total: applications.length,
          filtered: !controller.filter.value.isEmpty,
          onClear: controller.clearFilters,
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: visible.isEmpty
              ? MessageView(
                  title: 'Nenhuma candidatura corresponde aos filtros.',
                  actionLabel: 'Limpar filtros',
                  onAction: controller.clearFilters,
                )
              : _ApplicationsTable(
                  applications: visible,
                  followUpOf: controller.followUpOf,
                  today: controller.today,
                  onOpen: (a) => _openDetails(context, a),
                  onEdit: (a) =>
                      _openForm(context, AppRoutes.editApplicationPath(a.id)),
                  onDelete: (a) => _delete(context, a),
                ),
        ),
      ],
    );
  }
}

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({
    required this.shown,
    required this.total,
    required this.filtered,
    required this.onClear,
  });

  final int shown;
  final int total;
  final bool filtered;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final text = filtered
        ? '$shown de $total candidaturas'
        : total == 1
        ? '1 candidatura'
        : '$total candidaturas';
    return Row(
      children: [
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
        if (filtered) ...[
          const SizedBox(width: AppSpacing.sm),
          TextButton(onPressed: onClear, child: const Text('Limpar filtros')),
        ],
      ],
    );
  }
}

/// Tabela com cabeçalho fixo e linhas preguiçosas.
class _ApplicationsTable extends StatelessWidget {
  const _ApplicationsTable({
    required this.applications,
    required this.followUpOf,
    required this.today,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  static const _channelBreakpoint = 800.0;

  final List<Application> applications;
  final FollowUpState Function(Application) followUpOf;
  final LocalDate today;
  final ValueChanged<Application> onOpen;
  final ValueChanged<Application> onEdit;
  final ValueChanged<Application> onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showChannel = constraints.maxWidth >= _channelBreakpoint;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              _HeaderRow(showChannel: showChannel),
              const Divider(),
              Expanded(
                child: ListView.separated(
                  itemCount: applications.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) => _ApplicationRow(
                    application: applications[index],
                    followUp: followUpOf(applications[index]),
                    today: today,
                    showChannel: showChannel,
                    onOpen: onOpen,
                    onEdit: onEdit,
                    onDelete: onDelete,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

const _dateWidth = 110.0;
const _statusWidth = 190.0;
const _followUpWidth = 170.0;
const _menuWidth = 48.0;

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.showChannel});

  final bool showChannel;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge
        ?.copyWith(color: AppColors.textSecondary);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Empresa', style: style)),
          Expanded(flex: 3, child: Text('Vaga', style: style)),
          SizedBox(
            width: _dateWidth,
            child: Text('Data', style: style),
          ),
          if (showChannel)
            Expanded(flex: 2, child: Text('Canal', style: style)),
          SizedBox(
            width: _statusWidth,
            child: Text('Status', style: style),
          ),
          SizedBox(
            width: _followUpWidth,
            child: Text('Acompanhamento', style: style),
          ),
          const SizedBox(width: _menuWidth),
        ],
      ),
    );
  }
}

class _ApplicationRow extends StatelessWidget {
  const _ApplicationRow({
    required this.application,
    required this.followUp,
    required this.today,
    required this.showChannel,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final Application application;
  final FollowUpState followUp;
  final LocalDate today;
  final bool showChannel;
  final ValueChanged<Application> onOpen;
  final ValueChanged<Application> onEdit;
  final ValueChanged<Application> onDelete;

  @override
  Widget build(BuildContext context) {
    final details = application.details;
    return InkWell(
      onTap: () => onOpen(application),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(flex: 3, child: _Cell(details.companyName, strong: true)),
            Expanded(flex: 3, child: _Cell(details.jobTitle)),
            SizedBox(
              width: _dateWidth,
              child: _Cell(formatDate(details.applicationDate)),
            ),
            if (showChannel)
              Expanded(flex: 2, child: _Cell(channelDisplay(details))),
            SizedBox(
              width: _statusWidth,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(status: application.status),
              ),
            ),
            SizedBox(
              width: _followUpWidth,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FollowUpIndicator(state: followUp, today: today),
              ),
            ),
            SizedBox(
              width: _menuWidth,
              child: PopupMenuButton<_RowAction>(
                tooltip: 'Ações',
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (action) => switch (action) {
                  _RowAction.edit => onEdit(application),
                  _RowAction.delete => onDelete(application),
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: _RowAction.edit, child: Text('Editar')),
                  PopupMenuItem(
                    value: _RowAction.delete,
                    child: Text('Excluir'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _RowAction { edit, delete }

class _Cell extends StatelessWidget {
  const _Cell(this.text, {this.strong = false});

  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: strong ? const TextStyle(fontWeight: FontWeight.w600) : null,
      ),
    );
  }
}
