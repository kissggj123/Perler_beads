import 'package:flutter/material.dart';

import '../services/smart_import_service.dart';

class ColumnMappingDialog extends StatefulWidget {
  final List<String> headers;
  final List<ColumnMapping> initialMappings;
  final List<List<dynamic>> sampleData;

  const ColumnMappingDialog({
    super.key,
    required this.headers,
    required this.initialMappings,
    required this.sampleData,
  });

  @override
  State<ColumnMappingDialog> createState() => _ColumnMappingDialogState();
}

class _ColumnMappingDialogState extends State<ColumnMappingDialog> {
  late List<ColumnMapping> _mappings;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _mappings = List.from(widget.initialMappings);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('设置列映射'),
      content: SizedBox(
        width: 600,
        height: 450,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInstructions(context),
            const SizedBox(height: 16),
            Expanded(child: _buildMappingList(context)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _hasRequiredMappings() ? _confirmMappings : null,
          child: const Text('确认'),
        ),
      ],
    );
  }

  Widget _buildInstructions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '请为每列选择对应的数据类型。至少需要选择"颜色代码"和"数量"列。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMappingList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _mappings.length,
              itemBuilder: (context, index) {
                return _buildMappingRow(context, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 40,
            child: Text('#', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Expanded(
            flex: 2,
            child: Text('列名', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Expanded(
            flex: 2,
            child: Text('数据类型', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Expanded(
            flex: 3,
            child: Text('示例数据', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMappingRow(BuildContext context, int index) {
    final sampleValues = _getSampleValues(index);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '${index + 1}',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              widget.headers[index],
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(flex: 2, child: _buildTypeDropdown(context, index)),
          Expanded(
            flex: 3,
            child: Text(
              sampleValues,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeDropdown(BuildContext context, int index) {
    final availableTypes = ColumnType.values
        .where((t) => t != ColumnType.unknown)
        .toList();
    final currentType = _mappings[index].type;

    return DropdownButtonFormField<ColumnType>(
      initialValue: currentType == ColumnType.unknown ? null : currentType,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
      hint: const Text('选择类型'),
      items: [
        const DropdownMenuItem(value: null, child: Text('忽略此列')),
        ...availableTypes.map((type) {
          return DropdownMenuItem(
            value: type,
            child: Text(_getTypeDisplayName(type)),
          );
        }),
      ],
      onChanged: (newType) {
        setState(() {
          _mappings[index] = ColumnMapping(
            index: index,
            type: newType ?? ColumnType.unknown,
            headerName: widget.headers[index],
          );
        });
      },
    );
  }

  String _getSampleValues(int columnIndex) {
    final values = widget.sampleData
        .skip(1)
        .take(3)
        .where((row) => columnIndex < row.length)
        .map((row) => row[columnIndex]?.toString() ?? '')
        .where((v) => v.isNotEmpty)
        .take(3)
        .toList();

    if (values.isEmpty) return '(空)';

    return values.join(', ');
  }

  String _getTypeDisplayName(ColumnType type) {
    switch (type) {
      case ColumnType.code:
        return '颜色代码';
      case ColumnType.name:
        return '颜色名称';
      case ColumnType.quantity:
        return '数量';
      case ColumnType.red:
        return '红色值';
      case ColumnType.green:
        return '绿色值';
      case ColumnType.blue:
        return '蓝色值';
      case ColumnType.hexColor:
        return '十六进制颜色';
      case ColumnType.brand:
        return '品牌';
      case ColumnType.category:
        return '分类';
      case ColumnType.id:
        return 'ID';
      case ColumnType.lastUpdated:
        return '更新时间';
      case ColumnType.unknown:
        return '未知';
    }
  }

  bool _hasRequiredMappings() {
    final hasCode = _mappings.any((m) => m.type == ColumnType.code);
    final hasQuantity = _mappings.any((m) => m.type == ColumnType.quantity);

    return hasCode && hasQuantity;
  }

  void _confirmMappings() {
    Navigator.of(context).pop(_mappings);
  }
}
