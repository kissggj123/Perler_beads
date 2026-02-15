import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/standard_colors.dart';
import '../models/models.dart';
import '../providers/color_palette_provider.dart';
import '../providers/inventory_provider.dart';

class AddInventoryDialog extends StatefulWidget {
  final InventoryItem? item;

  const AddInventoryDialog({super.key, this.item});

  @override
  State<AddInventoryDialog> createState() => _AddInventoryDialogState();
}

class _AddInventoryDialogState extends State<AddInventoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _customCodeController = TextEditingController();
  final _customNameController = TextEditingController();

  BeadColor? _selectedColor;
  BeadBrand _selectedBrand = BeadBrand.perler;
  bool _useCustomColor = false;
  Color _customColorValue = const Color(0xFF808080);
  int _quantity = 100;

  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _selectedColor = widget.item!.beadColor;
      _quantity = widget.item!.quantity;
      _quantityController.text = _quantity.toString();
    } else {
      _quantityController.text = '100';
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _customCodeController.dispose();
    _customNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEditing = widget.item != null;

    return AlertDialog(
      title: Text(isEditing ? '编辑库存' : '添加库存'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildColorSourceToggle(context),
                const SizedBox(height: 16),
                if (!_useCustomColor) ...[
                  _buildColorSearch(context),
                  const SizedBox(height: 12),
                  _buildColorGrid(context),
                ] else ...[
                  _buildCustomColorForm(context),
                ],
                const SizedBox(height: 16),
                _buildQuantityInput(context),
                if (_selectedColor != null || _useCustomColor) ...[
                  const SizedBox(height: 16),
                  _buildSelectedPreview(context),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _canSubmit() ? _submit : null,
          child: Text(isEditing ? '保存' : '添加'),
        ),
      ],
    );
  }

  Widget _buildColorSourceToggle(BuildContext context) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(value: false, label: Text('从颜色库选择')),
        ButtonSegment(value: true, label: Text('自定义颜色')),
      ],
      selected: {_useCustomColor},
      onSelectionChanged: (selection) {
        setState(() {
          _useCustomColor = selection.first;
          if (!_useCustomColor) {
            _selectedColor = null;
          }
        });
      },
    );
  }

  Widget _buildColorSearch(BuildContext context) {
    final colorPaletteProvider = context.read<ColorPaletteProvider>();
    final categories = colorPaletteProvider.availableCategories;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            decoration: InputDecoration(
              hintText: '搜索颜色...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String?>(
            value: _selectedCategory,
            decoration: InputDecoration(
              hintText: '分类',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('全部分类')),
              ...categories.map(
                (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
              ),
            ],
            onChanged: (value) {
              setState(() => _selectedCategory = value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildColorGrid(BuildContext context) {
    final colorPaletteProvider = context.watch<ColorPaletteProvider>();
    var colors = colorPaletteProvider.allColors;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      colors = colors.where((c) {
        return c.name.toLowerCase().contains(query) ||
            c.code.toLowerCase().contains(query);
      }).toList();
    }

    if (_selectedCategory != null) {
      colors = colors.where((c) => c.category == _selectedCategory).toList();
    }

    if (colors.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: Text('没有找到匹配的颜色')),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 50,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: colors.length,
        itemBuilder: (context, index) {
          final color = colors[index];
          final isSelected = _selectedColor?.code == color.code;

          return Tooltip(
            message: '${color.code} - ${color.name}',
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedColor = color);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: color.color,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: color.isLight ? Colors.black : Colors.white,
                        size: 16,
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomColorForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () async {
                final color = await showDialog<Color>(
                  context: context,
                  builder: (context) =>
                      _ColorPickerDialog(initialColor: _customColorValue),
                );
                if (color != null) {
                  setState(() => _customColorValue = color);
                }
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _customColorValue,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Icon(
                  Icons.edit,
                  color: _customColorValue.computeLuminance() > 0.5
                      ? Colors.black54
                      : Colors.white70,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  TextField(
                    controller: _customCodeController,
                    decoration: const InputDecoration(
                      labelText: '颜色代码',
                      hintText: '例如: C01',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customNameController,
                    decoration: const InputDecoration(
                      labelText: '颜色名称',
                      hintText: '例如: 自定义红',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<BeadBrand>(
          value: _selectedBrand,
          decoration: const InputDecoration(
            labelText: '品牌',
            border: OutlineInputBorder(),
          ),
          items: BeadBrand.values.map((brand) {
            return DropdownMenuItem(
              value: brand,
              child: Text(_getBrandName(brand)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedBrand = value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildQuantityInput(BuildContext context) {
    return TextFormField(
      controller: _quantityController,
      decoration: InputDecoration(
        labelText: '数量',
        border: const OutlineInputBorder(),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () {
                final current = int.tryParse(_quantityController.text) ?? 0;
                if (current > 0) {
                  _quantityController.text = (current - 10).toString();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                final current = int.tryParse(_quantityController.text) ?? 0;
                _quantityController.text = (current + 10).toString();
              },
            ),
          ],
        ),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请输入数量';
        }
        final parsed = int.tryParse(value);
        if (parsed == null || parsed < 0) {
          return '请输入有效的数量';
        }
        return null;
      },
    );
  }

  Widget _buildSelectedPreview(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final previewColor = _useCustomColor
        ? _customColorValue
        : _selectedColor?.color;
    final previewName = _useCustomColor
        ? (_customNameController.text.isEmpty
              ? '自定义颜色'
              : _customNameController.text)
        : _selectedColor?.name;
    final previewCode = _useCustomColor
        ? (_customCodeController.text.isEmpty
              ? '?'
              : _customCodeController.text)
        : _selectedColor?.code;

    if (previewColor == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: previewColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                previewName ?? '',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                previewCode ?? '',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _canSubmit() {
    if (_useCustomColor) {
      return _customCodeController.text.isNotEmpty &&
          _customNameController.text.isNotEmpty;
    }
    return _selectedColor != null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final quantity = int.parse(_quantityController.text);
    final inventoryProvider = context.read<InventoryProvider>();

    BeadColor colorToUse;
    if (_useCustomColor) {
      colorToUse = BeadColor(
        code: _customCodeController.text.trim(),
        name: _customNameController.text.trim(),
        red: (_customColorValue.r * 255).round().clamp(0, 255),
        green: (_customColorValue.g * 255).round().clamp(0, 255),
        blue: (_customColorValue.b * 255).round().clamp(0, 255),
        brand: _selectedBrand,
      );
    } else {
      colorToUse = _selectedColor!;
    }

    if (widget.item != null) {
      inventoryProvider.updateItem(
        widget.item!.id,
        beadColor: colorToUse,
        quantity: quantity,
      );
    } else {
      inventoryProvider.addItem(colorToUse, quantity);
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.item != null ? '库存已更新' : '库存已添加')),
    );
  }

  String _getBrandName(BeadBrand brand) {
    switch (brand) {
      case BeadBrand.perler:
        return 'Perler';
      case BeadBrand.hama:
        return 'Hama';
      case BeadBrand.artkal:
        return 'Artkal';
      case BeadBrand.taobao:
        return '淘宝';
      case BeadBrand.pinduoduo:
        return '拼多多';
      case BeadBrand.generic:
        return '通用';
    }
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;

  const _ColorPickerDialog({required this.initialColor});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late double _red;
  late double _green;
  late double _blue;

  @override
  void initState() {
    super.initState();
    _red = widget.initialColor.r * 255;
    _green = widget.initialColor.g * 255;
    _blue = widget.initialColor.b * 255;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择颜色'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Color.fromRGBO(
                _red.round(),
                _green.round(),
                _blue.round(),
                1,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(),
            ),
          ),
          const SizedBox(height: 24),
          _buildSlider('红', _red, Colors.red, (value) => _red = value),
          _buildSlider('绿', _green, Colors.green, (value) => _green = value),
          _buildSlider('蓝', _blue, Colors.blue, (value) => _blue = value),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              Color.fromRGBO(_red.round(), _green.round(), _blue.round(), 1),
            );
          },
          child: const Text('确定'),
        ),
      ],
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    Color color,
    void Function(double) onChanged,
  ) {
    return Row(
      children: [
        SizedBox(width: 24, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 255,
            divisions: 255,
            activeColor: color,
            onChanged: (v) {
              setState(() => onChanged(v));
            },
          ),
        ),
        SizedBox(width: 40, child: Text(value.round().toString())),
      ],
    );
  }
}
