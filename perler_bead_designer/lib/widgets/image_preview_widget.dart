import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ImagePreviewWidget extends StatefulWidget {
  final ui.Image? originalImage;
  final ui.Image? previewImage;
  final int outputWidth;
  final int outputHeight;
  final bool isLoading;

  const ImagePreviewWidget({
    super.key,
    this.originalImage,
    this.previewImage,
    required this.outputWidth,
    required this.outputHeight,
    this.isLoading = false,
  });

  @override
  State<ImagePreviewWidget> createState() => _ImagePreviewWidgetState();
}

class _ImagePreviewWidgetState extends State<ImagePreviewWidget> {
  final TransformationController _originalController =
      TransformationController();
  final TransformationController _previewController =
      TransformationController();
  bool _showComparison = true;
  bool _showGrid = false;

  @override
  void dispose() {
    _originalController.dispose();
    _previewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.originalImage == null && widget.previewImage == null) {
      return _buildEmptyState(context);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            if (widget.isLoading)
              _buildLoadingState(context)
            else if (_showComparison)
              _buildComparisonView(context)
            else
              _buildSingleView(context),
            const SizedBox(height: 12),
            _buildInfoRow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.preview),
            const SizedBox(width: 8),
            Text('图片预览', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${widget.outputWidth} × ${widget.outputHeight}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(_showGrid ? Icons.grid_on : Icons.grid_off, size: 20),
              onPressed: () {
                setState(() {
                  _showGrid = !_showGrid;
                });
              },
              tooltip: _showGrid ? '隐藏网格' : '显示网格',
            ),
            IconButton(
              icon: Icon(
                _showComparison ? Icons.compare : Icons.image,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _showComparison = !_showComparison;
                });
              },
              tooltip: _showComparison ? '单独显示' : '对比显示',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              '正在处理图片...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 8),
              Text(
                '暂无图片',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonView(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildImageContainer(
            context,
            widget.originalImage,
            '原图',
            _originalController,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_forward,
            size: 16,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildImageContainer(
            context,
            widget.previewImage,
            '预览',
            _previewController,
            isPreview: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSingleView(BuildContext context) {
    return _buildImageContainer(
      context,
      widget.previewImage ?? widget.originalImage,
      '预览',
      _previewController,
      showLabel: false,
      isPreview: true,
    );
  }

  Widget _buildImageContainer(
    BuildContext context,
    ui.Image? image,
    String label,
    TransformationController controller, {
    bool showLabel = true,
    bool isPreview = false,
  }) {
    return Column(
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isPreview
                        ? Theme.of(context).colorScheme.secondaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isPreview
                          ? Theme.of(context).colorScheme.onSecondaryContainer
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                if (image != null)
                  InteractiveViewer(
                    transformationController: controller,
                    minScale: 0.5,
                    maxScale: 8.0,
                    child: Center(
                      child: CustomPaint(
                        painter: ImagePainter(
                          image,
                          showGrid: _showGrid && isPreview,
                          gridSize: Size(
                            widget.outputWidth.toDouble(),
                            widget.outputHeight.toDouble(),
                          ),
                        ),
                        size: Size(
                          image.width.toDouble(),
                          image.height.toDouble(),
                        ),
                      ),
                    ),
                  )
                else
                  Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                if (isPreview && image != null)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${image.width}×${image.height}',
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            context,
            Icons.grid_on,
            '拼豆数',
            '${widget.outputWidth * widget.outputHeight}',
          ),
          Container(
            width: 1,
            height: 32,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
          _buildInfoItem(
            context,
            Icons.aspect_ratio,
            '输出尺寸',
            '${widget.outputWidth}×${widget.outputHeight}',
          ),
          if (widget.originalImage != null) ...[
            Container(
              width: 1,
              height: 32,
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.3),
            ),
            _buildInfoItem(
              context,
              Icons.photo_size_select_large,
              '原图尺寸',
              '${widget.originalImage!.width}×${widget.originalImage!.height}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class ImagePainter extends CustomPainter {
  final ui.Image image;
  final bool showGrid;
  final Size gridSize;

  ImagePainter(this.image, {this.showGrid = false, this.gridSize = Size.zero});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.low;

    final srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final aspectRatio = image.width / image.height;
    Size destSize;

    if (aspectRatio > 1) {
      destSize = Size(size.width, size.width / aspectRatio);
    } else {
      destSize = Size(size.height * aspectRatio, size.height);
    }

    final destRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: destSize.width,
      height: destSize.height,
    );

    canvas.drawImageRect(image, srcRect, destRect, paint);

    if (showGrid && gridSize.width > 0 && gridSize.height > 0) {
      final gridPaint = Paint()
        ..color = Colors.black26
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke;

      final cellWidth = destRect.width / gridSize.width;
      final cellHeight = destRect.height / gridSize.height;

      for (int i = 0; i <= gridSize.width; i++) {
        final x = destRect.left + i * cellWidth;
        canvas.drawLine(
          Offset(x, destRect.top),
          Offset(x, destRect.bottom),
          gridPaint,
        );
      }

      for (int i = 0; i <= gridSize.height; i++) {
        final y = destRect.top + i * cellHeight;
        canvas.drawLine(
          Offset(destRect.left, y),
          Offset(destRect.right, y),
          gridPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
