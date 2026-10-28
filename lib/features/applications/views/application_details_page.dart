import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/shell/app_shell.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/state_views.dart';
import '../models/application.dart';
import '../models/interaction.dart';
import '../models/status_change.dart';
import '../viewmodels/application_details_controller.dart';
import 'change_status_dialog.dart';
import 'labels.dart';
import 'register_contact_dialog.dart';
import 'status_badge.dart';

/// Resultado devolvido à listagem quando a candidatura é excluída.
const detailsDeletedResult = 'deleted';

class ApplicationDetailsPage extends GetView<ApplicationDetailsController> {
  const ApplicationDetailsPage({super.key});

  Future<void> _changeStatus(BuildContext context, Application app) async {
    final choice = await showChangeStatusDialog(context, current: app.status);
    if (choice == null) return;
    final ok = await controller.changeStatus(choice.status, note: choice.note);
    if (!context.mounted) return;
    showFeedback(
      context,
      ok
          ? 'Status alterado para ${choice.status.label}.'
          : 'Não foi possível alterar o status. Tente novamente.',
      error: !ok,
    );
  }

  Future<void> _registerContact(BuildContext context) async {
    final input = await showRegisterContactDialog(
      context,
      today: controller.today,
      validate: controller.validateContact,
    );
    if (input == null) return;
    final ok = await controller.registerInteraction(
      date: input.date,
      type: input.type,
      summary: input.summary,
      receivedResponse: input.receivedResponse,
      nextFollowUpAt: input.nextFollowUpAt,
    );
    if (!context.mounted) return;
    showFeedback(
      context,
      ok
          ? 'Contato registrado.'
          : 'Não foi possível registrar o contato. Tente novamente.',
      error: !ok,
    );
  }

  Future<void> _removeContact(BuildContext context, Interaction i) async {
    final confirmed = await confirm(
      context,
      title: 'Excluir contato?',
      message:
          '${i.type.label} em ${formatDate(i.date)}.\n\n'
          'A data de próximo acompanhamento não é alterada.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!confirmed) return;
    final ok = await controller.removeInteraction(i.id);
    if (!context.mounted) return;
    showFeedback(
      context,
      ok
          ? 'Contato excluído.'
          : 'Não foi possível excluir o contato. Tente novamente.',
      error: !ok,
    );
  }

  Future<void> _edit(BuildContext context) async {
    final saved = await Get.toNamed(
      AppRoutes.editApplicationPath(controller.applicationId),
    );
    if (saved != true) return;
    await controller.load();
    if (context.mounted) showFeedback(context, 'Candidatura salva.');
  }

  Future<void> _delete(BuildContext context, Application app) async {
    final confirmed = await confirm(
      context,
      title: 'Excluir candidatura?',
      message:
          '${app.details.companyName} — ${app.details.jobTitle}\n\n'
          'O histórico de status e os contatos também serão excluídos. '
          'Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!confirmed) return;
    final ok = await controller.delete();
    if (!context.mounted) return;
    if (ok) {
      Get.back(result: detailsDeletedResult);
    } else {
      showFeedback(
        context,
        'Não foi possível excluir a candidatura. Tente novamente.',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final app = controller.application.value;
      final ready = controller.status.value == DetailsStatus.ready;
      final busy = controller.isBusy.value;
      return AppShell(
        currentRoute: AppRoutes.applications,
        title: ready ? app!.details.companyName : 'Candidatura',
        actions: ready
            ? [
                OutlinedButton(
                  onPressed: busy ? null : () => _edit(context),
                  child: const Text('Editar'),
                ),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton(
                  onPressed: busy ? null : () => _delete(context, app!),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                  child: const Text('Excluir'),
                ),
              ]
            : const [],
        child: switch (controller.status.value) {
          DetailsStatus.loading => const LoadingView(),
          DetailsStatus.notFound => MessageView(
            title: 'Candidatura não encontrada.',
            message: 'Ela pode ter sido excluída.',
            actionLabel: 'Voltar para a lista',
            onAction: Get.back,
          ),
          DetailsStatus.error => MessageView(
            title: 'Não foi possível carregar a candidatura.',
            message: 'Seus registros não foram alterados.',
            actionLabel: 'Tentar novamente',
            onAction: controller.load,
          ),
          DetailsStatus.ready => _DetailsBody(
            application: app!,
            busy: busy,
            onChangeStatus: () => _changeStatus(context, app),
            onRegisterContact: () => _registerContact(context),
            onRemoveContact: (i) => _removeContact(context, i),
          ),
        },
      );
    });
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({
    required this.application,
    required this.busy,
    required this.onChangeStatus,
    required this.onRegisterContact,
    required this.onRemoveContact,
  });

  static const _twoColumnBreakpoint = 900.0;

  final Application application;
  final bool busy;
  final VoidCallback onChangeStatus;
  final VoidCallback onRegisterContact;
  final ValueChanged<Interaction> onRemoveContact;

  @override
  Widget build(BuildContext context) {
    final d = application.details;
    final textTheme = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _twoColumnBreakpoint;
        final contacts = SectionCard(
          title: 'Contatos',
          action: FilledButton.tonal(
            onPressed: busy ? null : onRegisterContact,
            child: const Text('Registrar contato'),
          ),
          child: _ContactList(
            interactions: application.interactions,
            onRemove: busy ? null : onRemoveContact,
          ),
        );
        final history = SectionCard(
          title: 'Histórico de status',
          child: _StatusHistory(changes: application.statusHistory),
        );

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                d.jobTitle,
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  StatusBadge(status: application.status),
                  const SizedBox(width: AppSpacing.md),
                  TextButton(
                    onPressed: busy ? null : onChangeStatus,
                    child: const Text('Alterar status'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SectionCard(
                title: 'Resumo',
                child: _InfoGrid(
                  items: {
                    'Data da candidatura': formatDate(d.applicationDate),
                    'Canal': channelDisplay(d),
                    'Último contato': application.lastContactAt == null
                        ? 'Nenhum'
                        : formatDate(application.lastContactAt!),
                    'Resposta da empresa': application.hasResponse
                        ? 'Sim'
                        : 'Ainda não',
                    if (application.manualNextFollowUpAt != null)
                      'Próximo acompanhamento (definido)': formatDate(
                        application.manualNextFollowUpAt!,
                      ),
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _JobSection(application: application),
              const SizedBox(height: AppSpacing.lg),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: contacts),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(child: history),
                  ],
                )
              else ...[
                contacts,
                const SizedBox(height: AppSpacing.lg),
                history,
              ],
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }
}

class _JobSection extends StatelessWidget {
  const _JobSection({required this.application});

  final Application application;

  @override
  Widget build(BuildContext context) {
    final d = application.details;
    final items = <String, String>{
      if (d.atsName != null) 'ATS': d.atsName!,
      if (d.resumeVersion != null) 'Versão do currículo': d.resumeVersion!,
      if (d.jobClosingDate != null)
        'Encerramento da vaga': formatDate(d.jobClosingDate!),
      if (d.workMode != null) 'Modalidade': d.workMode!.label,
      if (d.city != null) 'Cidade': d.city!,
      if (d.salaryRange != null) 'Faixa salarial': d.salaryRange!,
      if (d.contactName != null) 'Contato': d.contactName!,
    };
    final hasContent =
        items.isNotEmpty ||
        d.jobUrl != null ||
        d.notes != null ||
        d.jobDescription != null;
    if (!hasContent) return const SizedBox.shrink();

    return SectionCard(
      title: 'Vaga',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (d.jobUrl != null) _LinkRow(url: d.jobUrl!),
          if (items.isNotEmpty) ...[
            if (d.jobUrl != null) const SizedBox(height: AppSpacing.md),
            _InfoGrid(items: items),
          ],
          if (d.notes != null) ...[
            const SizedBox(height: AppSpacing.md),
            _LabeledText(label: 'Observações', text: d.notes!),
          ],
          if (d.jobDescription != null) ...[
            const SizedBox(height: AppSpacing.md),
            _JobDescription(text: d.jobDescription!),
          ],
        ],
      ),
    );
  }
}

/// Pares rótulo/valor que se acomodam à largura disponível.
class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final Map<String, String> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xl,
      runSpacing: AppSpacing.md,
      children: [
        for (final entry in items.entries)
          SizedBox(
            width: 220,
            child: _LabeledText(label: entry.key, text: entry.value),
          ),
      ],
    );
  }
}

class _LabeledText extends StatelessWidget {
  const _LabeledText({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SelectableText(text, style: textTheme.bodyMedium),
      ],
    );
  }
}

/// Abrir no navegador exigiria `url_launcher`; por ora, copia o link.
class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LabeledText(label: 'Link da vaga', text: url),
        ),
        IconButton(
          tooltip: 'Copiar link',
          icon: const Icon(Icons.copy, size: 18),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: url));
            if (context.mounted) showFeedback(context, 'Link copiado.');
          },
        ),
      ],
    );
  }
}

class _JobDescription extends StatefulWidget {
  const _JobDescription({required this.text});

  final String text;

  @override
  State<_JobDescription> createState() => _JobDescriptionState();
}

class _JobDescriptionState extends State<_JobDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _expanded = !_expanded),
          icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
          label: Text(
            _expanded
                ? 'Ocultar descrição da vaga'
                : 'Mostrar descrição da vaga',
          ),
        ),
        if (_expanded)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: SelectableText(widget.text),
          ),
      ],
    );
  }
}

class _ContactList extends StatelessWidget {
  const _ContactList({required this.interactions, required this.onRemove});

  final List<Interaction> interactions;
  final ValueChanged<Interaction>? onRemove;

  @override
  Widget build(BuildContext context) {
    if (interactions.isEmpty) {
      return const Text(
        'Nenhum contato registrado.',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }
    // Mais recente primeiro; no empate de data, o último registrado.
    final ordered =
        [for (var i = 0; i < interactions.length; i++) (i, interactions[i])]
          ..sort((a, b) {
            final byDate = b.$2.date.compareTo(a.$2.date);
            return byDate != 0 ? byDate : b.$1.compareTo(a.$1);
          });
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        for (final (index, (_, interaction)) in ordered.indexed) ...[
          if (index > 0) const Divider(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${formatDate(interaction.date)} · '
                      '${interaction.type.label}',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (interaction.receivedResponse)
                      const _Tag('Houve resposta'),
                    if (interaction.summary != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      SelectableText(interaction.summary!),
                    ],
                    if (interaction.nextFollowUpAt != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Próximo acompanhamento: '
                        '${formatDate(interaction.nextFollowUpAt!)}',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Excluir contato',
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: onRemove == null
                    ? null
                    : () => onRemove!(interaction),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.statusResponded,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(text, style: Theme.of(context).textTheme.labelSmall),
      ),
    );
  }
}

class _StatusHistory extends StatelessWidget {
  const _StatusHistory({required this.changes});

  final List<StatusChange> changes;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final newestFirst = changes.reversed.toList();
    return Column(
      children: [
        for (final (index, change) in newestFirst.indexed) ...[
          if (index > 0) const Divider(height: AppSpacing.xl),
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  change.previousStatus == null
                      ? 'Cadastrada como ${change.newStatus.label}'
                      : '${change.previousStatus!.label} → '
                            '${change.newStatus.label}',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  formatDateTime(change.changedAt),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (change.note != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  SelectableText(change.note!),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
