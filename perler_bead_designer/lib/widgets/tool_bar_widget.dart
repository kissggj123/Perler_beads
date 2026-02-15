import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/design_editor_provider.dart';

class ToolBarWidget extends StatelessWidget {
  const ToolBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DesignEditorProvider>(
      builder: (context, provider, child) {
        return Container(
          height: 56,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              _buildDesignInfo(context, provider),
              const VerticalDivider(width: 32),
              _buildToolButtons(context, provider),
              const VerticalDivider(width: 32),
              _buildActionButtons(context, provider),
              const Spacer(),
              _buildQuickActions(context, provider),
              const VerticalDivider(width: 32),
              _buildViewOptions(context, provider),
              const SizedBox(width: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesignInfo(BuildContext context, DesignEditorProvider provider) {
    final design = provider.currentDesign;
    final isDirty = provider.isDirty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.edit_document,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  design?.name ?? '未命名设计',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (isDirty)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      '*',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (design != null)
              Text(
                '${design.width} × ${design.height}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolButtons(BuildContext context, DesignEditorProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildToolButton(
          context,
          icon: Icons.edit,
          label: '绘制',
          shortcut: 'D',
          isSelected: provider.toolMode == ToolMode.draw,
          onPressed: () => provider.setToolMode(ToolMode.draw),
        ),
        const SizedBox(width: 4),
        _buildToolButton(
          context,
          icon: Icons.cleaning_services,
          label: '擦除',
          shortcut: 'E',
          isSelected: provider.toolMode == ToolMode.erase,
          onPressed: () => provider.setToolMode(ToolMode.erase),
        ),
        const SizedBox(width: 4),
        _buildToolButton(
          context,
          icon: Icons.format_color_fill,
          label: '填充',
          shortcut: 'F',
          isSelected: provider.toolMode == ToolMode.fill,
          onPressed: () => provider.setToolMode(ToolMode.fill),
        ),
      ],
    );
  }

  Widget _buildToolButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? shortcut,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: shortcut != null ? '$label ($shortcut)' : label,
      child: Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, DesignEditorProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          context,
          icon: Icons.undo,
          label: '撤销',
          shortcut: 'Ctrl+Z',
          isEnabled: provider.canUndo,
          onPressed: provider.undo,
        ),
        const SizedBox(width: 4),
        _buildActionButton(
          context,
          icon: Icons.redo,
          label: '重做',
          shortcut: 'Ctrl+Y',
          isEnabled: provider.canRedo,
          onPressed: provider.redo,
        ),
        const SizedBox(width: 8),
        const VerticalDivider(width: 1),
        const SizedBox(width: 8),
        _buildActionButton(
          context,
          icon: Icons.delete_sweep,
          label: '清空',
          isEnabled: provider.hasDesign,
          onPressed: () => _showClearConfirmDialog(context, provider),
          color: Theme.of(context).colorScheme.error,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? shortcut,
    required bool isEnabled,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Tooltip(
      message: shortcut != null ? '$label ($shortcut)' : label,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 20,
              color: isEnabled
                  ? (color ?? Theme.of(context).colorScheme.onSurface)
                  : Theme.of(context).disabledColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, DesignEditorProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: '填充全部',
          child: IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: provider.hasDesign && provider.selectedColor != null
                ? () => _showFillAllConfirmDialog(context, provider)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildViewOptions(BuildContext context, DesignEditorProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildToggleOption(
          context,
          icon: Icons.grid_on,
          label: '网格',
          isEnabled: provider.showGrid,
          onPressed: provider.toggleGrid,
        ),
        const SizedBox(width: 4),
        _buildToggleOption(
          context,
          icon: Icons.pin_drop,
          label: '坐标',
          isEnabled: provider.showCoordinates,
          onPressed: provider.toggleCoordinates,
        ),
      ],
    );
  }

  Widget _buildToggleOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isEnabled,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: '$label: ${isEnabled ? "开" : "关"}',
      child: Material(
        color: isEnabled
            ? Theme.of(context).colorScheme.secondaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isEnabled
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isEnabled
                            ? Theme.of(context).colorScheme.onSecondaryContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showClearConfirmDialog(BuildContext context, DesignEditorProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空画布'),
        content: const Text('确定要清空所有拼豆吗？此操作可以撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              provider.clearAllBeads();
              Navigator.of(context).pop();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showFillAllConfirmDialog(BuildContext context, DesignEditorProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('填充全部'),
        content: Text('确定要用当前颜色填充整个画布吗？\n颜色: ${provider.selectedColor?.name ?? "未选择"}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              provider.fillAllBeads();
              Navigator.of(context).pop();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
