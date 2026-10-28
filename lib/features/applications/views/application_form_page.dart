import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/shell/app_shell.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/time/local_date.dart';
import '../../../core/widgets/date_field.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/state_views.dart';
import '../models/application_channel.dart';
import '../models/application_draft.dart';
import '../models/application_status.dart';
import '../models/application_validation.dart';
import '../models/work_mode.dart';
import '../viewmodels/application_form_controller.dart';
import 'labels.dart';

class ApplicationFormPage extends GetView<ApplicationFormController> {
  const ApplicationFormPage({super.key});

  /// Pergunta antes de descartar alterações não salvas (D-52).
  Future<bool> _canLeave(BuildContext context) async {
    if (!controller.isDirty.value) return true;
    return confirm(
      context,
      title: 'Descartar alterações?',
      message: 'As alterações feitas neste formulário não foram salvas.',
      confirmLabel: 'Descartar',
      destructive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => PopScope(
        canPop: !controller.isDirty.value,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          if (await _canLeave(context)) Get.back();
        },
        child: AppShell(
          currentRoute: AppRoutes.applications,
          title: controller.isEditing
              ? 'Editar candidatura'
              : 'Nova candidatura',
          canLeave: () => _canLeave(context),
          child: switch (controller.loadStatus.value) {
            FormLoadStatus.loading => const LoadingView(),
            FormLoadStatus.notFound => MessageView(
              title: 'Candidatura não encontrada.',
              message: 'Ela pode ter sido excluída.',
              actionLabel: 'Voltar para a lista',
              onAction: Get.back,
            ),
            FormLoadStatus.error => MessageView(
              title: 'Não foi possível carregar os dados.',
              message: 'Seus registros não foram alterados.',
              actionLabel: 'Tentar novamente',
              onAction: controller.load,
            ),
            FormLoadStatus.ready => _FormBody(
              onCancel: () async {
                if (await _canLeave(context)) Get.back();
              },
            ),
          },
        ),
      ),
    );
  }
}

class _FormBody extends GetView<ApplicationFormController> {
  const _FormBody({required this.onCancel});

  /// Sai do formulário, perguntando antes se houver alterações (D-52).
  final VoidCallback onCancel;

  static const _twoColumnBreakpoint = 720.0;

  Future<void> _save(BuildContext context) async {
    var result = await controller.save();
    if (result == SaveResult.duplicateWarning) {
      if (!context.mounted) return;
      final duplicate = controller.duplicateOf.value!.details;
      final proceed = await confirm(
        context,
        title: 'Possível duplicidade',
        message:
            'Já existe uma candidatura para ${duplicate.companyName} — '
            '${duplicate.jobTitle}, enviada em '
            '${formatDate(duplicate.applicationDate)}.\n\n'
            'Deseja salvar mesmo assim?',
        confirmLabel: 'Salvar mesmo assim',
      );
      if (!proceed) return;
      result = await controller.save(confirmDuplicate: true);
    }
    if (!context.mounted) return;
    switch (result) {
      case SaveResult.saved:
        Get.back(result: true);
      case SaveResult.invalid:
        showFeedback(context, 'Corrija os campos destacados.', error: true);
      case SaveResult.failed:
        showFeedback(
          context,
          'Não foi possível salvar. Seus dados continuam no formulário; '
          'tente novamente.',
          error: true,
        );
      case SaveResult.duplicateWarning:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = controller.draft.value;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _twoColumnBreakpoint;
        Widget pair(Widget a, Widget b) => wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: a),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: b),
                ],
              )
            : Column(
                children: [
                  a,
                  const SizedBox(height: AppSpacing.lg),
                  b,
                ],
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _SectionTitle('Vaga'),
                        pair(
                          _text(
                            label: 'Empresa *',
                            field: ApplicationField.companyName,
                            initial: initial.companyName,
                            onChanged: (v) => controller.edit(
                              (d) => d.copyWith(companyName: v),
                            ),
                          ),
                          _text(
                            label: 'Título da vaga *',
                            field: ApplicationField.jobTitle,
                            initial: initial.jobTitle,
                            onChanged: (v) =>
                                controller.edit((d) => d.copyWith(jobTitle: v)),
                          ),
                        ),
                        const _Gap(),
                        pair(
                          _text(
                            label: 'Link da vaga',
                            field: ApplicationField.jobUrl,
                            initial: initial.jobUrl,
                            onChanged: (v) =>
                                controller.edit((d) => d.copyWith(jobUrl: v)),
                          ),
                          _text(
                            label: 'ATS usado',
                            helper: 'Ex.: Greenhouse, Lever, Workday',
                            initial: initial.atsName,
                            onChanged: (v) =>
                                controller.edit((d) => d.copyWith(atsName: v)),
                          ),
                        ),
                        const _Gap(),
                        pair(
                          _date(
                            label: 'Encerramento da vaga',
                            field: FormDateField.jobClosingDate,
                            value: (d) => d.jobClosingDate,
                          ),
                          const SizedBox.shrink(),
                        ),
                        const _Gap(),
                        _text(
                          label: 'Descrição da vaga',
                          helper:
                              'Guarde uma cópia: o anúncio pode sair do ar.',
                          initial: initial.jobDescription,
                          maxLines: 8,
                          onChanged: (v) => controller.edit(
                            (d) => d.copyWith(jobDescription: v),
                          ),
                        ),
                        const _SectionTitle('Candidatura'),
                        pair(
                          _date(
                            label: 'Data da candidatura *',
                            field: FormDateField.applicationDate,
                            value: (d) => d.applicationDate,
                            error: ApplicationField.applicationDate,
                          ),
                          _status(),
                        ),
                        const _Gap(),
                        pair(_channel(initial), _channelOther(initial)),
                        const _Gap(),
                        pair(
                          _text(
                            label: 'Versão do currículo',
                            helper: 'Ex.: CV-backend-v3',
                            initial: initial.resumeVersion,
                            onChanged: (v) => controller.edit(
                              (d) => d.copyWith(resumeVersion: v),
                            ),
                          ),
                          const SizedBox.shrink(),
                        ),
                        const _SectionTitle('Local e remuneração'),
                        pair(
                          _workMode(initial),
                          _text(
                            label: 'Cidade',
                            initial: initial.city,
                            onChanged: (v) =>
                                controller.edit((d) => d.copyWith(city: v)),
                          ),
                        ),
                        const _Gap(),
                        pair(
                          _text(
                            label: 'Faixa salarial',
                            initial: initial.salaryRange,
                            onChanged: (v) => controller.edit(
                              (d) => d.copyWith(salaryRange: v),
                            ),
                          ),
                          const SizedBox.shrink(),
                        ),
                        const _SectionTitle('Contato e observações'),
                        _text(
                          label: 'Contato',
                          helper: 'Recrutador ou pessoa que fez a indicação',
                          initial: initial.contactName,
                          onChanged: (v) => controller.edit(
                            (d) => d.copyWith(contactName: v),
                          ),
                        ),
                        const _Gap(),
                        _text(
                          label: 'Observações',
                          initial: initial.notes,
                          maxLines: 4,
                          onChanged: (v) =>
                              controller.edit((d) => d.copyWith(notes: v)),
                        ),
                        const _SectionTitle('Acompanhamento'),
                        pair(
                          _date(
                            label: 'Próximo acompanhamento',
                            helper:
                                'Opcional. Se preenchida, substitui a data '
                                'calculada pelo prazo.',
                            field: FormDateField.manualNextFollowUpAt,
                            value: (d) => d.manualNextFollowUpAt,
                          ),
                          const SizedBox.shrink(),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: AppSpacing.sm),
                Obx(
                  () => FilledButton(
                    onPressed: controller.isSaving.value
                        ? null
                        : () => _save(context),
                    child: Text(
                      controller.isSaving.value ? 'Salvando…' : 'Salvar',
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _text({
    required String label,
    required String initial,
    required ValueChanged<String> onChanged,
    ApplicationField? field,
    String? helper,
    int maxLines = 1,
  }) {
    Widget build(String? errorText) => TextFormField(
      initialValue: initial,
      onChanged: onChanged,
      minLines: maxLines > 1 ? 3 : 1,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        errorText: errorText,
        alignLabelWithHint: maxLines > 1,
      ),
    );
    // Só campos validados observam os erros.
    if (field == null) return build(null);
    return Obx(() => build(controller.errorFor(field)?.message));
  }

  Widget _date({
    required String label,
    required FormDateField field,
    required LocalDateGetter value,
    ApplicationField? error,
    String? helper,
  }) {
    return Obx(
      () => DateField(
        label: label,
        helperText: helper,
        value: value(controller.draft.value),
        errorText: error == null ? null : controller.errorFor(error)?.message,
        onChanged: (date, {invalid = false}) =>
            controller.setDate(field, date, invalid: invalid),
      ),
    );
  }

  Widget _status() {
    if (controller.isEditing) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Status',
          helperText:
              'A mudança de status ficará disponível na página de detalhes.',
        ),
        child: Text(controller.originalStatus!.label),
      );
    }
    return Obx(
      () => DropdownButtonFormField<ApplicationStatus>(
        initialValue: controller.draft.value.status,
        decoration: InputDecoration(
          labelText: 'Status inicial *',
          errorText: controller.errorFor(ApplicationField.status)?.message,
        ),
        items: [
          for (final status in ApplicationStatus.values)
            DropdownMenuItem(value: status, child: Text(status.label)),
        ],
        onChanged: (value) =>
            controller.edit((d) => d.copyWith(status: () => value)),
      ),
    );
  }

  Widget _channel(ApplicationDraft initial) {
    return Obx(
      () => DropdownButtonFormField<ApplicationChannel>(
        initialValue: initial.channel,
        decoration: InputDecoration(
          labelText: 'Canal *',
          errorText: controller.errorFor(ApplicationField.channel)?.message,
        ),
        items: [
          for (final channel in ApplicationChannel.values)
            DropdownMenuItem(value: channel, child: Text(channel.label)),
        ],
        onChanged: (value) =>
            controller.edit((d) => d.copyWith(channel: () => value)),
      ),
    );
  }

  Widget _channelOther(ApplicationDraft initial) {
    return Obx(() {
      if (controller.draft.value.channel != ApplicationChannel.other) {
        return const SizedBox.shrink();
      }
      return TextFormField(
        initialValue: initial.channelOther,
        onChanged: (v) => controller.edit((d) => d.copyWith(channelOther: v)),
        decoration: InputDecoration(
          labelText: 'Qual canal? *',
          errorText: controller
              .errorFor(ApplicationField.channelOther)
              ?.message,
        ),
      );
    });
  }

  Widget _workMode(ApplicationDraft initial) {
    return DropdownButtonFormField<WorkMode?>(
      initialValue: initial.workMode,
      decoration: const InputDecoration(labelText: 'Modalidade'),
      items: [
        const DropdownMenuItem(value: null, child: Text('Não informada')),
        for (final mode in WorkMode.values)
          DropdownMenuItem(value: mode, child: Text(mode.label)),
      ],
      onChanged: (value) =>
          controller.edit((d) => d.copyWith(workMode: () => value)),
    );
  }
}

typedef LocalDateGetter = LocalDate? Function(ApplicationDraft draft);

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.md),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}

class _Gap extends StatelessWidget {
  const _Gap();

  @override
  Widget build(BuildContext context) => const SizedBox(height: AppSpacing.lg);
}
