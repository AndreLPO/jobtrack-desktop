import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../models/application_status.dart';
import 'labels.dart';

typedef StatusChoice = ({ApplicationStatus status, String note});

/// Diálogo "Alterar status" (F3). Devolve `null` se cancelado.
Future<StatusChoice?> showChangeStatusDialog(
  BuildContext context, {
  required ApplicationStatus current,
}) {
  return showDialog<StatusChoice>(
    context: context,
    builder: (_) => _ChangeStatusDialog(current: current),
  );
}

class _ChangeStatusDialog extends StatefulWidget {
  const _ChangeStatusDialog({required this.current});

  final ApplicationStatus current;

  @override
  State<_ChangeStatusDialog> createState() => _ChangeStatusDialogState();
}

class _ChangeStatusDialogState extends State<_ChangeStatusDialog> {
  late ApplicationStatus _selected = widget.current;
  String _note = '';

  @override
  Widget build(BuildContext context) {
    final unchanged = _selected == widget.current;
    return AlertDialog(
      title: const Text('Alterar status'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Status atual: ${widget.current.label}'),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<ApplicationStatus>(
              initialValue: _selected,
              decoration: const InputDecoration(labelText: 'Novo status'),
              items: [
                for (final status in ApplicationStatus.values)
                  DropdownMenuItem(value: status, child: Text(status.label)),
              ],
              onChanged: (value) => setState(() => _selected = value!),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              onChanged: (value) => _note = value,
              maxLines: 3,
              minLines: 2,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: unchanged
              ? null
              : () =>
                    Navigator.of(context).pop((status: _selected, note: _note)),
          child: const Text('Alterar'),
        ),
      ],
    );
  }
}
