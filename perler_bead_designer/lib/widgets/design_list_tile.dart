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

  const DesignListTile({
    super.key,
    required this.design,
    required this.onTap,
    this.onDelete,
    this.onExport,
    this.onRename,
    this.index,
  });

  @override
  State<DesignListTile> createState() => _DesignListTileState();
}

class _DesignListTileState extends State<DesignListTile> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final card = Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: () => _showContextMenu(context),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.grid_on,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.design.width} × ${widget.design.height}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.palette,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.design.getUniqueColorCount()} 种颜色',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(widget.design.updatedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
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
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.index != null) {
      return AnimatedListItem(
        index: widget.index!,
        child: card,
      );
    }
    return card;
  }

  Widget _buildThumbnail(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final usedColors = widget.design.getUsedColors();

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: usedColors.isEmpty
          ? Icon(
              Icons.grid_on,
              size: 28,
              color: colorScheme.outline,
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: usedColors.take(16).map((color) {
                  return Container(
                    color: color.color,
                  );
                }).toList(),
              ),
            ),
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
    final Offset position =
        button.localToGlobal(Offset.zero, ancestor: overlay);
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
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: colorScheme.error),
            title: Text('删除',
                style: TextStyle(color: colorScheme.error)),
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
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除设计'),
        content: Text('确定要删除"${widget.design.name}"吗？此操作不可撤销。'),
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
