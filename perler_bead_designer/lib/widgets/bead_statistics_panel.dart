import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/design_editor_provider.dart';
import '../services/inventory_storage_service.dart';

class BeadStatisticsPanel extends StatefulWidget {
  const BeadStatisticsPanel({super.key});

  @override
  State<BeadStatisticsPanel> createState() => _BeadStatisticsPanelState();
}

class _BeadStatisticsPanelState extends State<BeadStatisticsPanel> {
  Inventory? _inventory;
  final InventoryStorageService _inventoryService = InventoryStorageService();
  bool _showInventoryComparison = true;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    try {
      final inventory = await _inventoryService.loadInventory();
      if (mounted) {
        setState(() {
          _inventory = inventory;
        });
      }
    } catch (e) {
      debugPrint('加载库存失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DesignEditorProvider>(
      builder: (context, provider, child) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              left: BorderSide(color: Theme.of(context).dividerColor, width: 1),
            ),
          ),
          child: Column(
            children: [
              _buildHeader(context),
              _buildSummary(context, provider),
              const Divider(height: 1),
              if (_showInventoryComparison && _inventory != null)
                _buildInventorySummary(context, provider),
              const Divider(height: 1),
              Expanded(child: _buildColorStatistics(context, provider)),
              const Divider(height: 1),
              _buildExportButtons(context, provider),
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
            Icons.analytics,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '拼豆统计',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (_inventory != null)
            IconButton(
              icon: Icon(
                _showInventoryComparison ? Icons.inventory : Icons.inventory_2,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _showInventoryComparison = !_showInventoryComparison;
                });
              },
              tooltip: _showInventoryComparison ? '隐藏库存对比' : '显示库存对比',
            ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadInventory,
            tooltip: '刷新库存',
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, DesignEditorProvider provider) {
    final totalCount = provider.getTotalBeadCount();
    final uniqueColors = provider.getUniqueColorCount();
    final design = provider.currentDesign;

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (design != null) ...[
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    '尺寸',
                    '${design.width} × ${design.height}',
                    Icons.grid_4x4,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    '总拼豆',
                    totalCount.toString(),
                    Icons.grain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    '颜色数',
                    uniqueColors.toString(),
                    Icons.palette,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    '填充率',
                    design.width > 0 && design.height > 0
                        ? '${((totalCount / (design.width * design.height)) * 100).toStringAsFixed(1)}%'
                        : '0%',
                    Icons.percent,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInventorySummary(
    BuildContext context,
    DesignEditorProvider provider,
  ) {
    final insufficientColors = provider.getInsufficientColors(_inventory!);

    if (insufficientColors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.check_circle, size: 20, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              '库存充足',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.errorContainer.withValues(alpha: 0.3),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning,
            size: 20,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${insufficientColors.length} 种颜色库存不足',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () =>
                _showInsufficientColorsDialog(context, insufficientColors),
            child: const Text('详情'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorStatistics(
    BuildContext context,
    DesignEditorProvider provider,
  ) {
    final stats = provider.getBeadStatistics();

    if (stats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无拼豆数据',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final sortedStats = stats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final insufficientColors = _inventory != null
        ? provider.getInsufficientColors(_inventory!)
        : <MapEntry<BeadColor, int>>[];

    final insufficientColorCodes = insufficientColors
        .map((e) => e.key.code)
        .toSet();

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: sortedStats.length,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final entry = sortedStats[index];
        final color = entry.key;
        final count = entry.value;
        final isInsufficient = insufficientColorCodes.contains(color.code);

        int? inventoryCount;
        if (_inventory != null) {
          inventoryCount = _inventory!.getTotalQuantityForColor(color.code);
        }

        return _buildColorStatItem(
          context,
          color,
          count,
          inventoryCount,
          isInsufficient,
          provider,
        );
      },
    );
  }

  Widget _buildColorStatItem(
    BuildContext context,
    BeadColor color,
    int count,
    int? inventoryCount,
    bool isInsufficient,
    DesignEditorProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isInsufficient
            ? Theme.of(
                context,
              ).colorScheme.errorContainer.withValues(alpha: 0.3)
            : null,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isInsufficient
              ? Theme.of(context).colorScheme.error.withValues(alpha: 0.5)
              : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => provider.setSelectedColor(color),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.color,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  color.name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  color.code,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$count 颗',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (inventoryCount != null && _showInventoryComparison)
                Text(
                  '库存: $inventoryCount',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isInsufficient
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          if (isInsufficient) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: '库存不足',
              child: Icon(
                Icons.warning,
                size: 20,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExportButtons(
    BuildContext context,
    DesignEditorProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: provider.hasDesign
                ? () => _exportStatistics(context, provider)
                : null,
            icon: const Icon(Icons.table_chart, size: 18),
            label: const Text('导出统计'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: provider.hasDesign
                ? () => _exportDesign(context, provider)
                : null,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('保存设计'),
          ),
        ],
      ),
    );
  }

  void _showInsufficientColorsDialog(
    BuildContext context,
    List<MapEntry<BeadColor, int>> insufficientColors,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('库存不足的颜色'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: ListView.builder(
            itemCount: insufficientColors.length,
            itemBuilder: (context, index) {
              final entry = insufficientColors[index];
              final color = entry.key;
              final shortage = entry.value;

              return ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.color,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
                title: Text(color.name),
                subtitle: Text('缺少 $shortage 颗'),
                trailing: Text(
                  color.code,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          FilledButton(
            onPressed: () {
              _copyShoppingList(insufficientColors);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('购物清单已复制到剪贴板')));
            },
            child: const Text('复制购物清单'),
          ),
        ],
      ),
    );
  }

  void _copyShoppingList(List<MapEntry<BeadColor, int>> insufficientColors) {
    final buffer = StringBuffer();
    buffer.writeln('拼豆购物清单');
    buffer.writeln('生成时间: ${DateTime.now().toString().split('.')[0]}');
    buffer.writeln('');

    for (final entry in insufficientColors) {
      final color = entry.key;
      final shortage = entry.value;
      buffer.writeln('${color.name} (${color.code}): 缺少 $shortage 颗');
    }

    buffer.writeln('');
    buffer.writeln('总计: ${insufficientColors.length} 种颜色');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
  }

  void _exportStatistics(BuildContext context, DesignEditorProvider provider) {
    final stats = provider.getBeadStatistics();
    final buffer = StringBuffer();

    buffer.writeln('拼豆统计报告');
    buffer.writeln('设计名称: ${provider.currentDesign?.name ?? "未命名"}');
    buffer.writeln('尺寸: ${provider.width} × ${provider.height}');
    buffer.writeln('总拼豆数: ${provider.getTotalBeadCount()}');
    buffer.writeln('颜色数: ${provider.getUniqueColorCount()}');
    buffer.writeln('');

    buffer.writeln('颜色明细:');
    for (final entry in stats.entries) {
      final color = entry.key;
      final count = entry.value;
      buffer.writeln('  ${color.name} (${color.code}): $count 颗');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('统计信息已复制到剪贴板')));
  }

  void _exportDesign(
    BuildContext context,
    DesignEditorProvider provider,
  ) async {
    final success = await provider.saveDesign();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '设计已保存' : '保存失败'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
