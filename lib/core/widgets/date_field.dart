import 'package:flutter/material.dart';

import '../formatting/date_format.dart';
import '../time/local_date.dart';

/// Campo de data em dd/MM/yyyy com botão de calendário (D-06).
///
/// [onChanged] recebe a data válida, ou `null` com `invalid: true` se o
/// texto não for uma data existente. Texto vazio é `null` e válido.
class DateField extends StatefulWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.helperText,
  });

  final String label;
  final LocalDate? value;
  final void Function(LocalDate? date, {bool invalid}) onChanged;
  final String? errorText;
  final String? helperText;

  @override
  State<DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<DateField> {
  late final TextEditingController _text;
  bool _invalidFormat = false;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(
      text: widget.value == null ? '' : formatDate(widget.value!),
    );
  }

  @override
  void didUpdateWidget(DateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final value = widget.value;
    if (value != null && parseDate(_text.text) != value) {
      _text.text = formatDate(value);
      _invalidFormat = false;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _onText(String text) {
    if (text.trim().isEmpty) {
      setState(() => _invalidFormat = false);
      widget.onChanged(null);
      return;
    }
    final date = parseDate(text);
    setState(() => _invalidFormat = date == null);
    widget.onChanged(date, invalid: date == null);
  }

  Future<void> _pick() async {
    final initial = widget.value?.toDateTime() ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    final date = LocalDate.fromDateTime(picked);
    _text.text = formatDate(date);
    setState(() => _invalidFormat = false);
    widget.onChanged(date);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _text,
      onChanged: _onText,
      keyboardType: TextInputType.datetime,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: 'dd/mm/aaaa',
        helperText: widget.helperText,
        errorText: _invalidFormat
            ? 'Data inválida. Use dd/mm/aaaa.'
            : widget.errorText,
        suffixIcon: IconButton(
          tooltip: 'Abrir calendário',
          icon: const Icon(Icons.calendar_today_outlined, size: 18),
          onPressed: _pick,
        ),
      ),
    );
  }
}
