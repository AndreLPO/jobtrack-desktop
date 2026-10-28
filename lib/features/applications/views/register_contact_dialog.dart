import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/time/local_date.dart';
import '../../../core/widgets/date_field.dart';
import '../models/application_validation.dart';
import '../models/interaction_type.dart';
import 'labels.dart';

typedef ContactInput = ({
  LocalDate date,
  InteractionType type,
  String summary,
  bool receivedResponse,
  LocalDate? nextFollowUpAt,
});

typedef ContactValidator = List<FieldError<InteractionField>> Function({
  required LocalDate? date,
  required InteractionType? type,
  required LocalDate? nextFollowUpAt,
});

/// Diálogo "Registrar contato" (F4). Devolve `null` se cancelado.
Future<ContactInput?> showRegisterContactDialog(
  BuildContext context, {
  required LocalDate today,
  required ContactValidator validate,
}) {
  return showDialog<ContactInput>(
    context: context,
    builder: (_) => _RegisterContactDialog(today: today, validate: validate),
  );
}

class _RegisterContactDialog extends StatefulWidget {
  const _RegisterContactDialog({required this.today, required this.validate});

  final LocalDate today;
  final ContactValidator validate;

  @override
  State<_RegisterContactDialog> createState() => _RegisterContactDialogState();
}

class _RegisterContactDialogState extends State<_RegisterContactDialog> {
  late LocalDate? _date = widget.today;
  InteractionType? _type;
  String _summary = '';
  bool _receivedResponse = false;
  LocalDate? _next;
  final _invalidDates = <String>{};
  Map<InteractionField, ValidationCode> _errors = const {};

  void _setDate(
    String key,
    LocalDate? date,
    bool invalid,
    void Function() set,
  ) {
    setState(() {
      set();
      invalid ? _invalidDates.add(key) : _invalidDates.remove(key);
    });
  }

  void _submit() {
    final errors = widget.validate(
      date: _date,
      type: _type,
      nextFollowUpAt: _next,
    );
    setState(() => _errors = {for (final e in errors) e.field: e.code});
    if (errors.isNotEmpty || _invalidDates.isNotEmpty) return;
    Navigator.of(context).pop((
      date: _date!,
      type: _type!,
      summary: _summary,
      receivedResponse: _receivedResponse,
      nextFollowUpAt: _next,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar contato'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DateField(
                label: 'Data do contato *',
                value: _date,
                errorText: _errors[InteractionField.date]?.message,
                onChanged: (date, {invalid = false}) =>
                    _setDate('date', date, invalid, () => _date = date),
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<InteractionType>(
                initialValue: _type,
                decoration: InputDecoration(
                  labelText: 'Tipo *',
                  errorText: _errors[InteractionField.type]?.message,
                ),
                items: [
                  for (final type in InteractionType.values)
                    DropdownMenuItem(value: type, child: Text(type.label)),
                ],
                onChanged: (value) => setState(() => _type = value),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                onChanged: (value) => _summary = value,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Resumo (opcional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              CheckboxListTile(
                value: _receivedResponse,
                onChanged: (value) =>
                    setState(() => _receivedResponse = value ?? false),
                title: const Text('Houve resposta da empresa'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.sm),
              DateField(
                label: 'Próximo acompanhamento (opcional)',
                helperText:
                    'Em branco: o prazo padrão passa a contar a partir '
                    'deste contato.',
                value: _next,
                errorText: _errors[InteractionField.nextFollowUpAt]?.message,
                onChanged: (date, {invalid = false}) =>
                    _setDate('next', date, invalid, () => _next = date),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Registrar')),
      ],
    );
  }
}
