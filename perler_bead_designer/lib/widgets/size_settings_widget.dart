import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SizeSettingsWidget extends StatefulWidget {
  final int width;
  final int height;
  final bool maintainAspectRatio;
  final ValueChanged<int> onWidthChanged;
  final ValueChanged<int> onHeightChanged;
  final ValueChanged<bool> onMaintainAspectRatioChanged;
  final ValueChanged<int>? onPresetSelected;

  const SizeSettingsWidget({
    super.key,
    required this.width,
    required this.height,
    required this.maintainAspectRatio,
    required this.onWidthChanged,
    required this.onHeightChanged,
    required this.onMaintainAspectRatioChanged,
    this.onPresetSelected,
  });

  @override
  State<SizeSettingsWidget> createState() => _SizeSettingsWidgetState();
}

class _SizeSettingsWidgetState extends State<SizeSettingsWidget> {
  late TextEditingController _widthController;
  late TextEditingController _heightController;

  final List<Map<String, dynamic>> _presets = [
    {'name': '15×15', 'size': 15, 'description': '迷你板'},
    {'name': '29×29', 'size': 29, 'description': '小号板'},
    {'name': '35×35', 'size': 35, 'description': '中号板'},
    {'name': '50×50', 'size': 50, 'description': '大号板'},
    {'name': '75×75', 'size': 75, 'description': '超大板'},
    {'name': '100×100', 'size': 100, 'description': '巨型板'},
  ];

  @override
  void initState() {
    super.initState();
    _widthController = TextEditingController(text: widget.width.toString());
    _heightController = TextEditingController(text: widget.height.toString());
  }

  @override
  void didUpdateWidget(SizeSettingsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.width != widget.width) {
      _widthController.text = widget.width.toString();
    }
    if (oldWidget.height != widget.height) {
      _heightController.text = widget.height.toString();
    }
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildPresetButtons(context),
            const SizedBox(height: 16),
            _buildDimensionInputs(context),
            const SizedBox(height: 12),
            _buildAspectRatioToggle(context),
            const SizedBox(height: 12),
            _buildSizeInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.settings),
        const SizedBox(width: 8),
        Text('输出尺寸设置', style: Theme.of(context).textTheme.titleMedium),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            '${widget.width * widget.height} 珠',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '预设尺寸',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presets.map((preset) {
            final size = preset['size'] as int;
            final isSelected =
                widget.width == size &&
                (widget.height == size || !widget.maintainAspectRatio);

            return ChoiceChip(
              label: Text(preset['name'] as String),
              selected: isSelected,
              onSelected: (_) {
                widget.onPresetSelected?.call(size);
              },
              tooltip: preset['description'] as String,
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDimensionInputs(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildNumberInput(
            context,
            label: '宽度',
            value: widget.width,
            controller: _widthController,
            onChanged: widget.onWidthChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 32.0),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.maintainAspectRatio ? Icons.link : Icons.close,
              size: 16,
              color: widget.maintainAspectRatio
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildNumberInput(
            context,
            label: '高度',
            value: widget.height,
            controller: _heightController,
            onChanged: widget.onHeightChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildNumberInput(
    BuildContext context, {
    required String label,
    required int value,
    required TextEditingController controller,
    required ValueChanged<int> onChanged,
  }) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        suffixText: '珠',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      keyboardType: TextInputType.number,
      controller: controller,
      onSubmitted: (text) {
        final newValue = int.tryParse(text);
        if (newValue != null && newValue > 0 && newValue <= 500) {
          onChanged(newValue);
        } else {
          controller.text = value.toString();
        }
      },
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _NumberInputFormatter(min: 1, max: 500),
      ],
    );
  }

  Widget _buildAspectRatioToggle(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            widget.maintainAspectRatio ? Icons.lock : Icons.lock_open,
            size: 20,
            color: widget.maintainAspectRatio
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('保持宽高比', style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  widget.maintainAspectRatio ? '调整宽度时高度自动调整' : '可独立调整宽度和高度',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: widget.maintainAspectRatio,
            onChanged: widget.onMaintainAspectRatioChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSizeInfo(BuildContext context) {
    final totalBeads = widget.width * widget.height;
    String sizeCategory;
    Color categoryColor;

    if (totalBeads <= 500) {
      sizeCategory = '小型设计';
      categoryColor = Colors.green;
    } else if (totalBeads <= 2500) {
      sizeCategory = '中型设计';
      categoryColor = Colors.orange;
    } else if (totalBeads <= 5000) {
      sizeCategory = '大型设计';
      categoryColor = Colors.deepOrange;
    } else {
      sizeCategory = '巨型设计';
      categoryColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: categoryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: categoryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sizeCategory,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: categoryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '共需 $totalBeads 颗拼豆',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberInputFormatter extends TextInputFormatter {
  final int min;
  final int max;

  _NumberInputFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final value = int.tryParse(newValue.text);
    if (value == null) {
      return oldValue;
    }

    return newValue;
  }
}
