import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/settings_service.dart';

class ThemeColorPickerScreen extends StatefulWidget {
  const ThemeColorPickerScreen({super.key});

  @override
  State<ThemeColorPickerScreen> createState() => _ThemeColorPickerScreenState();
}

class _ThemeColorPickerScreenState extends State<ThemeColorPickerScreen> {
  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '主题配色',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '自定义应用的主题颜色',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            _buildPresetThemesSection(context, appProvider),
            const SizedBox(height: 24),
            _buildCustomColorsSection(context, appProvider),
            const SizedBox(height: 24),
            _buildSavedSchemesSection(context, appProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetThemesSection(
    BuildContext context,
    AppProvider appProvider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(Icons.palette, size: 20, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  '预设主题',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: PresetThemeType.values.length,
              itemBuilder: (context, index) {
                final preset = PresetThemeType.values[index];
                final colors = ThemeColors.fromPreset(preset);
                final isSelected =
                    appProvider.presetTheme == preset &&
                    !appProvider.isCustomTheme;

                return _PresetThemeCard(
                  colors: colors,
                  isSelected: isSelected,
                  onTap: () => appProvider.setPresetTheme(preset),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomColorsSection(
    BuildContext context,
    AppProvider appProvider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(Icons.tune, size: 20, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  '自定义颜色',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (appProvider.isCustomTheme)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '自定义',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ColorSliderRow(
                  label: '主色调',
                  color: appProvider.themeColors.primaryColor,
                  onChanged: (color) {
                    appProvider.updatePrimaryColorImmediate(color);
                  },
                  onChangeEnd: (color) {
                    appProvider.persistThemeColors();
                  },
                ),
                const SizedBox(height: 16),
                _ColorSliderRow(
                  label: '次色调',
                  color: appProvider.themeColors.secondaryColor,
                  onChanged: (color) {
                    appProvider.updateSecondaryColorImmediate(color);
                  },
                  onChangeEnd: (color) {
                    appProvider.persistThemeColors();
                  },
                ),
                const SizedBox(height: 16),
                _ColorSliderRow(
                  label: '强调色',
                  color: appProvider.themeColors.accentColor,
                  onChanged: (color) {
                    appProvider.updateAccentColorImmediate(color);
                  },
                  onChangeEnd: (color) {
                    appProvider.persistThemeColors();
                  },
                ),
                const SizedBox(height: 24),
                _buildColorPreview(context, appProvider),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _saveCurrentScheme(context, appProvider),
                      icon: const Icon(Icons.save),
                      label: const Text('保存配色方案'),
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

  Widget _buildColorPreview(BuildContext context, AppProvider appProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeColors = appProvider.themeColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('预览', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              _ColorPreviewBox(color: themeColors.primaryColor, label: '主色'),
              const SizedBox(width: 12),
              _ColorPreviewBox(color: themeColors.secondaryColor, label: '次色'),
              const SizedBox(width: 12),
              _ColorPreviewBox(color: themeColors.accentColor, label: '强调'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: themeColors.primaryColor,
                  ),
                  onPressed: () {},
                  child: const Text('主按钮'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: themeColors.primaryColor,
                    side: BorderSide(color: themeColors.primaryColor),
                  ),
                  onPressed: () {},
                  child: const Text('次按钮'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: themeColors.accentColor,
              minimumSize: const Size(double.infinity, 40),
            ),
            onPressed: () {},
            child: const Text('强调按钮'),
          ),
        ],
      ),
    );
  }

  void _saveCurrentScheme(BuildContext context, AppProvider appProvider) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('保存配色方案'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '方案名称',
            border: OutlineInputBorder(),
            hintText: '例如：我的配色',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.isNotEmpty
                  ? controller.text
                  : '自定义方案 ${appProvider.savedColorSchemes.length + 1}';
              appProvider.saveCurrentColorScheme(name);
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('配色方案已保存')));
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedSchemesSection(
    BuildContext context,
    AppProvider appProvider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final savedSchemes = appProvider.savedColorSchemes;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(Icons.bookmark, size: 20, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  '已保存的配色方案',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (savedSchemes.isNotEmpty)
                  Text(
                    '${savedSchemes.length} 个',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (savedSchemes.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.bookmark_border,
                      size: 48,
                      color: colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无保存的配色方案',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '自定义颜色后点击"保存配色方案"按钮',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: savedSchemes.length,
              itemBuilder: (context, index) {
                final scheme = savedSchemes[index];
                return ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: scheme.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: scheme.secondaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: scheme.accentColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  title: Text(scheme.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline),
                        onPressed: () {
                          appProvider.loadSavedColorScheme(index);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('配色方案已应用')),
                          );
                        },
                        tooltip: '应用',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: colorScheme.error,
                        ),
                        onPressed: () {
                          appProvider.deleteSavedColorScheme(index);
                        },
                        tooltip: '删除',
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _PresetThemeCard extends StatelessWidget {
  final ThemeColors colors;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetThemeCard({
    required this.colors,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected
                ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: colors.primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: colors.secondaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: colors.accentColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  colors.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorSliderRow extends StatefulWidget {
  final String label;
  final Color color;
  final Function(Color) onChanged;
  final Function(Color) onChangeEnd;

  const _ColorSliderRow({
    required this.label,
    required this.color,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  State<_ColorSliderRow> createState() => _ColorSliderRowState();
}

class _ColorSliderRowState extends State<_ColorSliderRow> {
  late double _hue;
  late double _saturation;
  late double _value;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.color);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
  }

  @override
  void didUpdateWidget(_ColorSliderRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.color != widget.color) {
      final hsv = HSVColor.fromColor(widget.color);
      _hue = hsv.hue;
      _saturation = hsv.saturation;
      _value = hsv.value;
    }
  }

  Color get currentColor =>
      HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();

  void _updateColor() {
    widget.onChanged(currentColor);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(widget.label, style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            GestureDetector(
              onTap: () => _showColorPickerDialog(),
              child: Container(
                width: 48,
                height: 32,
                decoration: BoxDecoration(
                  color: currentColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: currentColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildHueSlider(),
        const SizedBox(height: 4),
        _buildSaturationSlider(),
        const SizedBox(height: 4),
        _buildValueSlider(),
      ],
    );
  }

  Widget _buildHueSlider() {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            'H',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(
              context,
            ).copyWith(trackShape: _HueTrackShape()),
            child: Slider(
              value: _hue,
              min: 0,
              max: 360,
              onChanged: (value) {
                setState(() {
                  _hue = value;
                  _updateColor();
                });
              },
              onChangeEnd: (value) {
                widget.onChangeEnd(currentColor);
              },
            ),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '${_hue.round()}°',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildSaturationSlider() {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            'S',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: _saturation,
            min: 0,
            max: 1,
            onChanged: (value) {
              setState(() {
                _saturation = value;
                _updateColor();
              });
            },
            onChangeEnd: (value) {
              widget.onChangeEnd(currentColor);
            },
            activeColor: currentColor,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '${(_saturation * 100).round()}%',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildValueSlider() {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            'V',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: _value,
            min: 0,
            max: 1,
            onChanged: (value) {
              setState(() {
                _value = value;
                _updateColor();
              });
            },
            onChangeEnd: (value) {
              widget.onChangeEnd(currentColor);
            },
            activeColor: currentColor,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '${(_value * 100).round()}%',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  void _showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => _FullColorPickerDialog(
        initialColor: currentColor,
        onColorSelected: (color) {
          final hsv = HSVColor.fromColor(color);
          setState(() {
            _hue = hsv.hue;
            _saturation = hsv.saturation;
            _value = hsv.value;
            _updateColor();
          });
          widget.onChangeEnd(currentColor);
        },
      ),
    );
  }
}

class _HueTrackShape extends SliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 4;
    final trackLeft = offset.dx;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    bool isInteractive = false,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFF0000),
          Color(0xFFFFFF00),
          Color(0xFF00FF00),
          Color(0xFF00FFFF),
          Color(0xFF0000FF),
          Color(0xFFFF00FF),
          Color(0xFFFF0000),
        ],
      ).createShader(rect);

    final radius = Radius.circular(rect.height / 2);
    context.canvas.drawRRect(
      RRect.fromRectAndCorners(
        rect,
        topLeft: radius,
        bottomLeft: radius,
        topRight: radius,
        bottomRight: radius,
      ),
      paint,
    );
  }
}

class _ColorPreviewBox extends StatelessWidget {
  final Color color;
  final String label;

  const _ColorPreviewBox({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _FullColorPickerDialog extends StatefulWidget {
  final Color initialColor;
  final Function(Color) onColorSelected;

  const _FullColorPickerDialog({
    required this.initialColor,
    required this.onColorSelected,
  });

  @override
  State<_FullColorPickerDialog> createState() => _FullColorPickerDialogState();
}

class _FullColorPickerDialogState extends State<_FullColorPickerDialog> {
  late double _hue;
  late double _saturation;
  late double _value;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initialColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
  }

  Color get currentColor =>
      HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择颜色'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                boxShadow: [
                  BoxShadow(
                    color: currentColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildColorWheel(),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('饱和度'),
                Expanded(
                  child: Slider(
                    value: _saturation,
                    onChanged: (value) {
                      setState(() {
                        _saturation = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text('明度'),
                Expanded(
                  child: Slider(
                    value: _value,
                    onChanged: (value) {
                      setState(() {
                        _value = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            widget.onColorSelected(currentColor);
            Navigator.pop(context);
          },
          child: const Text('确定'),
        ),
      ],
    );
  }

  Widget _buildColorWheel() {
    return SizedBox(
      width: 200,
      height: 200,
      child: CustomPaint(
        painter: _ColorWheelPainter(_hue),
        child: GestureDetector(
          onPanStart: (details) => _updateHue(details.localPosition),
          onPanUpdate: (details) => _updateHue(details.localPosition),
        ),
      ),
    );
  }

  void _updateHue(Offset localPosition) {
    final center = Offset(100, 100);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final angle = (atan2(dy, dx) * 180 / pi + 360) % 360;
    setState(() {
      _hue = angle;
    });
  }
}

class _ColorWheelPainter extends CustomPainter {
  final double selectedHue;

  _ColorWheelPainter(this.selectedHue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (int i = 0; i < 360; i++) {
      final paint = Paint()
        ..color = HSVColor.fromAHSV(1.0, i.toDouble(), 1.0, 1.0).toColor()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final angle = i * pi / 180;
      final x1 = center.dx + (radius - 20) * cos(angle);
      final y1 = center.dy + (radius - 20) * sin(angle);
      final x2 = center.dx + radius * cos(angle);
      final y2 = center.dy + radius * sin(angle);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }

    final selectorAngle = selectedHue * pi / 180;
    final selectorX = center.dx + (radius - 10) * cos(selectorAngle);
    final selectorY = center.dy + (radius - 10) * sin(selectorAngle);

    final selectorPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(selectorX, selectorY), 8, selectorPaint);

    final borderPaint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(Offset(selectorX, selectorY), 8, borderPaint);
  }

  @override
  bool shouldRepaint(_ColorWheelPainter oldDelegate) {
    return oldDelegate.selectedHue != selectedHue;
  }
}
