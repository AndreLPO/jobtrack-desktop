import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/time/local_date.dart';
import '../../../core/widgets/date_field.dart';
import '../models/application_channel.dart';
import '../models/application_query.dart';
import '../../settings/models/applications_view_mode.dart';
import '../models/application_status.dart';
import 'labels.dart';

/// Busca, filtros e ordenação da listagem (RF-04).
class ApplicationsToolbar extends StatelessWidget {
  const ApplicationsToolbar({
    super.key,
    required this.filter,
    required this.sort,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.viewMode,
    required this.onViewModeChanged,
  });

  final ApplicationFilter filter;
  final ApplicationSort sort;
  final ValueChanged<ApplicationFilter> onFilterChanged;
  final ValueChanged<ApplicationSort> onSortChanged;
  final ApplicationsViewMode viewMode;
  final ValueChanged<ApplicationsViewMode> onViewModeChanged;

  Future<void> _pickPeriod(BuildContext context) async {
    final period = await showDialog<_Period>(
      context: context,
      builder: (_) => _PeriodDialog(from: filter.from, to: filter.to),
    );
    if (period == null) return;
    onFilterChanged(
      filter.copyWith(from: () => period.from, to: () => period.to),
    );
  }

  String get _periodLabel {
    final from = filter.from;
    final to = filter.to;
    if (from == null && to == null) return 'Período';
    if (from != null && to != null) {
      return 'Período: ${formatDate(from)} a ${formatDate(to)}';
    }
    return from != null
        ? 'Período: a partir de ${formatDate(from)}'
        : 'Período: até ${formatDate(to!)}';
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: _SearchField(
            text: filter.text,
            onChanged: (text) => onFilterChanged(filter.copyWith(text: text)),
          ),
        ),
        _MultiSelectMenu<ApplicationStatus>(
          label: 'Status',
          options: ApplicationStatus.values,
          optionLabel: (s) => s.label,
          selected: filter.statuses,
          onChanged: (s) => onFilterChanged(filter.copyWith(statuses: s)),
        ),
        _MultiSelectMenu<ApplicationChannel>(
          label: 'Canal',
          options: ApplicationChannel.values,
          optionLabel: (c) => c.label,
          selected: filter.channels,
          onChanged: (c) => onFilterChanged(filter.copyWith(channels: c)),
        ),
        _ToolbarButton(
          label: _periodLabel,
          active: filter.from != null || filter.to != null,
          icon: Icons.date_range_outlined,
          onPressed: () => _pickPeriod(context),
        ),
        FilterChip(
          label: const Text('Precisam de acompanhamento'),
          selected: filter.onlyNeedingFollowUp,
          onSelected: (value) =>
              onFilterChanged(filter.copyWith(onlyNeedingFollowUp: value)),
        ),
        _SortMenu(sort: sort, onChanged: onSortChanged),
        SegmentedButton<ApplicationsViewMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: ApplicationsViewMode.list,
              icon: Icon(Icons.view_list_outlined, size: 18),
              label: Text('Lista'),
            ),
            ButtonSegment(
              value: ApplicationsViewMode.board,
              icon: Icon(Icons.view_kanban_outlined, size: 18),
              label: Text('Quadro'),
            ),
          ],
          selected: {viewMode},
          onSelectionChanged: (selection) =>
              onViewModeChanged(selection.single),
        ),
      ],
    );
  }
}

extension ApplicationSortLabel on ApplicationSort {
  String get label => switch (this) {
    ApplicationSort.applicationDate => 'Data da candidatura',
    ApplicationSort.updatedAt => 'Última atualização',
    ApplicationSort.nextFollowUp => 'Próximo acompanhamento',
  };
}

class _SearchField extends StatefulWidget {
  const _SearchField({required this.text, required this.onChanged});

  final String text;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final _controller = TextEditingController(text: widget.text);

  @override
  void didUpdateWidget(_SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // "Limpar filtros" limpa também o texto digitado.
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
      decoration: const InputDecoration(
        isDense: true,
        prefixIcon: Icon(Icons.search, size: 20),
        hintText: 'Buscar empresa ou vaga',
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.label,
    required this.active,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final bool active;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = active
        ? OutlinedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          )
        : null;
    return icon == null
        ? OutlinedButton(onPressed: onPressed, style: style, child: Text(label))
        : OutlinedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 18),
            label: Text(label),
          );
  }
}

class _MultiSelectMenu<T> extends StatelessWidget {
  const _MultiSelectMenu({
    required this.label,
    required this.options,
    required this.optionLabel,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final List<T> options;
  final String Function(T) optionLabel;
  final Set<T> selected;
  final ValueChanged<Set<T>> onChanged;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: [
        for (final option in options)
          CheckboxMenuButton(
            value: selected.contains(option),
            closeOnActivate: false,
            onChanged: (checked) => onChanged(
              checked == true
                  ? {...selected, option}
                  : ({...selected}..remove(option)),
            ),
            child: Text(optionLabel(option)),
          ),
        if (selected.isNotEmpty) ...[
          const Divider(),
          MenuItemButton(
            onPressed: () => onChanged(const {}),
            child: const Text('Limpar seleção'),
          ),
        ],
      ],
      builder: (context, menu, _) => _ToolbarButton(
        label: selected.isEmpty ? label : '$label (${selected.length})',
        active: selected.isNotEmpty,
        icon: Icons.arrow_drop_down,
        onPressed: () => menu.isOpen ? menu.close() : menu.open(),
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.sort, required this.onChanged});

  final ApplicationSort sort;
  final ValueChanged<ApplicationSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: [
        for (final option in ApplicationSort.values)
          MenuItemButton(
            leadingIcon: Icon(option == sort ? Icons.check : null, size: 18),
            onPressed: () => onChanged(option),
            child: Text(option.label),
          ),
      ],
      builder: (context, menu, _) => TextButton.icon(
        onPressed: () => menu.isOpen ? menu.close() : menu.open(),
        icon: const Icon(Icons.sort, size: 18),
        label: Text('Ordenar: ${sort.label}'),
      ),
    );
  }
}

typedef _Period = ({LocalDate? from, LocalDate? to});

class _PeriodDialog extends StatefulWidget {
  const _PeriodDialog({required this.from, required this.to});

  final LocalDate? from;
  final LocalDate? to;

  @override
  State<_PeriodDialog> createState() => _PeriodDialogState();
}

class _PeriodDialogState extends State<_PeriodDialog> {
  late LocalDate? _from = widget.from;
  late LocalDate? _to = widget.to;
  final _invalid = <String>{};
  String? _rangeError;

  void _apply() {
    if (_invalid.isNotEmpty) return;
    if (_from != null && _to != null && _from!.isAfter(_to!)) {
      setState(() => _rangeError = 'A data inicial deve ser anterior à final.');
      return;
    }
    Navigator.of(context).pop((from: _from, to: _to));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Período da candidatura'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DateField(
              label: 'De',
              value: _from,
              onChanged: (date, {invalid = false}) => setState(() {
                _from = date;
                _rangeError = null;
                invalid ? _invalid.add('from') : _invalid.remove('from');
              }),
            ),
            const SizedBox(height: AppSpacing.lg),
            DateField(
              label: 'Até',
              value: _to,
              errorText: _rangeError,
              onChanged: (date, {invalid = false}) => setState(() {
                _to = date;
                _rangeError = null;
                invalid ? _invalid.add('to') : _invalid.remove('to');
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop((from: null, to: null)),
          child: const Text('Limpar período'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _apply, child: const Text('Aplicar')),
      ],
    );
  }
}
