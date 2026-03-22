import 'package:flutter/material.dart';
import 'package:plinkyhub/models/parameter.dart';
import 'package:plinkyhub/utils/format.dart';

class ParameterTile extends StatefulWidget {
  const ParameterTile({required this.parameter, super.key});

  final Parameter parameter;

  @override
  State<ParameterTile> createState() => _ParameterTileState();
}

class _ParameterTileState extends State<ParameterTile> {
  Parameter get parameter => widget.parameter;

  late final TextEditingController _valueController;
  late final Map<String, TextEditingController> _modulationControllers;

  @override
  void initState() {
    super.initState();
    _valueController = TextEditingController(
      text: parameter.displayValue,
    );
    _modulationControllers = {
      'base': TextEditingController(text: parameter.displayValue),
      'envelope': TextEditingController(
        text: formatValue(parameter.modulations.envelope),
      ),
      'pressure': TextEditingController(
        text: formatValue(parameter.modulations.pressure),
      ),
      'random': TextEditingController(
        text: formatValue(parameter.modulations.random),
      ),
      'a': TextEditingController(
        text: formatValue(parameter.modulations.a),
      ),
      'b': TextEditingController(
        text: formatValue(parameter.modulations.b),
      ),
      'x': TextEditingController(
        text: formatValue(parameter.modulations.x),
      ),
      'y': TextEditingController(
        text: formatValue(parameter.modulations.y),
      ),
    };
  }

  @override
  void dispose() {
    _valueController.dispose();
    for (final controller in _modulationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateControllerTexts() {
    _valueController.text = parameter.displayValue;
    _modulationControllers['base']!.text = parameter.displayValue;
    _modulationControllers['envelope']!.text =
        formatValue(parameter.modulations.envelope);
    _modulationControllers['pressure']!.text =
        formatValue(parameter.modulations.pressure);
    _modulationControllers['random']!.text =
        formatValue(parameter.modulations.random);
    _modulationControllers['a']!.text =
        formatValue(parameter.modulations.a);
    _modulationControllers['b']!.text =
        formatValue(parameter.modulations.b);
    _modulationControllers['x']!.text =
        formatValue(parameter.modulations.x);
    _modulationControllers['y']!.text =
        formatValue(parameter.modulations.y);
  }

  void _onSliderChanged(double newValue) {
    setState(() {
      parameter.value = newValue.round();
      _updateControllerTexts();
    });
  }

  void _onDropdownChanged(int? newValue) {
    if (newValue == null) {
      return;
    }
    setState(() {
      parameter.value = newValue;
      _updateControllerTexts();
    });
  }

  void _onNormalizedValueChanged(String text) {
    final parsed = double.tryParse(text);
    if (parsed == null) {
      return;
    }
    final denormalized = denormalize(parsed).round();
    final rangeMinimum = parameter.minimum < 0 ? -1024 : 0;
    const rangeMaximum = 1024;
    setState(() {
      parameter.value =
          denormalized.clamp(rangeMinimum, rangeMaximum);
      _updateControllerTexts();
    });
  }

  void _onModulationChanged(String source, String text) {
    final parsed = double.tryParse(text);
    if (parsed == null) {
      return;
    }
    final denormalized = denormalize(parsed).round().clamp(-1024, 1024);
    setState(() {
      switch (source) {
        case 'envelope':
          parameter.modulations.envelope = denormalized;
        case 'pressure':
          parameter.modulations.pressure = denormalized;
        case 'a':
          parameter.modulations.a = denormalized;
        case 'b':
          parameter.modulations.b = denormalized;
        case 'x':
          parameter.modulations.x = denormalized;
        case 'y':
          parameter.modulations.y = denormalized;
        case 'random':
          parameter.modulations.random = denormalized;
      }
      _updateControllerTexts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectOptions = parameter.getSelectOptions();
    final hasDropdown = selectOptions != null;
    final rangeMinimum = parameter.minimum < 0 ? -1024.0 : 0.0;
    const rangeMaximum = 1024.0;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            color: colorScheme.primaryContainer,
            child: Row(
              children: [
                Image.asset(
                  'assets/icons/${parameter.icon}',
                  width: 40,
                  height: 40,
                  color: colorScheme.onPrimaryContainer,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(width: 40, height: 40),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    parameter.name ?? parameter.id,
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                if (!hasDropdown)
                  SizedBox(
                    width: 64,
                    child: TextField(
                      controller: _valueController,
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      onSubmitted: _onNormalizedValueChanged,
                    ),
                  ),
              ],
            ),
          ),
          // Body
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (hasDropdown)
                  DropdownButton<int>(
                    value: parameter.getActiveSelectOption()?.value,
                    isExpanded: true,
                    items: selectOptions.map((option) {
                      return DropdownMenuItem<int>(
                        value: option.value,
                        child: Text(option.label),
                      );
                    }).toList(),
                    onChanged: _onDropdownChanged,
                  )
                else
                  Slider(
                    value: parameter.value.toDouble().clamp(
                          rangeMinimum,
                          rangeMaximum,
                        ),
                    min: rangeMinimum,
                    max: rangeMaximum,
                    inactiveColor: colorScheme.onSurface.withValues(alpha: 0.3),
                    onChanged: _onSliderChanged,
                  ),
                // Modulation matrix
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ModulationColumn(
                        entries: {
                          'Base': _modulationControllers['base']!,
                          'Env': _modulationControllers['envelope']!,
                          'Pressure': _modulationControllers['pressure']!,
                          'Random': _modulationControllers['random']!,
                        },
                        onChanged: (source, value) {
                          final sourceKey = switch (source) {
                            'Env' => 'envelope',
                            'Pressure' => 'pressure',
                            'Random' => 'random',
                            'Base' => 'base',
                            _ => source.toLowerCase(),
                          };
                          if (sourceKey == 'base') {
                            _onNormalizedValueChanged(value);
                          } else {
                            _onModulationChanged(sourceKey, value);
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: _ModulationColumn(
                        entries: {
                          'A': _modulationControllers['a']!,
                          'B': _modulationControllers['b']!,
                          'X': _modulationControllers['x']!,
                          'Y': _modulationControllers['y']!,
                        },
                        labelOnRight: true,
                        onChanged: (source, value) {
                          _onModulationChanged(source.toLowerCase(), value);
                        },
                      ),
                    ),
                  ],
                ),
                // Description
                ExpansionTile(
                  title: const Text(
                    'Details',
                    style: TextStyle(fontSize: 14),
                  ),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  children: [
                    Text(
                      parameter.description,
                      style: const TextStyle(fontSize: 12, height: 1.3),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModulationColumn extends StatelessWidget {
  const _ModulationColumn({
    required this.entries,
    required this.onChanged,
    this.labelOnRight = false,
  });

  final Map<String, TextEditingController> entries;
  final void Function(String source, String value) onChanged;
  final bool labelOnRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: entries.entries.map((entry) {
        final label = Text(
          entry.key,
          style: const TextStyle(fontSize: 14),
        );
        final field = SizedBox(
          width: 64,
          child: TextField(
            controller: entry.value,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 4,
              ),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) => onChanged(entry.key, value),
          ),
        );
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: SizedBox(
            height: 30,
            child: Row(
              mainAxisAlignment: labelOnRight
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.end,
              children: labelOnRight
                  ? [field, const SizedBox(width: 8), label]
                  : [label, const SizedBox(width: 8), field],
            ),
          ),
        );
      }).toList(),
    );
  }
}
