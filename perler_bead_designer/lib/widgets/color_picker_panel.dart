import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/color_palette_provider.dart';
import '../providers/design_editor_provider.dart';

class ColorPickerPanel extends StatefulWidget {
  const ColorPickerPanel({super.key});

  @override
  State<ColorPickerPanel> createState() => _ColorPickerPanelState();
}

class _ColorPickerPanelState extends State<ColorPickerPanel> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _hexInputController = TextEditingController();
  String? _selectedCategory;
  BeadBrand? _selectedBrand;
  bool _showSearch = false;
  bool _showHexInput = false;
  String? _hexValidationError;
  Color? _hexPreviewColor;

  @override
  void dispose() {
    _searchController.dispose();
    _hexInputController.dispose();
    super.dispose();
  }

  Color? _parseHexColor(String input) {
    String hex = input.trim();
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }
    if (hex.length == 3) {
      hex = hex.split('').map((c) => '$c$c').join();
    }
    if (hex.length != 6) return null;

    try {
      final value = int.parse(hex, radix: 16);
      return Color(value | 0xFF000000);
    } catch (e) {
      return null;
    }
  }

  String? _validateHexInput(String input) {
    if (input.isEmpty) return null;

    String hex = input.trim();
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }
    if (hex.length == 3) {
      return null;
    }
    if (hex.length != 6) {
      return '颜色代码应为6位十六进制数（如：224294）';
    }

    try {
      int.parse(hex, radix: 16);
      return null;
    } catch (e) {
      return '无效的十六进制颜色代码';
    }
  }

  void _onHexInputChanged(String value) {
    final error = _validateHexInput(value);
    final color = _parseHexColor(value);

    setState(() {
      _hexValidationError = error;
      _hexPreviewColor = color;
    });
  }

  void _applyHexColor(
    DesignEditorProvider editorProvider,
    ColorPaletteProvider paletteProvider,
  ) {
    if (_hexPreviewColor == null) return;

    final hex = _hexInputController.text.trim().replaceFirst('#', '');
    final code = 'HEX_${hex.toUpperCase()}';

    final existingColor = paletteProvider.getColorByCode(code);
    if (existingColor != null) {
      editorProvider.setSelectedColor(existingColor);
    } else {
      final newColor = BeadColor(
        code: code,
        name: '自定义 #${hex.toUpperCase()}',
        red: (_hexPreviewColor!.r * 255.0).round().clamp(0, 255),
        green: (_hexPreviewColor!.g * 255.0).round().clamp(0, 255),
        blue: (_hexPreviewColor!.b * 255.0).round().clamp(0, 255),
        brand: BeadBrand.generic,
        category: '自定义',
      );
      paletteProvider.addCustomColor(newColor);
      editorProvider.setSelectedColor(newColor);
    }

    _hexInputController.clear();
    setState(() {
      _hexPreviewColor = null;
      _hexValidationError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ColorPaletteProvider, DesignEditorProvider>(
      builder: (context, paletteProvider, editorProvider, child) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              _buildHeader(context),
              _buildRecentColors(context, editorProvider),
              const Divider(height: 1),
              _buildHexInput(context, paletteProvider, editorProvider),
              _buildSearchBar(context, paletteProvider),
              _buildFilters(context, paletteProvider),
              const Divider(height: 1),
              Expanded(
                child: _buildColorGrid(
                  context,
                  paletteProvider,
                  editorProvider,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        children: [
          Icon(
            Icons.palette,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '颜色选择',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.add_circle_outline, size: 20),
            onPressed: () {
              setState(() {
                _showHexInput = !_showHexInput;
              });
            },
            tooltip: _showHexInput ? '隐藏颜色输入' : '输入颜色代码',
          ),
          IconButton(
            icon: Icon(_showSearch ? Icons.search_off : Icons.search, size: 20),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  context.read<ColorPaletteProvider>().setSearchQuery('');
                }
              });
            },
            tooltip: _showSearch ? '隐藏搜索' : '搜索',
          ),
        ],
      ),
    );
  }

  Widget _buildRecentColors(
    BuildContext context,
    DesignEditorProvider editorProvider,
  ) {
    final recentColors = editorProvider.recentColors;
    if (recentColors.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                size: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '最近使用',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recentColors.length,
              separatorBuilder: (context, index) => const SizedBox(width: 4),
              itemBuilder: (context, index) {
                final color = recentColors[index];
                return _buildColorChip(
                  context,
                  color,
                  editorProvider.selectedColor?.code == color.code,
                  editorProvider,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, ColorPaletteProvider provider) {
    if (!_showSearch) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索颜色名称或代码...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    _searchController.clear();
                    provider.setSearchQuery('');
                    setState(() {});
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          isDense: true,
        ),
        onChanged: (value) {
          provider.setSearchQuery(value);
          setState(() {});
        },
      ),
    );
  }

  Widget _buildHexInput(
    BuildContext context,
    ColorPaletteProvider paletteProvider,
    DesignEditorProvider editorProvider,
  ) {
    if (!_showHexInput) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _hexInputController,
                  decoration: InputDecoration(
                    hintText: '输入颜色代码 (如: #224294)',
                    prefixIcon: const Icon(Icons.colorize, size: 20),
                    suffixIcon: _hexInputController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _hexInputController.clear();
                              _onHexInputChanged('');
                            },
                          )
                        : null,
                    errorText: _hexValidationError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  onChanged: _onHexInputChanged,
                  onSubmitted: (_) {
                    if (_hexPreviewColor != null &&
                        _hexValidationError == null) {
                      _applyHexColor(editorProvider, paletteProvider);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              if (_hexPreviewColor != null && _hexValidationError == null)
                GestureDetector(
                  onTap: () => _applyHexColor(editorProvider, paletteProvider),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _hexPreviewColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
                    ),
                  ),
                )
              else
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Icon(Icons.help_outline, color: Colors.grey.shade500),
                ),
            ],
          ),
          if (_hexPreviewColor != null && _hexValidationError == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _hexPreviewColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '预览: #${_hexInputController.text.trim().replaceFirst('#', '').toUpperCase()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'RGB(${(_hexPreviewColor!.r * 255.0).round()}, ${(_hexPreviewColor!.g * 255.0).round()}, ${(_hexPreviewColor!.b * 255.0).round()})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, ColorPaletteProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _buildCategoryFilter(context, provider)),
          const SizedBox(width: 8),
          Expanded(child: _buildBrandFilter(context, provider)),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(
    BuildContext context,
    ColorPaletteProvider provider,
  ) {
    final categories = provider.availableCategories;

    return DropdownButtonFormField<String?>(
      initialValue: _selectedCategory,
      decoration: InputDecoration(
        labelText: '分类',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('全部')),
        ...categories.map(
          (category) => DropdownMenuItem(
            value: category,
            child: Text(category, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
        provider.setCategory(value);
      },
    );
  }

  Widget _buildBrandFilter(
    BuildContext context,
    ColorPaletteProvider provider,
  ) {
    return DropdownButtonFormField<BeadBrand?>(
      initialValue: _selectedBrand,
      decoration: InputDecoration(
        labelText: '品牌',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('全部')),
        ...BeadBrand.values.map(
          (brand) =>
              DropdownMenuItem(value: brand, child: Text(_getBrandName(brand))),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _selectedBrand = value;
        });
        provider.setBrand(value);
      },
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

  Widget _buildColorGrid(
    BuildContext context,
    ColorPaletteProvider paletteProvider,
    DesignEditorProvider editorProvider,
  ) {
    final colors = paletteProvider.filteredColors;

    if (colors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '未找到匹配的颜色',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                paletteProvider.clearFilters();
                setState(() {
                  _selectedCategory = null;
                  _selectedBrand = null;
                });
              },
              child: const Text('清除筛选'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 48,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final color = colors[index];
        final isSelected = editorProvider.selectedColor?.code == color.code;
        return _buildColorItem(context, color, isSelected, editorProvider);
      },
    );
  }

  Widget _buildColorItem(
    BuildContext context,
    BeadColor color,
    bool isSelected,
    DesignEditorProvider editorProvider,
  ) {
    return Tooltip(
      message: '${color.name}\n${color.code}\n${color.hex}',
      preferBelow: false,
      child: GestureDetector(
        onTap: () {
          editorProvider.setSelectedColor(color);
        },
        child: Container(
          decoration: BoxDecoration(
            color: color.color,
            borderRadius: BorderRadius.circular(4),
            border: isSelected
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3,
                  )
                : Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: color.isLight
              ? null
              : Icon(
                  Icons.circle,
                  size: 8,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
        ),
      ),
    );
  }

  Widget _buildColorChip(
    BuildContext context,
    BeadColor color,
    bool isSelected,
    DesignEditorProvider editorProvider,
  ) {
    return Tooltip(
      message: '${color.name} (${color.code})',
      child: GestureDetector(
        onTap: () {
          editorProvider.setSelectedColor(color);
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.color,
            borderRadius: BorderRadius.circular(4),
            border: isSelected
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : Border.all(color: Colors.grey.shade300, width: 1),
          ),
        ),
      ),
    );
  }
}
