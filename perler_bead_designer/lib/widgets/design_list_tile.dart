import 'package:flutter/material.dart';

import '../models/bead_design.dart';
import '../utils/animations.dart';

class DesignListTile extends StatefulWidget {
  final BeadDesign design;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onExport;
  final VoidCallback? onRename;
  final int? index;
  final bool showDetails;

  const DesignListTile({
    super.key,
    required this.design,
    required this.onTap,
    this.onDelete,
    this.onExport,
    this.onRename,
    this.index,
    this.showDetails = false,
  });

  @override
  State<DesignListTile> createState() => _DesignListTileState();
}

class _DesignListTileState extends State<DesignListTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final card = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        child: Card(
          elevation: _isHovered ? 4 : 1,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: () => _showContextMenu(context),
            onSecondaryTap: () => _showContextMenu(context),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildThumbnail(context),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.design.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        _buildInfoRow(context),
                        if (widget.showDetails) ...[
                          const SizedBox(height: 8),
                          _buildDetailsCard(context),
                        ],
                        const SizedBox(height: 4),
                        _buildTimeInfo(context),
                      ],
                    ),
                  ),
                  _buildPopupMenu(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.index != null) {
      return AnimatedListItem(index: widget.index!, child: card);
    }
    return card;
  }

  Widget _buildInfoRow(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _buildInfoChip(
          context,
          icon: Icons.grid_on,
          label: '${widget.design.width} × ${widget.design.height}',
        ),
        _buildInfoChip(
          context,
          icon: Icons.palette,
          label: '${widget.design.getUniqueColorCount()} 种颜色',
        ),
        _buildInfoChip(
          context,
          icon: Icons.grain,
          label: '${widget.design.getTotalBeadCount()} 颗豆',
        ),
      ],
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildTimeInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(Icons.update, size: 12, color: colorScheme.outline),
        const SizedBox(width: 4),
        Text(
          '修改于 ${_formatDateTime(widget.design.updatedAt)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.outline,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 12),
        Icon(Icons.schedule, size: 12, color: colorScheme.outline),
        const SizedBox(width: 4),
        Text(
          '创建于 ${_formatDateTime(widget.design.createdAt)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.outline,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final usedColors = widget.design.getUsedColors();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                '详细信息',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  context,
                  '设计ID',
                  widget.design.id.length > 12
                      ? '${widget.design.id.substring(0, 12)}...'
                      : widget.design.id,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  context,
                  '画布大小',
                  '${widget.design.width} × ${widget.design.height}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  context,
                  '使用颜色',
                  '${widget.design.getUniqueColorCount()} 种',
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  context,
                  '拼豆总数',
                  '${widget.design.getTotalBeadCount()} 颗',
                ),
              ),
            ],
          ),
          if (usedColors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '使用的颜色',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 24,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: usedColors.length > 20 ? 20 : usedColors.length,
                separatorBuilder: (context, index) => const SizedBox(width: 2),
                itemBuilder: (context, index) {
                  return Tooltip(
                    message:
                        '${usedColors[index].name} (${usedColors[index].code})',
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: usedColors[index].color,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: colorScheme.outlineVariant,
                          width: 0.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        Text(value, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final grid = widget.design.grid;
    final hasContent = widget.design.getTotalBeadCount() > 0;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isHovered ? colorScheme.primary : colorScheme.outlineVariant,
          width: _isHovered ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: !hasContent
            ? Icon(Icons.grid_on, size: 32, color: colorScheme.outline)
            : _buildGridPreview(context, grid),
      ),
    );
  }

  Widget _buildGridPreview(BuildContext context, List<List<dynamic>> grid) {
    final width = widget.design.width;
    final height = widget.design.height;
    final cellSize = 64.0 / (width > height ? width : height);

    return CustomPaint(
      size: const Size(64, 64),
      painter: _GridPreviewPainter(
        grid: grid,
        width: width,
        height: height,
        cellSize: cellSize,
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: _isHovered ? colorScheme.primary : null,
      ),
      onSelected: (value) => _handleMenuAction(value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'open',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('打开编辑'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'rename',
          child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('重命名'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'export',
          child: ListTile(
            leading: Icon(Icons.download),
            title: Text('导出'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'details',
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('查看详情'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: colorScheme.error),
            title: Text('删除', style: TextStyle(color: colorScheme.error)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '刚刚';
        }
        return '${difference.inMinutes} 分钟前';
      }
      return '${difference.inHours} 小时前';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    } else {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }

  void _showContextMenu(BuildContext context) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final RenderBox button = context.findRenderObject()! as RenderBox;
    final Offset position = button.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );
    final colorScheme = Theme.of(context).colorScheme;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + button.size.height,
        overlay.size.width - position.dx - button.size.width,
        overlay.size.height - position.dy - button.size.height,
      ),
      items: [
        const PopupMenuItem(
          value: 'open',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('打开编辑'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'rename',
          child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('重命名'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'export',
          child: ListTile(
            leading: Icon(Icons.download),
            title: Text('导出'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'details',
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('查看详情'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: colorScheme.error),
            title: Text('删除', style: TextStyle(color: colorScheme.error)),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    ).then((value) {
      if (value != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _handleMenuAction(value);
          }
        });
      }
    });
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'open':
        widget.onTap();
        break;
      case 'rename':
        widget.onRename?.call();
        break;
      case 'export':
        widget.onExport?.call();
        break;
      case 'details':
        _showDetailsDialog();
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _showDetailsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _DesignDetailsDialog(design: widget.design),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除设计'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要删除"${widget.design.name}"吗？'),
            const SizedBox(height: 8),
            Text(
              '此操作不可撤销。',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                color: Theme.of(ctx).colorScheme.error,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onDelete?.call();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

class _GridPreviewPainter extends CustomPainter {
  final List<List<dynamic>> grid;
  final int width;
  final int height;
  final double cellSize;

  _GridPreviewPainter({
    required this.grid,
    required this.width,
    required this.height,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final offsetX = (size.width - width * cellSize) / 2;
    final offsetY = (size.height - height * cellSize) / 2;

    for (int y = 0; y < grid.length && y < height; y++) {
      for (int x = 0; x < grid[y].length && x < width; x++) {
        final cell = grid[y][x];
        if (cell != null && cell.color != null) {
          paint.color = cell.color;
          canvas.drawRect(
            Rect.fromLTWH(
              offsetX + x * cellSize,
              offsetY + y * cellSize,
              cellSize,
              cellSize,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPreviewPainter oldDelegate) {
    return grid != oldDelegate.grid ||
        width != oldDelegate.width ||
        height != oldDelegate.height;
  }
}

class _DesignDetailsDialog extends StatelessWidget {
  final BeadDesign design;

  const _DesignDetailsDialog({required this.design});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final usedColors = design.getUsedColors();

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.info_outline, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(design.name, overflow: TextOverflow.ellipsis)),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPreviewSection(context),
              const SizedBox(height: 16),
              _buildInfoSection(context),
              const SizedBox(height: 16),
              _buildTimeSection(context),
              if (usedColors.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildColorsSection(context, usedColors),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _buildPreviewSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final grid = design.grid;
    final hasContent = design.getTotalBeadCount() > 0;

    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: !hasContent
              ? Icon(Icons.grid_on, size: 48, color: colorScheme.outline)
              : CustomPaint(
                  size: const Size(120, 120),
                  painter: _GridPreviewPainter(
                    grid: grid,
                    width: design.width,
                    height: design.height,
                    cellSize:
                        120.0 /
                        (design.width > design.height
                            ? design.width
                            : design.height),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '基本信息',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _buildInfoRow(context, '设计ID', design.id),
        _buildInfoRow(context, '画布尺寸', '${design.width} × ${design.height} 格'),
        _buildInfoRow(context, '使用颜色', '${design.getUniqueColorCount()} 种'),
        _buildInfoRow(context, '拼豆总数', '${design.getTotalBeadCount()} 颗'),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '时间信息',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _buildInfoRow(context, '创建时间', _formatFullDateTime(design.createdAt)),
        _buildInfoRow(context, '修改时间', _formatFullDateTime(design.updatedAt)),
      ],
    );
  }

  Widget _buildColorsSection(BuildContext context, List usedColors) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '使用的颜色 (${usedColors.length} 种)',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: usedColors.map((color) {
            return Tooltip(
              message: '${color.name} (${color.code})',
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.color,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatFullDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
