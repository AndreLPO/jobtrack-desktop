import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/time/local_date.dart';
import '../../follow_ups/views/follow_up_labels.dart';
import '../models/application.dart';
import '../models/application_status.dart';
import '../models/follow_up_policy.dart';
import '../models/kanban.dart';
import 'labels.dart';
import 'status_badge.dart';

typedef MoveCallback = void Function(
  Application application,
  ApplicationStatus status,
);

/// Quadro Kanban das candidaturas (spec `kanban`). Recebe a lista já
/// filtrada e ordenada; a ordem dentro da coluna é preservada (RN-KB-05).
class KanbanBoard extends StatefulWidget {
  const KanbanBoard({
    super.key,
    required this.columns,
    required this.applications,
    required this.followUpOf,
    required this.today,
    required this.onOpen,
    required this.onMove,
  });

  static const columnWidth = 260.0;

  final List<KanbanColumn> columns;
  final List<Application> applications;
  final FollowUpState Function(Application) followUpOf;
  final LocalDate today;
  final ValueChanged<Application> onOpen;
  final MoveCallback onMove;

  @override
  State<KanbanBoard> createState() => _KanbanBoardState();
}

class _KanbanBoardState extends State<KanbanBoard> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = groupForKanban(widget.applications, widget.columns);
    return Scrollbar(
      controller: _scroll,
      thumbVisibility: true,
      child: ListView.separated(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        itemCount: widget.columns.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) => _ColumnView(
          column: widget.columns[index],
          applications: groups[index],
          followUpOf: widget.followUpOf,
          today: widget.today,
          onOpen: widget.onOpen,
          onMove: widget.onMove,
        ),
      ),
    );
  }
}

/// Título da coluna em pt-BR.
String kanbanColumnTitle(KanbanColumn column) =>
    column.isGrouped ? 'Encerradas' : column.statuses.single.label;

/// Pergunta qual status aplicar ao soltar na coluna agrupada (K-02).
Future<ApplicationStatus?> _pickStatus(
  BuildContext context,
  KanbanColumn column,
) {
  return showDialog<ApplicationStatus>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Encerrar como'),
      children: [
        for (final status in column.statuses)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(status),
            child: Text(status.label),
          ),
      ],
    ),
  );
}

class _ColumnView extends StatelessWidget {
  const _ColumnView({
    required this.column,
    required this.applications,
    required this.followUpOf,
    required this.today,
    required this.onOpen,
    required this.onMove,
  });

  final KanbanColumn column;
  final List<Application> applications;
  final FollowUpState Function(Application) followUpOf;
  final LocalDate today;
  final ValueChanged<Application> onOpen;
  final MoveCallback onMove;

  Future<void> _accept(BuildContext context, Application application) async {
    final status = column.dropStatus ?? await _pickStatus(context, column);
    if (status != null) onMove(application, status);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DragTarget<Application>(
      // Soltar na própria coluna (status único) não faz nada (RN-KB-02).
      onWillAcceptWithDetails: (details) =>
          column.isGrouped || !column.contains(details.data.status),
      onAcceptWithDetails: (details) => _accept(context, details.data),
      builder: (context, candidates, _) {
        final highlighted = candidates.isNotEmpty;
        return Container(
          width: KanbanBoard.columnWidth,
          decoration: BoxDecoration(
            color: AppColors.statusOpen,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: highlighted ? AppColors.accent : AppColors.border,
              width: highlighted ? 2 : AppSizes.borderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        kanbanColumnTitle(column),
                        style: textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      '${applications.length}',
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: applications.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          'Nenhuma candidatura',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.sm,
                          0,
                          AppSpacing.sm,
                          AppSpacing.sm,
                        ),
                        itemCount: applications.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) => _DraggableCard(
                          application: applications[index],
                          followUp: followUpOf(applications[index]),
                          today: today,
                          showStatus: column.isGrouped,
                          onOpen: onOpen,
                          onMove: onMove,
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

class _DraggableCard extends StatelessWidget {
  const _DraggableCard({
    required this.application,
    required this.followUp,
    required this.today,
    required this.showStatus,
    required this.onOpen,
    required this.onMove,
  });

  final Application application;
  final FollowUpState followUp;
  final LocalDate today;
  final bool showStatus;
  final ValueChanged<Application> onOpen;
  final MoveCallback onMove;

  @override
  Widget build(BuildContext context) {
    final card = _Card(
      application: application,
      followUp: followUp,
      today: today,
      showStatus: showStatus,
      onOpen: onOpen,
      onMove: onMove,
    );
    return Draggable<Application>(
      data: application,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: KanbanBoard.columnWidth - AppSpacing.lg,
          child: Opacity(opacity: 0.9, child: card),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: card),
      child: card,
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.application,
    required this.followUp,
    required this.today,
    required this.showStatus,
    required this.onOpen,
    required this.onMove,
  });

  final Application application;
  final FollowUpState followUp;
  final LocalDate today;
  final bool showStatus;
  final ValueChanged<Application> onOpen;
  final MoveCallback onMove;

  @override
  Widget build(BuildContext context) {
    final details = application.details;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onOpen(application),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            0,
            AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      details.companyName,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      details.jobTitle,
                      style: textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Candidatura em ${formatDate(details.applicationDate)}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (showStatus) ...[
                      const SizedBox(height: AppSpacing.xs),
                      StatusBadge(status: application.status),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    FollowUpIndicator(state: followUp, today: today),
                  ],
                ),
              ),
              PopupMenuButton<_CardAction>(
                tooltip: 'Ações do cartão',
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (action) => switch (action) {
                  _OpenDetails() => onOpen(application),
                  _MoveTo(:final status) => onMove(application, status),
                },
                itemBuilder: (_) => [
                  for (final status in ApplicationStatus.values)
                    if (status != application.status)
                      PopupMenuItem(
                        value: _MoveTo(status),
                        child: Text('Mover para ${status.label}'),
                      ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: _OpenDetails(),
                    child: Text('Abrir detalhes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ações do menu do cartão. "Mover para…" é a alternativa acessível ao
/// arrastar (spec F3).
sealed class _CardAction {
  const _CardAction();
}

final class _OpenDetails extends _CardAction {
  const _OpenDetails();
}

final class _MoveTo extends _CardAction {
  const _MoveTo(this.status);

  final ApplicationStatus status;
}
