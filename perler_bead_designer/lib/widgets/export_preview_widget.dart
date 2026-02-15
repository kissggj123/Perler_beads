import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/bead_design.dart';
import '../services/export_service.dart';

class ExportPreviewWidget extends StatefulWidget {
  final BeadDesign design;
  final int scale;
  final bool showGrid;
  final Color backgroundColor;

  const ExportPreviewWidget({
    super.key,
    required this.design,
    this.scale = 5,
    this.showGrid = true,
    this.backgroundColor = Colors.white,
  });

  @override
  State<ExportPreviewWidget> createState() => _ExportPreviewWidgetState();
}

class _ExportPreviewWidgetState extends State<ExportPreviewWidget> {
  Uint8List? _previewImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _generatePreview();
  }

  @override
  void didUpdateWidget(ExportPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scale != widget.scale ||
        oldWidget.showGrid != widget.showGrid ||
        oldWidget.backgroundColor != widget.backgroundColor ||
        oldWidget.design != widget.design) {
      _generatePreview();
    }
  }

  Future<void> _generatePreview() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final image = await ExportService.generatePreviewImage(
        widget.design,
        scale: widget.scale,
        showGrid: widget.showGrid,
        backgroundColor: widget.backgroundColor,
      );

      if (mounted) {
        setState(() {
          _previewImage = image;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_previewImage == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              '无法生成预览',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return InteractiveViewer(
      minScale: 0.1,
      maxScale: 5.0,
      child: Center(
        child: Image.memory(
          _previewImage!,
          fit: BoxFit.contain,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}

class ExportPreviewDialog extends StatelessWidget {
  final BeadDesign design;
  final int scale;
  final bool showGrid;
  final Color backgroundColor;

  const ExportPreviewDialog({
    super.key,
    required this.design,
    this.scale = 5,
    this.showGrid = true,
    this.backgroundColor = Colors.white,
  });

  static Future<void> show(
    BuildContext context, {
    required BeadDesign design,
    int scale = 5,
    bool showGrid = true,
    Color backgroundColor = Colors.white,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ExportPreviewDialog(
        design: design,
        scale: scale,
        showGrid: showGrid,
        backgroundColor: backgroundColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          children: [
            AppBar(
              title: const Text('导出预览'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: ExportPreviewWidget(
                design: design,
                scale: scale,
                showGrid: showGrid,
                backgroundColor: backgroundColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoChip(
                    Icons.grid_on,
                    '${design.width} × ${design.height}',
                    '尺寸',
                  ),
                  _buildInfoChip(
                    Icons.circle,
                    '${design.getTotalBeadCount()}',
                    '拼豆数',
                  ),
                  _buildInfoChip(
                    Icons.palette,
                    '${design.getUniqueColorCount()}',
                    '颜色数',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
