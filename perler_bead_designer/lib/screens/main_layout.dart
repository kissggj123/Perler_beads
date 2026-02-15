import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bead_color.dart';
import '../providers/app_provider.dart';
import '../providers/color_palette_provider.dart';
import '../widgets/app_drawer.dart';
import 'home_screen.dart';
import 'inventory_screen.dart';
import 'settings_screen.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final currentIndex = appProvider.currentPageIndex;
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 800;

    final pages = <Widget>[
      const HomeScreen(),
      const InventoryScreen(),
      const _ColorPaletteScreen(),
      const SettingsScreen(),
    ];

    if (isWideScreen) {
      return Scaffold(
        body: Row(
          children: [
            _buildNavigationRail(context, appProvider, currentIndex),
            VerticalDivider(
              thickness: 1,
              width: 1,
              color: colorScheme.outlineVariant,
            ),
            Expanded(child: pages[currentIndex]),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getPageTitle(currentIndex)),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
      ),
      drawer: const AppDrawer(),
      body: pages[currentIndex],
    );
  }

  Widget _buildNavigationRail(
    BuildContext context,
    AppProvider appProvider,
    int currentIndex,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isExpanded = appProvider.sidebarExpanded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isExpanded ? 200 : 72,
      child: NavigationRail(
        extended: isExpanded,
        minExtendedWidth: 200,
        leading: Column(
          children: [
            const SizedBox(height: 16),
            IconButton(
              onPressed: appProvider.toggleSidebar,
              icon: Icon(
                isExpanded ? Icons.menu_open : Icons.menu,
                color: colorScheme.onSurface,
              ),
              tooltip: isExpanded ? '收起侧边栏' : '展开侧边栏',
            ),
          ],
        ),
        selectedIndex: currentIndex,
        onDestinationSelected: appProvider.setCurrentPageIndex,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelType: isExpanded
            ? NavigationRailLabelType.none
            : NavigationRailLabelType.all,
        destinations: AppPage.values.map((page) {
          return NavigationRailDestination(
            icon: Icon(page.icon),
            selectedIcon: Icon(page.selectedIcon),
            label: Text(page.label),
          );
        }).toList(),
      ),
    );
  }

  String _getPageTitle(int index) {
    return AppPage.values
        .firstWhere(
          (page) => page.pageIndex == index,
          orElse: () => AppPage.home,
        )
        .label;
  }
}

class _ColorPaletteScreen extends StatefulWidget {
  const _ColorPaletteScreen();

  @override
  State<_ColorPaletteScreen> createState() => _ColorPaletteScreenState();
}

class _ColorPaletteScreenState extends State<_ColorPaletteScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paletteProvider = context.watch<ColorPaletteProvider>();
    final colors = paletteProvider.filteredColors;

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context, paletteProvider, colors.length),
          _buildSearchAndFilters(context, paletteProvider),
          Expanded(
            child: colors.isEmpty
                ? _buildEmptyState(context)
                : _buildColorGrid(colors, paletteProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorPaletteProvider provider,
    int count,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.palette, color: colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Text(
            '颜色库',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '共 $count 种',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (provider.customColorCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '自定义 ${provider.customColorCount}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const Spacer(),
          IconButton.outlined(
            onPressed: () => _showAddCustomColorDialog(context, provider),
            icon: const Icon(Icons.add),
            tooltip: '添加自定义颜色',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(
    BuildContext context,
    ColorPaletteProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索颜色名称、代码...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearchQuery('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                  onChanged: (value) {
                    provider.setSearchQuery(value);
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 12),
              _buildCategoryFilter(context, provider),
              const SizedBox(width: 8),
              _buildBrandFilter(context, provider),
              if (provider.searchQuery.isNotEmpty ||
                  provider.selectedCategory != null ||
                  provider.selectedBrand != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    _searchController.clear();
                    provider.clearFilters();
                  },
                  icon: const Icon(Icons.filter_alt_off),
                  tooltip: '清除筛选',
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.errorContainer,
                    foregroundColor: colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(
    BuildContext context,
    ColorPaletteProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final categories = provider.availableCategories;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: provider.selectedCategory,
          hint: const Text('分类'),
          items: [
            const DropdownMenuItem(value: null, child: Text('全部分类')),
            ...categories.map(
              (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
            ),
          ],
          onChanged: (value) => provider.setCategory(value),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildBrandFilter(
    BuildContext context,
    ColorPaletteProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final brands = provider.availableBrands;
    final brandNames = {
      BeadBrand.perler: 'Perler',
      BeadBrand.hama: 'Hama',
      BeadBrand.artkal: 'Artkal',
      BeadBrand.generic: '通用',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<BeadBrand?>(
          value: provider.selectedBrand,
          hint: const Text('品牌'),
          items: [
            const DropdownMenuItem(value: null, child: Text('全部品牌')),
            ...brands.map(
              (brand) => DropdownMenuItem(
                value: brand,
                child: Text(brandNames[brand] ?? brand.name),
              ),
            ),
          ],
          onChanged: (value) => provider.setBrand(value),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            '未找到匹配的颜色',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请尝试其他搜索条件',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildColorGrid(
    List<BeadColor> colors,
    ColorPaletteProvider provider,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final color = colors[index];
        final isCustom = provider.hasCustomColor(color.code);
        return _ColorCard(
          color: color,
          isCustom: isCustom,
          onDelete: isCustom
              ? () => _confirmDeleteColor(context, provider, color)
              : null,
        );
      },
    );
  }

  void _confirmDeleteColor(
    BuildContext context,
    ColorPaletteProvider provider,
    BeadColor color,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除颜色'),
        content: Text('确定要删除自定义颜色 "${color.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              provider.removeCustomColor(color.code);
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomColorDialog(
    BuildContext context,
    ColorPaletteProvider provider,
  ) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    int red = 128, green = 128, blue = 128;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('添加自定义颜色'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, red, green, blue),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RGB($red, $green, $blue)',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '#${red.toRadixString(16).padLeft(2, '0')}'
                                      '${green.toRadixString(16).padLeft(2, '0')}'
                                      '${blue.toRadixString(16).padLeft(2, '0')}'
                                  .toUpperCase(),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildColorSlider(
                    context,
                    'R',
                    red,
                    Colors.red,
                    (v) => setDialogState(() => red = v),
                  ),
                  _buildColorSlider(
                    context,
                    'G',
                    green,
                    Colors.green,
                    (v) => setDialogState(() => green = v),
                  ),
                  _buildColorSlider(
                    context,
                    'B',
                    blue,
                    Colors.blue,
                    (v) => setDialogState(() => blue = v),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '颜色名称 *',
                      border: OutlineInputBorder(),
                      hintText: '例如：天蓝色',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(
                      labelText: '颜色代码（可选）',
                      border: OutlineInputBorder(),
                      hintText: '例如：C001',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    provider.addCustomColor(
                      BeadColor(
                        code: codeController.text.isEmpty
                            ? 'CUSTOM_${DateTime.now().millisecondsSinceEpoch}'
                            : codeController.text,
                        name: nameController.text,
                        red: red,
                        green: green,
                        blue: blue,
                        brand: BeadBrand.generic,
                        category: '自定义',
                      ),
                    );
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('添加'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildColorSlider(
    BuildContext context,
    String label,
    int value,
    Color color,
    void Function(int) onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            divisions: 255,
            activeColor: color,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _ColorCard extends StatelessWidget {
  final BeadColor color;
  final bool isCustom;
  final VoidCallback? onDelete;

  const _ColorCard({required this.color, this.isCustom = false, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLight = color.isLight;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCustom ? colorScheme.primary : colorScheme.outlineVariant,
          width: isCustom ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showColorDetails(context),
        onLongPress: onDelete,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(color: color.color),
                  if (isCustom)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isLight ? Colors.black54 : Colors.white54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '自定义',
                          style: TextStyle(
                            fontSize: 10,
                            color: isLight ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    color.code,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    color.name,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorDetails(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brandNames = {
      BeadBrand.perler: 'Perler',
      BeadBrand.hama: 'Hama',
      BeadBrand.artkal: 'Artkal',
      BeadBrand.generic: '通用',
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outline),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(color.name, overflow: TextOverflow.ellipsis)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: color.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outline, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow(context, '代码', color.code),
            _buildDetailRow(
              context,
              'RGB',
              '${color.red}, ${color.green}, ${color.blue}',
            ),
            _buildDetailRow(context, '十六进制', color.hexCode),
            _buildDetailRow(
              context,
              '品牌',
              brandNames[color.brand] ?? color.brand.name,
            ),
            if (color.category != null)
              _buildDetailRow(context, '分类', color.category!),
            if (isCustom)
              _buildDetailRow(
                context,
                '类型',
                '自定义颜色',
                trailing: Icon(
                  Icons.edit,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ),
          ],
        ),
        actions: [
          if (onDelete != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDelete?.call();
              },
              style: TextButton.styleFrom(foregroundColor: colorScheme.error),
              child: const Text('删除'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
