import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/inventory_provider.dart';
import '../services/smart_import_service.dart';
import 'column_mapping_dialog.dart';

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
  SmartImportResult? _importResult;
  List<ColumnMapping>? _currentMappings;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导入库存'),
      content: SizedBox(
        width: 650,
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
            if (_importResult != null && _importResult!.needsManualMapping) ...[
              const SizedBox(height: 12),
              _buildManualMappingHint(context),
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
        if (_importResult != null && _importResult!.needsManualMapping)
          FilledButton.icon(
            onPressed: _showColumnMappingDialog,
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('设置列映射'),
          ),
        if (_previewItems.isNotEmpty && !_isLoading)
          FilledButton(onPressed: _importItems, child: const Text('导入')),
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
              value: ImportFormat.xlsx,
              label: Text('XLSX'),
              icon: Icon(Icons.grid_on),
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
              _importResult = null;
              _currentMappings = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildFileSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: _isLoading ? null : _pickFile,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.5),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
              _getFormatHint(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFormatHint() {
    switch (_selectedFormat) {
      case ImportFormat.csv:
        return '支持 .csv 格式，自动识别分隔符和编码';
      case ImportFormat.xlsx:
        return '支持 .xlsx / .xls 格式';
      case ImportFormat.json:
        return '支持 .json 格式';
    }
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

  Widget _buildManualMappingHint(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.tertiary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '无法自动识别所有列，请点击"设置列映射"手动选择',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onTertiaryContainer,
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
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
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
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
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
      _importResult = null;
      _previewItems = [];
    });

    try {
      final extensions = _getAllowedExtensions();
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: '选择库存文件',
        type: FileType.custom,
        allowedExtensions: extensions,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();

        setState(() {
          _fileName = result.files.single.name;
          _fileContent = content;
        });

        _parseContent(content, result.files.single.name);
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

  List<String> _getAllowedExtensions() {
    switch (_selectedFormat) {
      case ImportFormat.csv:
        return ['csv'];
      case ImportFormat.xlsx:
        return ['xlsx', 'xls'];
      case ImportFormat.json:
        return ['json'];
    }
  }

  void _parseContent(String content, String fileName) {
    final importService = SmartImportService.instance;
    final result = importService.parseFile(content, fileName);

    setState(() {
      _importResult = result;
      _currentMappings = result.detectedColumns;

      if (result.success) {
        _previewItems = result.items;
        if (result.items.isEmpty) {
          _error = '未找到有效的库存数据';
        }
      } else if (result.needsManualMapping) {
        _error = result.error;
        _previewItems = [];
      } else {
        _error = result.error;
        _previewItems = [];
      }
    });
  }

  Future<void> _showColumnMappingDialog() async {
    if (_importResult == null) return;

    final hasHeader = _importResult!.headers.isNotEmpty;
    final headers = hasHeader
        ? _importResult!.headers
        : List.generate(
            _importResult!.rawData.isNotEmpty
                ? _importResult!.rawData.first.length
                : 0,
            (i) => '列${i + 1}',
          );

    final defaultMappings = List.generate(
      headers.length,
      (i) => ColumnMapping(
        index: i,
        type: ColumnType.unknown,
        headerName: headers[i],
      ),
    );

    final result = await showDialog<List<ColumnMapping>>(
      context: context,
      builder: (context) => ColumnMappingDialog(
        headers: headers,
        initialMappings: _currentMappings ?? defaultMappings,
        sampleData: _importResult!.rawData,
      ),
    );

    if (result != null) {
      _applyMappings(result);
    }
  }

  void _applyMappings(List<ColumnMapping> mappings) {
    if (_importResult == null) return;

    final importService = SmartImportService.instance;
    final hasHeader = _importResult!.headers.isNotEmpty;
    final dataRows = hasHeader
        ? _importResult!.rawData.sublist(1)
        : _importResult!.rawData;

    final result = importService.parseWithMapping(dataRows, mappings);

    setState(() {
      _currentMappings = mappings;
      if (result.success) {
        _previewItems = result.items;
        _error = null;
        _importResult = SmartImportResult(
          success: true,
          items: result.items,
          detectedColumns: mappings,
          headers: _importResult!.headers,
          rawData: _importResult!.rawData,
        );
      } else {
        _error = result.error;
        _previewItems = [];
      }
    });
  }

  Future<void> _importItems() async {
    setState(() => _isLoading = true);

    try {
      final inventoryProvider = context.read<InventoryProvider>();
      int count = 0;

      for (final item in _previewItems) {
        final existing = inventoryProvider.findByColorCode(item.beadColor.code);
        if (existing != null) {
          await inventoryProvider.updateQuantity(
            item.beadColor.code,
            existing.quantity + item.quantity,
          );
        } else {
          await inventoryProvider.addItem(item.beadColor, item.quantity);
        }
        count++;
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('成功导入 $count 项库存')));
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

enum ImportFormat { csv, xlsx, json }
