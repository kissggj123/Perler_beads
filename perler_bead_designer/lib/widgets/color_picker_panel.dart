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
  String? _selectedCategory;
  BeadBrand? _selectedBrand;
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
