import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/bead_design.dart';
import '../models/inventory.dart';
import '../services/export_service.dart';
import '../utils/pdf_generator.dart';
import 'export_preview_widget.dart';

enum ExportCategory {
  design,
  materialList,
}

enum DesignExportFormat {
  png,
  pdf,
}

enum MaterialExportFormat {
  csv,
  pdf,
}

class ExportDialog extends StatefulWidget {
  final BeadDesign design;
  final Inventory? inventory;
  final VoidCallback? onExportComplete;

  const ExportDialog({
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
      builder: (context) => ExportDialog(
        design: design,
        inventory: inventory,
        onExportComplete: onExportComplete,
      ),
    );
  }

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  ExportCategory _exportCategory = ExportCategory.design;
  DesignExportFormat _designFormat = DesignExportFormat.png;
  MaterialExportFormat _materialFormat = MaterialExportFormat.csv;

  int _scale = 10;
  bool _showGrid = true;
  bool _showCoordinates = true;
  Color _backgroundColor = Colors.white;
  PdfPageSize _pageSize = PdfPageSize.a4;
  PdfOrientation _orientation = PdfOrientation.portrait;

  bool _isExporting = false;
  double _exportProgress = 0.0;

  final List<int> _scaleOptions = [5, 10, 15, 20, 25, 30, 40, 50];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('导出'),
      content: SizedBox(
        width: 550,
        child: _isExporting
            ? _buildProgressIndicator()
            : _buildExportOptions(),
      ),
      actions: _isExporting
          ? []
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              ElevatedButton.icon(
                onPressed: _handleExport,
                icon: const Icon(Icons.download),
                label: const Text('导出'),
              ),
            ],
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          '正在导出...',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: _exportProgress),
        const SizedBox(height: 8),
        Text(
          '${(_exportProgress * 100).toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildExportOptions() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCategorySelector(),
          const Divider(),
          if (_exportCategory == ExportCategory.design) ...[
            _buildDesignFormatSelector(),
            const SizedBox(height: 12),
            if (_designFormat == DesignExportFormat.png)
              _buildPngOptions()
            else
              _buildPdfOptions(),
            const Divider(),
            _buildPreviewSection(),
          ] else ...[
            _buildMaterialFormatSelector(),
            const SizedBox(height: 12),
            _buildMaterialOptions(),
            const Divider(),
            _buildMaterialPreview(),
          ],
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '导出类型',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SegmentedButton<ExportCategory>(
          segments: const [
            ButtonSegment(
              value: ExportCategory.design,
              label: Text('设计图'),
              icon: Icon(Icons.grid_on),
            ),
            ButtonSegment(
              value: ExportCategory.materialList,
              label: Text('材料清单'),
              icon: Icon(Icons.list_alt),
            ),
          ],
          selected: {_exportCategory},
          onSelectionChanged: (Set<ExportCategory> selection) {
            setState(() {
              _exportCategory = selection.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDesignFormatSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '导出格式',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SegmentedButton<DesignExportFormat>(
          segments: const [
            ButtonSegment(
              value: DesignExportFormat.png,
              label: Text('PNG 图片'),
              icon: Icon(Icons.image),
            ),
            ButtonSegment(
              value: DesignExportFormat.pdf,
              label: Text('PDF 文档'),
              icon: Icon(Icons.picture_as_pdf),
            ),
          ],
          selected: {_designFormat},
          onSelectionChanged: (Set<DesignExportFormat> selection) {
            setState(() {
              _designFormat = selection.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildMaterialFormatSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '导出格式',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SegmentedButton<MaterialExportFormat>(
          segments: const [
            ButtonSegment(
              value: MaterialExportFormat.csv,
              label: Text('CSV 表格'),
              icon: Icon(Icons.table_chart),
            ),
            ButtonSegment(
              value: MaterialExportFormat.pdf,
              label: Text('PDF 文档'),
              icon: Icon(Icons.picture_as_pdf),
            ),
          ],
          selected: {_materialFormat},
          onSelectionChanged: (Set<MaterialExportFormat> selection) {
            setState(() {
              _materialFormat = selection.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPngOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PNG 选项',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('缩放比例: '),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _scale,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                items: _scaleOptions.map((scale) {
                  return DropdownMenuItem(
                    value: scale,
                    child: Text('${scale}x (${widget.design.width * scale} × ${widget.design.height * scale} 像素)'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _scale = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('显示网格'),
          subtitle: const Text('在拼豆之间显示网格线'),
          value: _showGrid,
          onChanged: (value) {
            setState(() {
              _showGrid = value;
            });
          },
        ),
        const SizedBox(height: 8),
        ListTile(
          title: const Text('背景颜色'),
          trailing: _buildColorPicker(),
        ),
      ],
    );
  }

  Widget _buildPdfOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PDF 选项',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<PdfPageSize>(
                initialValue: _pageSize,
                decoration: const InputDecoration(
                  labelText: '页面大小',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: PdfPageSize.a4, child: Text('A4')),
                  DropdownMenuItem(value: PdfPageSize.a3, child: Text('A3')),
                  DropdownMenuItem(value: PdfPageSize.letter, child: Text('Letter')),
                  DropdownMenuItem(value: PdfPageSize.legal, child: Text('Legal')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _pageSize = value;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<PdfOrientation>(
                initialValue: _orientation,
                decoration: const InputDecoration(
                  labelText: '页面方向',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: PdfOrientation.portrait, child: Text('纵向')),
                  DropdownMenuItem(value: PdfOrientation.landscape, child: Text('横向')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _orientation = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('显示网格'),
          subtitle: const Text('在拼豆之间显示网格线'),
          value: _showGrid,
          onChanged: (value) {
            setState(() {
              _showGrid = value;
            });
          },
        ),
        SwitchListTile(
          title: const Text('显示坐标'),
          subtitle: const Text('显示行列坐标编号'),
          value: _showCoordinates,
          onChanged: (value) {
            setState(() {
              _showCoordinates = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildMaterialOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PDF 选项',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<PdfPageSize>(
                initialValue: _pageSize,
                decoration: const InputDecoration(
                  labelText: '页面大小',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: PdfPageSize.a4, child: Text('A4')),
                  DropdownMenuItem(value: PdfPageSize.a3, child: Text('A3')),
                  DropdownMenuItem(value: PdfPageSize.letter, child: Text('Letter')),
                  DropdownMenuItem(value: PdfPageSize.legal, child: Text('Legal')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _pageSize = value;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<PdfOrientation>(
                initialValue: _orientation,
                decoration: const InputDecoration(
                  labelText: '页面方向',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: PdfOrientation.portrait, child: Text('纵向')),
                  DropdownMenuItem(value: PdfOrientation.landscape, child: Text('横向')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _orientation = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    return GestureDetector(
      onTap: _pickBackgroundColor,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _backgroundColor,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Future<void> _pickBackgroundColor() async {
    final color = await showDialog<Color>(
      context: context,
      builder: (context) => _ColorPickerDialog(initialColor: _backgroundColor),
    );

    if (color != null) {
      setState(() {
        _backgroundColor = color;
      });
    }
  }

  Widget _buildPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '预览',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Center(
            child: ExportPreviewWidget(
              design: widget.design,
              scale: 3,
              showGrid: _showGrid,
              backgroundColor: _backgroundColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialPreview() {
    final materialData = ExportService.getMaterialListData(
      widget.design,
      inventory: widget.inventory,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '材料清单预览',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPreviewItem(
                    Icons.grid_on,
                    materialData['designSize'],
                    '尺寸',
                  ),
                  _buildPreviewItem(
                    Icons.circle,
                    '${materialData['totalBeads']}',
                    '总拼豆数',
                  ),
                  _buildPreviewItem(
                    Icons.palette,
                    '${materialData['colorCount']}',
                    '颜色种类',
                  ),
                ],
              ),
              if (widget.inventory != null) ...[
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPreviewItem(
                      Icons.check_circle,
                      '${_getSufficientCount(materialData)}',
                      '库存充足',
                      color: Colors.green,
                    ),
                    _buildPreviewItem(
                      Icons.warning,
                      '${_getInsufficientCount(materialData)}',
                      '库存不足',
                      color: Colors.orange,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewItem(IconData icon, String value, String label, {Color? color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
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

  int _getSufficientCount(Map<String, dynamic> materialData) {
    final items = materialData['items'] as List<Map<String, dynamic>>;
    return items.where((item) => item['sufficient'] as bool).length;
  }

  int _getInsufficientCount(Map<String, dynamic> materialData) {
    final items = materialData['items'] as List<Map<String, dynamic>>;
    return items.where((item) {
      final hasStock = item['hasStock'] as bool;
      final sufficient = item['sufficient'] as bool;
      return hasStock && !sufficient;
    }).length;
  }

  Future<void> _handleExport() async {
    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
    });

    try {
      ExportResult result;

      if (_exportCategory == ExportCategory.design) {
        result = await _handleDesignExport();
      } else {
        result = await _handleMaterialExport();
      }

      setState(() => _exportProgress = 1.0);

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
          Navigator.of(context).pop();
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

  Future<ExportResult> _handleDesignExport() async {
    final extension = _designFormat == DesignExportFormat.png ? 'png' : 'pdf';
    final filePath = await _getSavePath(extension, widget.design.name);
    if (filePath == null) {
      return ExportResult.failure('未选择保存位置');
    }

    setState(() => _exportProgress = 0.3);

    if (_designFormat == DesignExportFormat.png) {
      return await ExportService.exportToPng(
        widget.design,
        scale: _scale,
        showGrid: _showGrid,
        backgroundColor: _backgroundColor,
        customPath: filePath,
      );
    } else {
      return await ExportService.exportToPdf(
        widget.design,
        pageSize: _pageSize,
        orientation: _orientation,
        showGrid: _showGrid,
        showCoordinates: _showCoordinates,
        customPath: filePath,
      );
    }
  }

  Future<ExportResult> _handleMaterialExport() async {
    final extension = _materialFormat == MaterialExportFormat.pdf ? 'pdf' : 'csv';
    final filePath = await _getSavePath(extension, '${widget.design.name}_材料清单');
    if (filePath == null) {
      return ExportResult.failure('未选择保存位置');
    }

    setState(() => _exportProgress = 0.3);

    final format = _materialFormat == MaterialExportFormat.pdf
        ? MaterialListFormat.pdf
        : MaterialListFormat.csv;

    return await ExportService.exportMaterialList(
      widget.design,
      format: format,
      pageSize: _pageSize,
      orientation: _orientation,
      customPath: filePath,
    );
  }

  Future<String?> _getSavePath(String extension, String fileName) async {
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      return await FilePicker.platform.saveFile(
        dialogTitle: '保存文件',
        fileName: '$fileName.$extension',
        type: FileType.custom,
        allowedExtensions: [extension],
      );
    }
    return null;
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor;

  const _ColorPickerDialog({required this.initialColor});

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _selectedColor;

  final List<Color> _presetColors = [
    Colors.white,
    Colors.black,
    Colors.grey,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择背景颜色'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: _selectedColor,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetColors.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                        width: isSelected ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedColor),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
