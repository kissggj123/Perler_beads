import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bead_design.dart';
import '../models/plugin_interface.dart';
import '../providers/plugin_provider.dart';

class PluginPanel extends StatefulWidget {
  final BeadDesign? initialDesign;
  final Function(BeadDesign)? onDesignUpdated;

  const PluginPanel({super.key, this.initialDesign, this.onDesignUpdated});

  @override
  State<PluginPanel> createState() => _PluginPanelState();
}

class _PluginPanelState extends State<PluginPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialDesign != null) {
        context.read<PluginProvider>().setCurrentDesign(widget.initialDesign);
      }
    });
  }

  @override
  void didUpdateWidget(PluginPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDesign != oldWidget.initialDesign) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.initialDesign != null) {
          context.read<PluginProvider>().setCurrentDesign(widget.initialDesign);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PluginProvider>(
      builder: (context, provider, child) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, provider),
              const Divider(height: 1),
              Expanded(
                child: Row(
                  children: [
                    _buildPluginList(context, provider),
                    const VerticalDivider(width: 1),
                    Expanded(child: _buildPluginDetails(context, provider)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, PluginProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.extension, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            '插件工具',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${provider.plugins.length} 个插件',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPluginList(BuildContext context, PluginProvider provider) {
    final groupedPlugins = provider.pluginsGroupedByCategory;
    final categories = groupedPlugins.keys.toList()..sort();

    return SizedBox(
      width: 200,
      child: Column(
        children: [
          _buildSearchBar(context, provider),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _buildAllPluginsItem(context, provider),
                ...categories.map((category) {
                  return _buildCategorySection(
                    context,
                    provider,
                    _getCategoryName(category),
                    category,
                    groupedPlugins[category]!,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, PluginProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        onChanged: (value) => provider.setSearchQuery(value),
        decoration: InputDecoration(
          hintText: '搜索插件...',
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildAllPluginsItem(BuildContext context, PluginProvider provider) {
    final isSelected = provider.selectedCategory == 'all';

    return Material(
      color: isSelected
          ? Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.3)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => provider.setSelectedCategory('all'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.apps,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                '全部插件',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const Spacer(),
              Text(
                '${provider.plugins.length}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    PluginProvider provider,
    String categoryName,
    String categoryId,
    List<IPlugin> plugins,
  ) {
    final isSelected = provider.selectedCategory == categoryId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: isSelected
              ? Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => provider.setSelectedCategory(categoryId),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(categoryId),
                    size: 18,
                    color: _getCategoryColor(context, categoryId),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      categoryName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  Text(
                    '${plugins.length}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (provider.selectedCategory == categoryId ||
            provider.selectedCategory == 'all')
          ...plugins.map(
            (plugin) => _buildPluginItem(context, provider, plugin),
          ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildPluginItem(
    BuildContext context,
    PluginProvider provider,
    IPlugin plugin,
  ) {
    final isSelected = provider.selectedPlugin?.name == plugin.name;

    return Material(
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => provider.selectPlugin(plugin.name),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          margin: const EdgeInsets.only(left: 24),
          child: Row(
            children: [
              Icon(
                _getPluginIcon(plugin.name),
                size: 16,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getPluginDisplayName(plugin.name),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : null,
                      ),
                    ),
                    Text(
                      'v${plugin.version}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPluginDetails(BuildContext context, PluginProvider provider) {
    final plugin = provider.selectedPlugin;

    if (plugin == null) {
      return _buildEmptyState(context, provider);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPluginInfo(context, plugin),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _buildDesignStatus(context, provider),
          const SizedBox(height: 16),
          _buildParametersSection(context, provider, plugin),
          const SizedBox(height: 24),
          _buildExecuteButton(context, provider),
          if (provider.lastError != null) _buildErrorSection(context, provider),
          if (provider.lastResult != null && provider.lastResult!.success)
            _buildResultSection(context, provider),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, PluginProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app,
            size: 48,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '请从左侧选择一个插件',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '选择后将显示插件详情和参数设置',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPluginInfo(BuildContext context, IPlugin plugin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getPluginIcon(plugin.name),
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getPluginDisplayName(plugin.name),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '版本 ${plugin.version}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          plugin.description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildInfoChip(
              context,
              Icons.person_outline,
              plugin.metadata.author,
            ),
            ...plugin.metadata.tags.map(
              (tag) => _buildInfoChip(
                context,
                Icons.label_outline,
                tag,
                isTag: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String label, {
    bool isTag = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isTag
            ? Theme.of(context).colorScheme.secondaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isTag
                ? Theme.of(context).colorScheme.onSecondaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isTag
                  ? Theme.of(context).colorScheme.onSecondaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesignStatus(BuildContext context, PluginProvider provider) {
    final hasDesign = provider.hasDesign;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasDesign
            ? Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.3)
            : Theme.of(
                context,
              ).colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasDesign
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasDesign
                ? Icons.check_circle_outline
                : Icons.warning_amber_outlined,
            size: 20,
            color: hasDesign
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasDesign
                  ? '设计已加载: ${provider.currentDesign!.name} (${provider.currentDesign!.width}×${provider.currentDesign!.height})'
                  : '未加载设计，请先打开或创建一个设计',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: hasDesign
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParametersSection(
    BuildContext context,
    PluginProvider provider,
    IPlugin plugin,
  ) {
    if (plugin.parameters.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                '此插件没有可配置的参数',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '参数设置',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => provider.resetParameters(),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('重置'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...plugin.parameters.map(
          (param) => _buildParameterControl(context, provider, param),
        ),
      ],
    );
  }

  Widget _buildParameterControl(
    BuildContext context,
    PluginProvider provider,
    PluginParameter param,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                param.label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: param.description,
                child: Icon(
                  Icons.help_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (param is PluginParameterNumber)
            _buildNumberControl(context, provider, param)
          else if (param is PluginParameterBoolean)
            _buildBooleanControl(context, provider, param)
          else if (param is PluginParameterSelect)
            _buildSelectControl(context, provider, param),
        ],
      ),
    );
  }

  Widget _buildNumberControl(
    BuildContext context,
    PluginProvider provider,
    PluginParameterNumber param,
  ) {
    final value = provider.currentParameters[param.key] ?? param.defaultValue;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Slider(
                value: (value as num).toDouble(),
                min: param.min.isFinite ? param.min : 0,
                max: param.max.isFinite ? param.max : 100,
                divisions: param.max.isFinite && param.min.isFinite
                    ? ((param.max - param.min) / param.step).round().clamp(
                        1,
                        100,
                      )
                    : null,
                onChanged: (newValue) {
                  provider.updateParameter(param.key, newValue);
                },
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                value.toStringAsFixed(1),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        if (param.min.isFinite && param.max.isFinite)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '最小: ${param.min.toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '最大: ${param.max.toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildBooleanControl(
    BuildContext context,
    PluginProvider provider,
    PluginParameterBoolean param,
  ) {
    final value = provider.currentParameters[param.key] ?? param.defaultValue;

    return SwitchListTile(
      value: value as bool,
      onChanged: (newValue) {
        provider.updateParameter(param.key, newValue);
      },
      contentPadding: EdgeInsets.zero,
      title: Text(
        value ? '已启用' : '已禁用',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Widget _buildSelectControl(
    BuildContext context,
    PluginProvider provider,
    PluginParameterSelect param,
  ) {
    final value = provider.currentParameters[param.key] ?? param.defaultValue;

    return DropdownButtonFormField<String>(
      initialValue: value as String,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: param.options.map((option) {
        return DropdownMenuItem(value: option.value, child: Text(option.label));
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          provider.updateParameter(param.key, newValue);
        }
      },
    );
  }

  Widget _buildExecuteButton(BuildContext context, PluginProvider provider) {
    final canExecute = provider.canExecute;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canExecute
            ? () async {
                final result = await provider.executePlugin();
                if (result != null &&
                    result.success &&
                    widget.onDesignUpdated != null) {
                  widget.onDesignUpdated!(result.design);
                }
              }
            : null,
        icon: provider.isProcessing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow),
        label: Text(provider.isProcessing ? '处理中...' : '执行插件'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildErrorSection(BuildContext context, PluginProvider provider) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              provider.lastError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            iconSize: 18,
            color: Theme.of(context).colorScheme.onErrorContainer,
            onPressed: () => provider.clearLastError(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection(BuildContext context, PluginProvider provider) {
    final result = provider.lastResult!;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.message ?? '插件执行成功',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                iconSize: 18,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                onPressed: () => provider.clearLastResult(),
              ),
            ],
          ),
          if (result.statistics != null) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              '统计信息:',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            ...result.statistics!.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '• ${_formatStatKey(entry.key)}: ${entry.value}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  String _formatStatKey(String key) {
    final words = key.split('_');
    return words
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'color':
        return '颜色处理';
      case 'effect':
        return '特效';
      case 'transform':
        return '变换';
      case 'general':
        return '通用';
      default:
        return category;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'color':
        return Icons.palette_outlined;
      case 'effect':
        return Icons.auto_awesome_outlined;
      case 'transform':
        return Icons.transform_outlined;
      case 'general':
        return Icons.widgets_outlined;
      default:
        return Icons.extension_outlined;
    }
  }

  Color _getCategoryColor(BuildContext context, String category) {
    switch (category) {
      case 'color':
        return Theme.of(context).colorScheme.primary;
      case 'effect':
        return Theme.of(context).colorScheme.secondary;
      case 'transform':
        return Theme.of(context).colorScheme.tertiary;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  String _getPluginDisplayName(String name) {
    switch (name) {
      case 'color_optimizer':
        return '颜色优化';
      case 'dithering':
        return '抖动处理';
      case 'outline':
        return '轮廓工具';
      default:
        return name;
    }
  }

  IconData _getPluginIcon(String name) {
    switch (name) {
      case 'color_optimizer':
        return Icons.palette;
      case 'dithering':
        return Icons.gradient;
      case 'outline':
        return Icons.border_outer;
      default:
        return Icons.extension;
    }
  }
}
