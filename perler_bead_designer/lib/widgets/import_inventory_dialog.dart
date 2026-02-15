import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/inventory_provider.dart';

class ImportInventoryDialog extends StatefulWidget {
  const ImportInventoryDialog({super.key});

  @override
  State<ImportInventoryDialog> createState() => _ImportInventoryDialogState();
}

class _ImportInventoryDialogState extends State<ImportInventoryDialog> {
  ImportFormat _selectedFormat = ImportFormat.csv;
  String? _fileContent;
  String? _fileName;
  List<InventoryItem> _previewItems = [];
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('导入库存'),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormatSelector(context),
            const SizedBox(height: 16),
            _buildFileSelector(context),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _buildErrorDisplay(context),
            ],
            if (_fileContent != null && _previewItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildPreviewHeader(context),
              const SizedBox(height: 8),
              _buildPreviewList(context),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _previewItems.isNotEmpty && !_isLoading
              ? _importItems
              : null,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('导入'),
        ),
      ],
    );
  }

  Widget _buildFormatSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('选择文件格式', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SegmentedButton<ImportFormat>(
          segments: const [
            ButtonSegment(
              value: ImportFormat.csv,
              label: Text('CSV'),
              icon: Icon(Icons.table_chart),
            ),
            ButtonSegment(
              value: ImportFormat.json,
              label: Text('JSON'),
              icon: Icon(Icons.code),
            ),
          ],
          selected: {_selectedFormat},
          onSelectionChanged: (selection) {
            setState(() {
              _selectedFormat = selection.first;
              _fileContent = null;
              _fileName = null;
              _previewItems = [];
              _error = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildFileSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: _pickFile,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.5),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        ),
        child: Column(
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 48,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              _fileName ?? '点击选择文件',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              _selectedFormat == ImportFormat.csv
                  ? '支持 .csv 格式'
                  : '支持 .json 格式',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorDisplay(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('导入预览', style: Theme.of(context).textTheme.titleSmall),
        Text(
          '共 ${_previewItems.length} 项',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewList(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        itemCount: _previewItems.length > 20 ? 20 : _previewItems.length,
        itemBuilder: (context, index) {
          final item = _previewItems[index];
          return ListTile(
            dense: true,
            leading: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: item.beadColor.color,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
            ),
            title: Text(item.beadColor.name),
            subtitle: Text('${item.beadColor.code} · 数量: ${item.quantity}'),
          );
        },
      ),
    );
  }

  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: '选择库存文件',
        type: FileType.custom,
        allowedExtensions: [
          _selectedFormat == ImportFormat.csv ? 'csv' : 'json',
        ],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();

        setState(() {
          _fileName = result.files.single.name;
          _fileContent = content;
        });

        _parseContent(content);
      }
    } catch (e) {
      setState(() {
        _error = '读取文件失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _parseContent(String content) {
    try {
      if (_selectedFormat == ImportFormat.csv) {
        _parseCsv(content);
      } else {
        _parseJson(content);
      }
    } catch (e) {
      setState(() {
        _error = '解析文件失败: $e';
        _previewItems = [];
      });
    }
  }

  void _parseCsv(String content) {
    final rows = const CsvToListConverter().convert(content);
    if (rows.isEmpty) {
      setState(() {
        _error = 'CSV文件为空';
        _previewItems = [];
      });
      return;
    }

    final items = <InventoryItem>[];
    bool isFirstRow = true;

    for (final row in rows) {
      if (isFirstRow) {
        isFirstRow = false;
        continue;
      }

      if (row.length >= 5) {
        final color = BeadColor(
          code: row[1].toString(),
          name: row[2].toString(),
          red: row.length > 5 ? (int.tryParse(row[5].toString()) ?? 128) : 128,
          green: row.length > 6
              ? (int.tryParse(row[6].toString()) ?? 128)
              : 128,
          blue: row.length > 7 ? (int.tryParse(row[7].toString()) ?? 128) : 128,
          brand: BeadBrand.values.firstWhere(
            (b) => b.name == row[3].toString(),
            orElse: () => BeadBrand.generic,
          ),
          category: row.length > 8 ? row[8].toString() : null,
        );
        final quantity = int.tryParse(row[4].toString()) ?? 0;
        items.add(
          InventoryItem(
            id: 'import_${DateTime.now().millisecondsSinceEpoch}_${items.length}',
            beadColor: color,
            quantity: quantity,
            lastUpdated: DateTime.now(),
          ),
        );
      }
    }

    setState(() {
      _previewItems = items;
      if (items.isEmpty) {
        _error = '未找到有效的库存数据';
      }
    });
  }

  void _parseJson(String content) {
    final data = jsonDecode(content) as Map<String, dynamic>;
    final inventory = Inventory.fromJson(data);

    setState(() {
      _previewItems = inventory.items;
      if (inventory.items.isEmpty) {
        _error = '未找到有效的库存数据';
      }
    });
  }

  Future<void> _importItems() async {
    setState(() => _isLoading = true);

    try {
      final inventoryProvider = context.read<InventoryProvider>();
      ImportResult result;

      if (_selectedFormat == ImportFormat.csv) {
        result = await inventoryProvider.importFromCsv(_fileContent!);
      } else {
        result = await inventoryProvider.importFromJson(_fileContent!);
      }

      if (mounted) {
        if (result.success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('成功导入 ${result.importedCount} 项库存')),
          );
        } else {
          setState(() {
            _error = result.message;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = '导入失败: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

enum ImportFormat { csv, json }
