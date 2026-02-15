import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/inventory_provider.dart';
import '../widgets/add_inventory_dialog.dart';
import '../widgets/import_inventory_dialog.dart';
import '../widgets/inventory_item_tile.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  bool _showLowStockOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadInventory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final inventoryProvider = context.watch<InventoryProvider>();

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context, inventoryProvider),
          Expanded(
            child: inventoryProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(context, inventoryProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('添加库存'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, InventoryProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStatisticsRow(context, provider),
          const SizedBox(height: 16),
          _buildSearchAndFilters(context, provider),
        ],
      ),
    );
  }

  Widget _buildStatisticsRow(BuildContext context, InventoryProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.inventory_2,
            label: '总颜色数',
            value: '${provider.colorCount}',
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.grain,
            label: '总数量',
            value: '${provider.totalQuantity}',
            color: colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.warning_amber,
            label: '低库存',
            value: '${provider.lowStockItems.length}',
            color: provider.hasLowStock
                ? colorScheme.error
                : colorScheme.tertiary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.block,
            label: '缺货',
            value: '${provider.outOfStockItems.length}',
            color: provider.hasOutOfStock
                ? colorScheme.error
                : colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(
    BuildContext context,
    InventoryProvider provider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索颜色名称或代码...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        provider.setSearchQuery('');
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
            ),
            onChanged: (value) {
              provider.setSearchQuery(value);
              setState(() {});
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _buildCategoryFilter(context, provider)),
        const SizedBox(width: 12),
        Expanded(child: _buildBrandFilter(context, provider)),
        const SizedBox(width: 12),
        FilterChip(
          label: const Text('仅低库存'),
          selected: _showLowStockOnly,
          onSelected: (selected) {
            setState(() => _showLowStockOnly = selected);
          },
          selectedColor: colorScheme.errorContainer,
          checkmarkColor: colorScheme.onErrorContainer,
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          onPressed: () => _showImportDialog(context),
          icon: const Icon(Icons.file_upload),
          tooltip: '导入',
        ),
        IconButton.outlined(
          onPressed: () => _showExportDialog(context, provider),
          icon: const Icon(Icons.file_download),
          tooltip: '导出',
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(
    BuildContext context,
    InventoryProvider provider,
  ) {
    return DropdownButtonFormField<String?>(
      value: provider.selectedCategory,
      decoration: InputDecoration(
        labelText: '分类',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('全部分类')),
        ...provider.availableCategories.map((category) {
          return DropdownMenuItem(value: category, child: Text(category));
        }),
      ],
      onChanged: (value) {
        provider.setCategory(value);
      },
    );
  }

  Widget _buildBrandFilter(BuildContext context, InventoryProvider provider) {
    return DropdownButtonFormField<BeadBrand?>(
      value: provider.selectedBrand,
      decoration: InputDecoration(
        labelText: '品牌',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('全部品牌')),
        ...BeadBrand.values.map((brand) {
          return DropdownMenuItem(
            value: brand,
            child: Text(_getBrandName(brand)),
          );
        }),
      ],
      onChanged: (value) {
        provider.setBrand(value);
      },
    );
  }

  Widget _buildContent(BuildContext context, InventoryProvider provider) {
    var items = provider.filteredItems;

    if (_showLowStockOnly) {
      items = items
          .where((item) => item.quantity <= provider.lowStockThreshold)
          .toList();
    }

    if (items.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        _buildTableHeader(context),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return InventoryItemTile(
                item: item,
                lowStockThreshold: provider.lowStockThreshold,
                onEdit: () => _showEditDialog(context, provider, item),
                onDelete: () => _confirmDelete(context, provider, item),
                onQuantityChanged: (newQuantity) {
                  provider.updateQuantity(item.beadColor.code, newQuantity);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest),
      child: const Row(
        children: [
          SizedBox(
            width: 48,
            child: Text('颜色', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            width: 80,
            child: Text('代码', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 2,
            child: Text('名称', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text('品牌', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text('分类', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            width: 100,
            child: Text('数量', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            width: 100,
            child: Text('操作', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            '暂无库存数据',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: colorScheme.outline),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮添加库存，或导入现有数据',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => _showAddDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('添加库存'),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => _showImportDialog(context),
                icon: const Icon(Icons.file_upload),
                label: const Text('导入数据'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddInventoryDialog(),
    );
  }

  void _showEditDialog(
    BuildContext context,
    InventoryProvider provider,
    InventoryItem item,
  ) {
    showDialog(
      context: context,
      builder: (context) => AddInventoryDialog(item: item),
    );
  }

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ImportInventoryDialog(),
    );
  }

  void _showExportDialog(BuildContext context, InventoryProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出库存'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('导出为 CSV'),
              subtitle: const Text('适合电子表格软件'),
              onTap: () async {
                Navigator.of(context).pop();
                final success = await provider.exportToCsvFile();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? '导出成功' : '导出失败')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('导出为 JSON'),
              subtitle: const Text('适合数据交换'),
              onTap: () async {
                Navigator.of(context).pop();
                final success = await provider.exportToJsonFile();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? '导出成功' : '导出失败')),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    InventoryProvider provider,
    InventoryItem item,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${item.beadColor.name}" 的库存记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              provider.removeItem(item.id);
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
