import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/bead_color.dart';
import '../models/color_palette.dart';

class GridCellInfo {
  final int x;
  final int y;
  final Color color;
  final BeadColor? beadColor;

  GridCellInfo({
    required this.x,
    required this.y,
    required this.color,
    this.beadColor,
  });

  String get rgbString =>
      'RGB(${(color.r * 255.0).round()}, ${(color.g * 255.0).round()}, ${(color.b * 255.0).round()})';
  String get hexString =>
      '#${(color.r * 255.0).round().toRadixString(16).padLeft(2, '0')}${(color.g * 255.0).round().toRadixString(16).padLeft(2, '0')}${(color.b * 255.0).round().toRadixString(16).padLeft(2, '0')}'
          .toUpperCase();
}

typedef CellColorProvider = Color? Function(int x, int y);

class ImagePreviewWidget extends StatefulWidget {
  final ui.Image? originalImage;
  final ui.Image? previewImage;
  final int outputWidth;
  final int outputHeight;
  final bool isLoading;
  final ColorPalette? colorPalette;
  final void Function(GridCellInfo)? onCellTap;
  final CellColorProvider? cellColorProvider;

  const ImagePreviewWidget({
    super.key,
    this.originalImage,
    this.previewImage,
    required this.outputWidth,
    required this.outputHeight,
    this.isLoading = false,
    this.colorPalette,
    this.onCellTap,
    this.cellColorProvider,
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

  Offset? _hoveredCell;
  GridCellInfo? _hoveredCellInfo;

  @override
  void dispose() {
    _originalController.dispose();
    _previewController.dispose();
    super.dispose();
  }

  GridCellInfo? _getCellInfoFromPosition(
    Offset localPosition,
    Size imageSize,
    Rect destRect,
  ) {
    if (widget.cellColorProvider == null || widget.colorPalette == null) {
      return null;
    }

    final cellWidth = destRect.width / widget.outputWidth;
    final cellHeight = destRect.height / widget.outputHeight;

    final relX = localPosition.dx - destRect.left;
    final relY = localPosition.dy - destRect.top;

    if (relX < 0 ||
        relX > destRect.width ||
        relY < 0 ||
        relY > destRect.height) {
      return null;
    }

    final gridX = (relX / cellWidth).floor().clamp(0, widget.outputWidth - 1);
    final gridY = (relY / cellHeight).floor().clamp(0, widget.outputHeight - 1);

    final color = widget.cellColorProvider!(gridX, gridY);
    if (color == null) return null;

    final beadColor = widget.colorPalette!.findClosestColorToRgb(
      (color.r * 255.0).round(),
      (color.g * 255.0).round(),
      (color.b * 255.0).round(),
    );

    return GridCellInfo(x: gridX, y: gridY, color: color, beadColor: beadColor);
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
                  MouseRegion(
                    cursor: isPreview && widget.cellColorProvider != null
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
                    onHover: isPreview
                        ? (event) => _handleHover(event, image)
                        : null,
                    onExit: isPreview ? (_) => _handleHoverExit() : null,
                    child: GestureDetector(
                      onTapUp: isPreview
                          ? (details) => _handleTap(details, image)
                          : null,
                      child: InteractiveViewer(
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
                              hoveredCell: isPreview ? _hoveredCell : null,
                              hoveredCellInfo: isPreview
                                  ? _hoveredCellInfo
                                  : null,
                            ),
                            size: Size(
                              image.width.toDouble(),
                              image.height.toDouble(),
                            ),
                          ),
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
                if (isPreview && _hoveredCellInfo != null)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: _buildHoverTooltip(context),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleHover(PointerHoverEvent event, ui.Image image) {
    final localPosition = event.localPosition;

    final aspectRatio = image.width / image.height;
    Size destSize;
    if (aspectRatio > 1) {
      destSize = Size(
        image.width.toDouble(),
        image.width.toDouble() / aspectRatio,
      );
    } else {
      destSize = Size(
        image.height.toDouble() * aspectRatio,
        image.height.toDouble(),
      );
    }

    final destRect = Rect.fromCenter(
      center: Offset(image.width.toDouble() / 2, image.height.toDouble() / 2),
      width: destSize.width,
      height: destSize.height,
    );

    final cellInfo = _getCellInfoFromPosition(
      localPosition,
      Size(image.width.toDouble(), image.height.toDouble()),
      destRect,
    );

    if (cellInfo != null) {
      setState(() {
        _hoveredCell = Offset(cellInfo.x.toDouble(), cellInfo.y.toDouble());
        _hoveredCellInfo = cellInfo;
      });
    }
  }

  void _handleHoverExit() {
    setState(() {
      _hoveredCell = null;
      _hoveredCellInfo = null;
    });
  }

  void _handleTap(TapUpDetails details, ui.Image image) {
    final localPosition = details.localPosition;

    final aspectRatio = image.width / image.height;
    Size destSize;
    if (aspectRatio > 1) {
      destSize = Size(
        image.width.toDouble(),
        image.width.toDouble() / aspectRatio,
      );
    } else {
      destSize = Size(
        image.height.toDouble() * aspectRatio,
        image.height.toDouble(),
      );
    }

    final destRect = Rect.fromCenter(
      center: Offset(image.width.toDouble() / 2, image.height.toDouble() / 2),
      width: destSize.width,
      height: destSize.height,
    );

    final cellInfo = _getCellInfoFromPosition(
      localPosition,
      Size(image.width.toDouble(), image.height.toDouble()),
      destRect,
    );

    if (cellInfo != null && widget.onCellTap != null) {
      widget.onCellTap!(cellInfo);
    }
  }

  Widget _buildHoverTooltip(BuildContext context) {
    if (_hoveredCellInfo == null) return const SizedBox.shrink();

    final info = _hoveredCellInfo!;
    final beadColor = info.beadColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '位置: (${info.x}, ${info.y})',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
          if (beadColor != null) ...[
            const SizedBox(height: 2),
            Text(
              '${beadColor.code} - ${beadColor.name}',
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ],
      ),
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

class ColorInfoDialog extends StatelessWidget {
  final GridCellInfo cellInfo;

  const ColorInfoDialog({super.key, required this.cellInfo});

  static Future<void> show(BuildContext context, GridCellInfo cellInfo) {
    return showDialog(
      context: context,
      builder: (context) => ColorInfoDialog(cellInfo: cellInfo),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label 已复制: $text'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final beadColor = cellInfo.beadColor;
    final color = cellInfo.color;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.palette, size: 24),
          const SizedBox(width: 8),
          const Text('颜色信息'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPositionInfo(context),
          const Divider(height: 24),
          _buildColorPreview(context, color),
          const SizedBox(height: 16),
          _buildColorValues(context, color),
          if (beadColor != null) ...[
            const Divider(height: 24),
            _buildBeadColorInfo(context, beadColor),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
        if (beadColor != null)
          FilledButton.icon(
            onPressed: () => _copyAllInfo(context, beadColor, color),
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('复制全部'),
          ),
      ],
    );
  }

  Widget _buildPositionInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.grid_on,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '格子位置: (${cellInfo.x}, ${cellInfo.y})',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPreview(BuildContext context, Color color) {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.5),
              width: 2,
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
                '颜色预览',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                cellInfo.hexString,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorValues(BuildContext context, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('颜色数值', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildColorValueItem(
                context,
                'R',
                (color.r * 255.0).round().toString(),
                Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildColorValueItem(
                context,
                'G',
                (color.g * 255.0).round().toString(),
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildColorValueItem(
                context,
                'B',
                (color.b * 255.0).round().toString(),
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildCopyableItem(
                context,
                'HEX',
                cellInfo.hexString,
                Icons.copy,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCopyableItem(
                context,
                'RGB',
                cellInfo.rgbString,
                Icons.copy,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorValueItem(
    BuildContext context,
    String label,
    String value,
    Color indicatorColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: indicatorColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return InkWell(
      onTap: () => _copyToClipboard(context, value, label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
            Flexible(
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildBeadColorInfo(BuildContext context, BeadColor beadColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.category,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text('匹配的拼豆颜色', style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: beadColor.color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            beadColor.code,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            beadColor.name,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      beadColor.hexCode,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (beadColor.category != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        beadColor.category!,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _copyToClipboard(
                  context,
                  '${beadColor.code} - ${beadColor.name}',
                  '颜色信息',
                ),
                icon: const Icon(Icons.copy),
                tooltip: '复制颜色信息',
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _copyAllInfo(BuildContext context, BeadColor beadColor, Color color) {
    final info =
        '''
格子位置: (${cellInfo.x}, ${cellInfo.y})
颜色: ${cellInfo.hexString}
RGB: (${(color.r * 255.0).round()}, ${(color.g * 255.0).round()}, ${(color.b * 255.0).round()})
拼豆色号: ${beadColor.code}
拼豆名称: ${beadColor.name}
拼豆HEX: ${beadColor.hexCode}
'''
            .trim();

    Clipboard.setData(ClipboardData(text: info));
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('颜色信息已复制到剪贴板'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class ImagePainter extends CustomPainter {
  final ui.Image image;
  final bool showGrid;
  final Size gridSize;
  final Offset? hoveredCell;
  final GridCellInfo? hoveredCellInfo;

  ImagePainter(
    this.image, {
    this.showGrid = false,
    this.gridSize = Size.zero,
    this.hoveredCell,
    this.hoveredCellInfo,
  });

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

      if (hoveredCell != null && hoveredCellInfo != null) {
        final highlightPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;

        final highlightBorderPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

        final cellX = hoveredCell!.dx;
        final cellY = hoveredCell!.dy;

        final highlightRect = Rect.fromLTWH(
          destRect.left + cellX * cellWidth,
          destRect.top + cellY * cellHeight,
          cellWidth,
          cellHeight,
        );

        canvas.drawRect(highlightRect, highlightPaint);
        canvas.drawRect(highlightRect, highlightBorderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ImagePainter oldDelegate) {
    return oldDelegate.hoveredCell != hoveredCell ||
        oldDelegate.hoveredCellInfo != hoveredCellInfo;
  }
}
