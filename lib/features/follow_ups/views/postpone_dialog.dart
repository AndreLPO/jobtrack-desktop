import 'package:flutter/material.dart';

import '../../../core/time/local_date.dart';
import '../../../core/widgets/date_field.dart';
import '../../applications/models/application_validation.dart';
import '../../applications/views/labels.dart';

/// Diálogo "Adiar" (D-23). Devolve a nova data ou `null` se cancelado.
Future<LocalDate?> showPostponeDialog(
  BuildContext context, {
  required ValidationCode? Function(LocalDate date) validate,
}) {
  return showDialog<LocalDate>(
    context: context,
    builder: (_) => _PostponeDialog(validate: validate),
  );
}

class _PostponeDialog extends StatefulWidget {
  const _PostponeDialog({required this.validate});

  final ValidationCode? Function(LocalDate date) validate;

  @override
  State<_PostponeDialog> createState() => _PostponeDialogState();
}

class _PostponeDialogState extends State<_PostponeDialog> {
  LocalDate? _date;
  bool _invalidText = false;
  String? _error;

  void _submit() {
    if (_invalidText) return;
    final date = _date;
    if (date == null) {
      setState(() => _error = ValidationCode.required.message);
      return;
    }
    final code = widget.validate(date);
    if (code != null) {
      setState(() => _error = code.message);
      return;
    }
    Navigator.of(context).pop(date);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adiar acompanhamento'),
      content: SizedBox(
        width: 360,
        child: DateField(
          label: 'Nova data de acompanhamento *',
          value: _date,
          errorText: _error,
          onChanged: (date, {invalid = false}) => setState(() {
            _date = date;
            _invalidText = invalid;
            _error = null;
          }),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Adiar')),
      ],
    );
  }
}
