import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/shell/app_shell.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/time/local_date.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../applications/models/application.dart';
import '../../applications/models/follow_up_policy.dart';
import '../../applications/views/register_contact_dialog.dart';
import '../../applications/views/status_badge.dart';
import '../viewmodels/follow_ups_controller.dart';
import 'follow_up_labels.dart';
import 'postpone_dialog.dart';

class FollowUpsPage extends GetView<FollowUpsController> {
  const FollowUpsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.followUps,
      title: 'Acompanhamentos',
      child: Obx(
        () => switch (controller.status.value) {
          FollowUpsStatus.loading => const LoadingView(),
          FollowUpsStatus.error => MessageView(
            title: 'Não foi possível carregar os acompanhamentos.',
            message: 'Seus registros não foram alterados.',
            actionLabel: 'Tentar novamente',
            onAction: controller.load,
          ),
          FollowUpsStatus.ready => const _FollowUpsBody(),
        },
      ),
    );
  }
}

class _FollowUpsBody extends GetView<FollowUpsController> {
  const _FollowUpsBody();

  @override
  Widget build(BuildContext context) => Obx(() => _build(context));

  Widget _build(BuildContext context) {
    final due = controller.due;
    final close = controller.suggestClose;
    final settings = controller.settings.value;
    final rules = Text(
      'Prazo: ${settings.intervalDays} dias corridos · Limite: '
      '${settings.maxAttempts} tentativas sem resposta. '
      'Nada é enviado automaticamente: você entra em contato e registra '
      'o resultado.',
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: AppColors.textSecondary),
    );
    if (due.isEmpty && close.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          rules,
          const Expanded(
            child: MessageView(
              title: 'Nenhum acompanhamento pendente.',
              message:
                  'Quando uma candidatura sem resposta atingir o prazo, ela '
                  'aparece aqui.',
            ),
          ),
        ],
      );
    }
    return ListView(
      children: [
        rules,
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: 'Vencidos (${due.length})',
          child: due.isEmpty
              ? const _EmptySection('Nenhum acompanhamento vencido.')
              : _EntryList(entries: due),
        ),
        const SizedBox(height: AppSpacing.lg),
        SectionCard(
          title: 'Sugerido encerrar (${close.length})',
          child: close.isEmpty
              ? const _EmptySection(
                  'Nenhuma candidatura atingiu o limite de tentativas.',
                )
              : _EntryList(entries: close),
        ),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(color: AppColors.textSecondary));
}

class _EntryList extends StatelessWidget {
  const _EntryList({required this.entries});

  final List<FollowUpEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (index, entry) in entries.indexed) ...[
          if (index > 0) const Divider(height: AppSpacing.lg),
          _EntryTile(entry: entry),
        ],
      ],
    );
  }
}

enum _EntryAction { copyMessage, postpone, close, details }

class _EntryTile extends GetView<FollowUpsController> {
  const _EntryTile({required this.entry});

  final FollowUpEntry entry;

  Application get _app => entry.application;

  Future<void> _report(BuildContext context, bool ok, String success) async {
    if (!context.mounted) return;
    showFeedback(
      context,
      ok ? success : 'Não foi possível salvar. Tente novamente.',
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
      _app,
      date: input.date,
      type: input.type,
      summary: input.summary,
      receivedResponse: input.receivedResponse,
      nextFollowUpAt: input.nextFollowUpAt,
    );
    if (context.mounted) await _report(context, ok, 'Contato registrado.');
  }

  Future<void> _postpone(BuildContext context) async {
    final date = await showPostponeDialog(
      context,
      validate: controller.validatePostpone,
    );
    if (date == null) return;
    final ok = await controller.postpone(_app, date);
    if (context.mounted) {
      await _report(
        context,
        ok,
        'Acompanhamento adiado para ${formatDate(date)}.',
      );
    }
  }

  Future<void> _close(BuildContext context) async {
    final confirmed = await confirm(
      context,
      title: 'Encerrar sem resposta?',
      message:
          '${_app.details.companyName} — ${_app.details.jobTitle}\n\n'
          'O status passa para "Encerrada sem resposta" e a candidatura sai '
          'dos acompanhamentos. Você pode reabrir depois, alterando o status.',
      confirmLabel: 'Encerrar',
    );
    if (!confirmed) return;
    final ok = await controller.closeWithoutResponse(_app);
    if (context.mounted) await _report(context, ok, 'Candidatura encerrada.');
  }

  Future<void> _copyMessage(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: controller.messageFor(_app)));
    if (context.mounted) {
      showFeedback(context, 'Mensagem copiada. Revise antes de enviar.');
    }
  }

  Future<void> _openDetails() async {
    await Get.toNamed(AppRoutes.applicationDetailsPath(_app.id));
    await controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final details = _app.details;
    final textTheme = Theme.of(context).textTheme;
    final secondary = textTheme.bodySmall?.copyWith(
      color: AppColors.textSecondary,
    );
    final today = controller.today;
    final limit = controller.settings.value.maxAttempts;
    final note = [
      if (details.contactName != null) 'Contato: ${details.contactName}',
      if (details.notes != null) 'Obs.: ${details.notes}',
    ].join(' · ');

    return InkWell(
      onTap: _openDetails,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${details.companyName} — ${details.jobTitle}',
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      StatusBadge(status: _app.status),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(_summary(today, limit), style: textTheme.bodyMedium),
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      note,
                      style: secondary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Obx(() {
              final busy = controller.isBusy.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (entry.state is FollowUpSuggestClose)
                    FilledButton.tonal(
                      onPressed: busy ? null : () => _close(context),
                      child: const Text('Encerrar sem resposta'),
                    )
                  else
                    FilledButton.tonal(
                      onPressed: busy ? null : () => _registerContact(context),
                      child: const Text('Registrar contato'),
                    ),
                  PopupMenuButton<_EntryAction>(
                    tooltip: 'Mais ações',
                    enabled: !busy,
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (action) => switch (action) {
                      _EntryAction.copyMessage => _copyMessage(context),
                      _EntryAction.postpone => _postpone(context),
                      _EntryAction.close => _close(context),
                      _EntryAction.details => _openDetails(),
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: _EntryAction.copyMessage,
                        child: Text('Copiar mensagem'),
                      ),
                      const PopupMenuItem(
                        value: _EntryAction.postpone,
                        child: Text('Adiar'),
                      ),
                      if (entry.state is! FollowUpSuggestClose)
                        const PopupMenuItem(
                          value: _EntryAction.close,
                          child: Text('Encerrar sem resposta'),
                        ),
                      const PopupMenuItem(
                        value: _EntryAction.details,
                        child: Text('Abrir detalhes'),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Colunas de RF-06 em uma linha de texto.
  String _summary(LocalDate today, int limit) {
    final parts = <String>[
      'Candidatura em ${formatDate(_app.details.applicationDate)}',
    ];
    switch (entry.state) {
      case FollowUpDue(:final dueDate, :final base):
        parts
          ..add(daysSinceText(base, today))
          ..add('Sugerido para ${formatDate(dueDate)}');
      case FollowUpSuggestClose():
        if (_app.lastContactAt != null) {
          parts.add('Último contato em ${formatDate(_app.lastContactAt!)}');
        }
      case FollowUpScheduled() || FollowUpNotApplicable():
        break;
    }
    parts.add('Tentativas: ${entry.attempts}/$limit');
    return parts.join(' · ');
  }
}
