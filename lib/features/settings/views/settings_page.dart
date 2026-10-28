import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/shell/app_shell.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/state_views.dart';
import '../models/follow_up_settings.dart';
import '../models/message_template.dart';
import '../viewmodels/settings_controller.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  /// Pergunta antes de descartar alterações não salvas (D-59).
  Future<bool> _canLeave(BuildContext context) async {
    if (!controller.isDirty) return true;
    return confirm(
      context,
      title: 'Descartar alterações?',
      message: 'As alterações nas configurações não foram salvas.',
      confirmLabel: 'Descartar',
      destructive: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.settings,
      title: 'Configurações',
      canLeave: () => _canLeave(context),
      child: Obx(
        () => switch (controller.status.value) {
          SettingsStatus.loading => const LoadingView(),
          SettingsStatus.error => MessageView(
            title: 'Não foi possível carregar as configurações.',
            message: 'Seus registros não foram alterados.',
            actionLabel: 'Tentar novamente',
            onAction: controller.load,
          ),
          SettingsStatus.ready => const _SettingsBody(),
        },
      ),
    );
  }
}

class _SettingsBody extends GetView<SettingsController> {
  const _SettingsBody();

  Future<void> _save(BuildContext context) async {
    final result = await controller.save();
    if (!context.mounted) return;
    switch (result) {
      case SettingsSaveResult.saved:
        showFeedback(context, 'Configurações salvas.');
      case SettingsSaveResult.invalid:
        showFeedback(context, 'Corrija os campos destacados.', error: true);
      case SettingsSaveResult.failed:
        showFeedback(
          context,
          'Não foi possível salvar. As configurações anteriores continuam '
          'valendo.',
          error: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final secondary = textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
    );
    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionCard(
                title: 'Acompanhamento',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Obx(
                      () => Text(
                        'Uma candidatura sem resposta é sugerida para '
                        'acompanhamento ${controller.saved.intervalDays} dias '
                        'corridos após a candidatura ou o último contato. '
                        'Depois de ${controller.saved.maxAttempts} '
                        'acompanhamentos sem resposta, o app sugere encerrar. '
                        'As alterações valem na hora para todas as '
                        'candidaturas sem data definida manualmente.',
                        style: secondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.lg,
                      runSpacing: AppSpacing.lg,
                      children: [
                        _NumberField(
                          label: 'Prazo (dias corridos)',
                          initial: controller.intervalText.value,
                          onChanged: controller.setInterval,
                          invalid: controller.intervalInvalid,
                          error:
                              'Informe um número de '
                              '${FollowUpSettings.minIntervalDays} a '
                              '${FollowUpSettings.maxIntervalDays}.',
                        ),
                        _NumberField(
                          label: 'Limite de tentativas',
                          initial: controller.attemptsText.value,
                          onChanged: controller.setAttempts,
                          invalid: controller.attemptsInvalid,
                          error:
                              'Informe um número de '
                              '${FollowUpSettings.minMaxAttempts} a '
                              '${FollowUpSettings.maxMaxAttempts}.',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Obx(
                        () => FilledButton(
                          onPressed: controller.isSaving.value
                              ? null
                              : () => _save(context),
                          child: Text(
                            controller.isSaving.value ? 'Salvando…' : 'Salvar',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _TemplateSection(),
              if (controller.dataDirectory != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _DataLocation(path: controller.dataDirectory!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateSection extends GetView<SettingsController> {
  const _TemplateSection();

  Future<void> _save(BuildContext context) async {
    final result = await controller.saveTemplate();
    if (!context.mounted) return;
    switch (result) {
      case SettingsSaveResult.saved:
        showFeedback(context, 'Modelo de mensagem salvo.');
      case SettingsSaveResult.invalid:
        showFeedback(context, 'O modelo não pode ficar vazio.', error: true);
      case SettingsSaveResult.failed:
        showFeedback(
          context,
          'Não foi possível salvar o modelo. O anterior continua valendo.',
          error: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: AppColors.textSecondary);
    return SectionCard(
      title: 'Modelo de mensagem de acompanhamento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Usado por "Copiar mensagem" nos Acompanhamentos e nos detalhes. '
            'Nada é enviado: você revisa e envia por e-mail ou LinkedIn. '
            'Escreva seus dados (nome, LinkedIn, experiência) direto no '
            'texto. Variáveis disponíveis:',
            style: secondary,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final entry in MessageTemplate.variables.entries)
            Text('${entry.key} — ${entry.value}', style: secondary),
          const SizedBox(height: AppSpacing.lg),
          Obx(
            () => _TemplateField(
              text: controller.templateText.value,
              onChanged: controller.setTemplate,
              errorText: controller.templateInvalid.value
                  ? 'O modelo não pode ficar vazio.'
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: controller.restoreDefaultTemplate,
                child: const Text('Restaurar padrão'),
              ),
              const SizedBox(width: AppSpacing.sm),
              Obx(
                () => FilledButton(
                  onPressed: controller.isSavingTemplate.value
                      ? null
                      : () => _save(context),
                  child: Text(
                    controller.isSavingTemplate.value
                        ? 'Salvando…'
                        : 'Salvar modelo',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Campo multilinha que acompanha mudanças externas ("Restaurar padrão").
class _TemplateField extends StatefulWidget {
  const _TemplateField({
    required this.text,
    required this.onChanged,
    this.errorText,
  });

  final String text;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  State<_TemplateField> createState() => _TemplateFieldState();
}

class _TemplateFieldState extends State<_TemplateField> {
  late final _controller = TextEditingController(text: widget.text);

  @override
  void didUpdateWidget(_TemplateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != _controller.text) _controller.text = widget.text;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      minLines: 8,
      maxLines: 16,
      decoration: InputDecoration(
        labelText: 'Modelo',
        alignLabelWithHint: true,
        errorText: widget.errorText,
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.initial,
    required this.onChanged,
    required this.invalid,
    required this.error,
  });

  final String label;
  final String initial;
  final ValueChanged<String> onChanged;
  final RxBool invalid;
  final String error;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Obx(
        () => TextFormField(
          initialValue: initial,
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: label,
            errorText: invalid.value ? error : null,
            errorMaxLines: 2,
          ),
        ),
      ),
    );
  }
}

class _DataLocation extends StatelessWidget {
  const _DataLocation({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Dados locais',
      action: IconButton(
        tooltip: 'Copiar caminho',
        icon: const Icon(Icons.copy, size: 18),
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: path));
          if (context.mounted) showFeedback(context, 'Caminho copiado.');
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seus registros ficam somente neste computador, na pasta abaixo. '
            'Para ter uma cópia de segurança, copie essa pasta com o '
            'aplicativo fechado.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          SelectableText(path),
        ],
      ),
    );
  }
}
