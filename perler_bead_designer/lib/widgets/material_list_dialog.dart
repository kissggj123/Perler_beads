import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/bead_design.dart';
import '../models/bead_color.dart';
import '../models/inventory.dart';
import '../services/export_service.dart';

class MaterialListDialog extends StatefulWidget {
  final BeadDesign design;
  final Inventory? inventory;
  final VoidCallback? onExportComplete;

  const MaterialListDialog({
    super.key,
    required this.design,
    this.inventory,
    this.onExportComplete,
  });

  static Future<void> show(
    BuildContext context, {
    required BeadDesign design,
    Inventory? inventory,
    VoidCallback? onExportComplete,
  }) {
    return showDialog(
      context: context,
      builder: (context) => MaterialListDialog(
        design: design,
        inventory: inventory,
        onExportComplete: onExportComplete,
      ),
    );
  }

  @override
  State<MaterialListDialog> createState() => _MaterialListDialogState();
}

class _MaterialListDialogState extends State<MaterialListDialog> {
  late Map<String, dynamic> _materialData;
  bool _isExporting = false;
  MaterialListFormat _exportFormat = MaterialListFormat.csv;

  @override
  void initState() {
    super.initState();
    _materialData = ExportService.getMaterialListData(
      widget.design,
      inventory: widget.inventory,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.list_alt),
          const SizedBox(width: 8),
          const Text('材料清单'),
          const Spacer(),
          Text(
            widget.design.name,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 500,
        child: _isExporting
            ? const Center(child: CircularProgressIndicator())
            : _buildMaterialList(),
      ),
      actions: _isExporting
          ? []
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
              PopupMenuButton<MaterialListFormat>(
                icon: const Icon(Icons.download),
                tooltip: '导出',
                initialValue: _exportFormat,
                onSelected: (format) => _handleExport(format),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: MaterialListFormat.csv,
                    child: ListTile(
                      leading: Icon(Icons.table_chart),
                      title: Text('导出为 CSV'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: MaterialListFormat.pdf,
                    child: ListTile(
                      leading: Icon(Icons.picture_as_pdf),
                      title: Text('导出为 PDF'),
                    ),
                  ),
                ],
              ),
            ],
    );
  }

  Widget _buildMaterialList() {
    final items = _materialData['items'] as List<Map<String, dynamic>>;

    return Column(
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 16),
        Expanded(
          child: Card(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildMaterialItem(item, index + 1);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              Icons.grid_on,
              _materialData['designSize'],
              '尺寸',
            ),
            _buildSummaryItem(
              Icons.circle,
              '${_materialData['totalBeads']}',
              '总拼豆数',
            ),
            _buildSummaryItem(
              Icons.palette,
              '${_materialData['colorCount']}',
              '颜色种类',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialItem(Map<String, dynamic> item, int index) {
    final color = item['color'] as BeadColor;
    final count = item['count'] as int;
    final percentage = item['percentage'] as String;
    final stockQuantity = item['stockQuantity'] as int?;
    final hasStock = item['hasStock'] as bool;
    final sufficient = item['sufficient'] as bool;

    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '$index',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.color,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
      title: Text(
        color.name,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${color.code} · ${color.hexCode}',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: _buildTrailing(count, percentage, stockQuantity, hasStock, sufficient),
    );
  }

  Widget _buildTrailing(
    int count,
    String percentage,
    int? stockQuantity,
    bool hasStock,
    bool sufficient,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '($percentage%)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        if (hasStock) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                sufficient ? Icons.check_circle : Icons.warning,
                size: 14,
                color: sufficient ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                '库存: $stockQuantity',
                style: TextStyle(
                  fontSize: 11,
                  color: sufficient ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ] else if (widget.inventory != null) ...[
          const SizedBox(height: 2),
          Text(
            '无库存记录',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _handleExport(MaterialListFormat format) async {
    setState(() {
      _isExporting = true;
      _exportFormat = format;
    });

    try {
      final extension = format == MaterialListFormat.pdf ? 'pdf' : 'csv';
      String? filePath;

      if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
        filePath = await FilePicker.platform.saveFile(
          dialogTitle: '保存材料清单',
          fileName: '${widget.design.name}_材料清单.$extension',
          allowedExtensions: [extension],
        );
      }

      if (filePath == null) {
        setState(() {
          _isExporting = false;
        });
        return;
      }

      final result = await ExportService.exportMaterialList(
        widget.design,
        format: format,
        customPath: filePath,
      );

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('导出成功: ${result.filePath}'),
              action: SnackBarAction(
                label: '打开',
                onPressed: () {
                  if (result.filePath != null) {
                    Process.run('open', [result.filePath!]);
                  }
                },
              ),
            ),
          );
          widget.onExportComplete?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? '导出失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
}

class MaterialListSummaryCard extends StatelessWidget {
  final BeadDesign design;
  final Inventory? inventory;

  const MaterialListSummaryCard({
    super.key,
    required this.design,
    this.inventory,
  });

  @override
  Widget build(BuildContext context) {
    final materialData = ExportService.getMaterialListData(
      design,
      inventory: inventory,
    );

    final items = materialData['items'] as List<Map<String, dynamic>>;
    int sufficientCount = 0;
    int insufficientCount = 0;
    int noStockCount = 0;

    for (final item in items) {
      final hasStock = item['hasStock'] as bool;
      final sufficient = item['sufficient'] as bool;

      if (!hasStock) {
        noStockCount++;
      } else if (sufficient) {
        sufficientCount++;
      } else {
        insufficientCount++;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_2, size: 20),
                const SizedBox(width: 8),
                Text(
                  '材料需求摘要',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '总需求',
                    '${materialData['totalBeads']}',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '颜色数',
                    '${materialData['colorCount']}',
                    Colors.purple,
                  ),
                ),
                if (inventory != null) ...[
                  Expanded(
                    child: _buildStatItem(
                      '库存充足',
                      '$sufficientCount',
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      '库存不足',
                      '$insufficientCount',
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      '无记录',
                      '$noStockCount',
                      Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
