import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/design_editor_provider.dart';

class HistoryPanel extends StatefulWidget {
  const HistoryPanel({super.key});

  @override
  State<HistoryPanel> createState() => _HistoryPanelState();
}

class _HistoryPanelState extends State<HistoryPanel> {
  @override
  Widget build(BuildContext context) {
    return Consumer<DesignEditorProvider>(
      builder: (context, provider, child) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              left: BorderSide(color: Theme.of(context).dividerColor, width: 1),
            ),
          ),
          child: Column(
            children: [
              _buildHeader(context, provider),
              const Divider(height: 1),
              _buildStatsBar(context, provider),
              const Divider(height: 1),
              Expanded(child: _buildHistoryList(context, provider)),
              _buildFooter(context, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, DesignEditorProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        children: [
          Icon(
            Icons.history,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '操作历史',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (provider.canUndo || provider.canRedo)
            TextButton.icon(
              icon: const Icon(Icons.delete_sweep, size: 16),
              label: const Text('清空'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () => _showClearHistoryDialog(context, provider),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(BuildContext context, DesignEditorProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _buildStatChip(
            context,
            icon: Icons.undo,
            label: '可撤销',
            value: provider.undoCount.toString(),
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          _buildStatChip(
            context,
            icon: Icons.redo,
            label: '可重做',
            value: provider.redoCount.toString(),
            color: colorScheme.tertiary,
          ),
          const SizedBox(width: 12),
          _buildStatChip(
            context,
            icon: Icons.storage,
            label: '最大',
            value: provider.maxHistorySize.toString(),
            color: colorScheme.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    DesignEditorProvider provider,
  ) {
    final undoStack = provider.undoStack;
    final redoStack = provider.redoStack;

    if (undoStack.isEmpty && redoStack.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无操作历史',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '开始编辑后，操作记录将显示在这里',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final totalItems = undoStack.length + redoStack.length + 1;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (index < redoStack.length) {
          final redoIndex = redoStack.length - 1 - index;
          final history = redoStack[redoIndex];
          return _buildHistoryItem(
            context,
            provider,
            history,
            index,
            isRedo: true,
            redoIndex: redoIndex,
          );
        } else if (index == redoStack.length) {
          return _buildCurrentStateItem(context, provider, index);
        } else {
          final undoIndex = index - redoStack.length - 1;
          final history = undoStack[undoIndex];
          return _buildHistoryItem(
            context,
            provider,
            history,
            index,
            isRedo: false,
            undoIndex: undoIndex,
          );
        }
      },
    );
  }

  Widget _buildCurrentStateItem(
    BuildContext context,
    DesignEditorProvider provider,
    int index,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.primary, width: 2),
      ),
      child: ListTile(
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.edit, size: 18, color: colorScheme.onPrimary),
        ),
        title: Text(
          '当前状态',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        subtitle: Text(
          _formatTimestamp(DateTime.now()),
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '当前',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    DesignEditorProvider provider,
    EditorHistory history,
    int index, {
    required bool isRedo,
    int? undoIndex,
    int? redoIndex,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final description = history.description ?? '操作';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isRedo
            ? colorScheme.tertiaryContainer.withValues(alpha: 0.3)
            : null,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isRedo
              ? colorScheme.tertiary.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isRedo
                ? colorScheme.tertiaryContainer
                : colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getIconForDescription(description),
            size: 18,
            color: isRedo
                ? colorScheme.onTertiaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isRedo ? colorScheme.tertiary : null,
          ),
        ),
        subtitle: Text(
          _formatTimestamp(history.timestamp),
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        trailing: isRedo
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '重做',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              )
            : null,
        onTap: () {
          if (isRedo && redoIndex != null) {
            provider.jumpToRedoState(redoIndex);
          } else if (!isRedo && undoIndex != null) {
            provider.jumpToHistoryState(undoIndex);
          }
        },
      ),
    );
  }

  Widget _buildFooter(BuildContext context, DesignEditorProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.undo, size: 18),
            label: const Text('撤销'),
            onPressed: provider.canUndo ? () => provider.undo() : null,
            style: TextButton.styleFrom(
              foregroundColor: provider.canUndo
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          TextButton.icon(
            icon: const Icon(Icons.redo, size: 18),
            label: const Text('重做'),
            onPressed: provider.canRedo ? () => provider.redo() : null,
            style: TextButton.styleFrom(
              foregroundColor: provider.canRedo
                  ? colorScheme.tertiary
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog(
    BuildContext context,
    DesignEditorProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清空历史记录'),
        content: const Text('确定要清空所有历史记录吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () {
              provider.clearAllBeads();
              Navigator.pop(dialogContext);
            },
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }

  IconData _getIconForDescription(String description) {
    if (description.contains('绘制')) {
      return Icons.brush;
    } else if (description.contains('擦除') || description.contains('清除')) {
      return Icons.cleaning_services;
    } else if (description.contains('填充')) {
      return Icons.format_color_fill;
    } else if (description.contains('清空')) {
      return Icons.delete_sweep;
    } else if (description.contains('调整')) {
      return Icons.open_in_full;
    } else if (description.contains('批量')) {
      return Icons.draw;
    }
    return Icons.edit;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else {
      return '${timestamp.month}/${timestamp.day} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
