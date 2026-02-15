import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/data_export_service.dart';
import '../services/design_storage_service.dart';
import '../services/performance_service.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../widgets/performance_monitor.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String appName = '兔可可的拼豆世界';
  static const String appVersion = '1.1.0';
  static const String developer = 'BunnyCC';
  static const String copyright =
      'Copyright © 2026 BunnyCC. All rights reserved.';

  late bool _exportShowGrid;
  late bool _exportPdfIncludeStats;
  late int _defaultCanvasWidth;
  late int _defaultCanvasHeight;
  late int _lowStockThreshold;
  late String _defaultExportFormat;

  final PerformanceService _performanceService = PerformanceService();
  bool _showPerformanceMonitor = false;

  int _versionTapCount = 0;
  DateTime? _lastVersionTapTime;
  static const int _godModeTapThreshold = 7;
  static const Duration _tapTimeout = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    final settingsService = SettingsService();
    _exportShowGrid = settingsService.getExportShowGrid();
    _exportPdfIncludeStats = settingsService.getExportPdfIncludeStats();
    _defaultCanvasWidth = settingsService.getDefaultCanvasWidth();
    _defaultCanvasHeight = settingsService.getDefaultCanvasHeight();
    _lowStockThreshold = settingsService.getLowStockThreshold();
    _defaultExportFormat = settingsService.getDefaultExportFormat();
    _performanceService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '设置',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '自定义您的应用体验',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            _buildThemeSection(context),
            const SizedBox(height: 24),
            _buildAnimationSection(context),
            const SizedBox(height: 24),
            _buildCustomizationSection(context),
            const SizedBox(height: 24),
            _buildExportSection(context),
            const SizedBox(height: 24),
            _buildDataSection(context),
            const SizedBox(height: 24),
            _buildAboutSection(context),
            Consumer<AppProvider>(
              builder: (context, appProvider, child) {
                if (appProvider.godModeEnabled) {
                  return Column(
                    children: [
                      const SizedBox(height: 24),
                      _buildGodModeSection(context),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return _SettingsCard(
      title: '外观',
      icon: Icons.palette_outlined,
      children: [
        ListTile(
          leading: Icon(
            _getThemeIcon(appProvider.themeMode),
            color: colorScheme.primary,
          ),
          title: const Text('主题模式'),
          subtitle: Text(_getThemeLabel(appProvider.themeMode)),
          trailing: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto),
                label: Text('系统'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode),
                label: Text('亮色'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode),
                label: Text('暗色'),
              ),
            ],
            selected: {appProvider.themeMode},
            onSelectionChanged: (modes) {
              appProvider.setThemeMode(modes.first);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnimationSection(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return _SettingsCard(
      title: '动画效果',
      icon: Icons.animation,
      children: [
        SwitchListTile(
          secondary: Icon(Icons.motion_photos_on, color: colorScheme.primary),
          title: const Text('启用动画效果'),
          subtitle: const Text('关闭后将禁用所有界面动画'),
          value: appProvider.animationsEnabled,
          onChanged: (value) {
            appProvider.setAnimationsEnabled(value);
          },
        ),
        const Divider(),
        SwitchListTile(
          secondary: Icon(Icons.swap_horiz, color: colorScheme.secondary),
          title: const Text('页面切换动画'),
          subtitle: const Text('页面切换时的过渡动画效果'),
          value:
              appProvider.pageTransitionsEnabled &&
              appProvider.animationsEnabled,
          onChanged: appProvider.animationsEnabled
              ? (value) {
                  appProvider.setPageTransitionsEnabled(value);
                }
              : null,
        ),
        SwitchListTile(
          secondary: Icon(Icons.list, color: colorScheme.tertiary),
          title: const Text('列表项动画'),
          subtitle: const Text('列表项进入时的动画效果'),
          value:
              appProvider.listAnimationsEnabled &&
              appProvider.animationsEnabled,
          onChanged: appProvider.animationsEnabled
              ? (value) {
                  appProvider.setListAnimationsEnabled(value);
                }
              : null,
        ),
        SwitchListTile(
          secondary: Icon(Icons.touch_app, color: colorScheme.primary),
          title: const Text('按钮点击动画'),
          subtitle: const Text('按钮按下时的缩放动画效果'),
          value:
              appProvider.buttonAnimationsEnabled &&
              appProvider.animationsEnabled,
          onChanged: appProvider.animationsEnabled
              ? (value) {
                  appProvider.setButtonAnimationsEnabled(value);
                }
              : null,
        ),
        SwitchListTile(
          secondary: Icon(Icons.widgets, color: colorScheme.secondary),
          title: const Text('卡片交互动画'),
          subtitle: const Text('卡片点击时的动画效果'),
          value:
              appProvider.cardAnimationsEnabled &&
              appProvider.animationsEnabled,
          onChanged: appProvider.animationsEnabled
              ? (value) {
                  appProvider.setCardAnimationsEnabled(value);
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildPerformanceSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _SettingsCard(
      title: '性能设置',
      icon: Icons.speed,
      children: [
        ListTile(
          leading: Icon(Icons.memory, color: colorScheme.primary),
          title: const Text('GPU 加速'),
          subtitle: Text(
            _performanceService.config.enableGpuAcceleration
                ? '已启用 - ${PerformanceService.getPlatformDefaultBackend()}'
                : '已禁用',
          ),
          trailing: Switch(
            value: _performanceService.config.enableGpuAcceleration,
            onChanged: (value) async {
              await _performanceService.setEnableGpuAcceleration(value);
              setState(() {});
            },
          ),
        ),
        ListTile(
          leading: Icon(Icons.tune, color: colorScheme.secondary),
          title: const Text('性能等级'),
          subtitle: Text(
            _getPerformanceLevelLabel(
              _performanceService.config.performanceLevel,
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showPerformanceLevelDialog(context),
        ),
        ListTile(
          leading: Icon(Icons.monitor_heart, color: colorScheme.tertiary),
          title: const Text('性能监控'),
          subtitle: const Text('显示实时帧率和 GPU 使用率'),
          trailing: Switch(
            value: _showPerformanceMonitor,
            onChanged: (value) {
              setState(() {
                _showPerformanceMonitor = value;
              });
              if (value) {
                _performanceService.startMonitoring();
              } else {
                _performanceService.stopMonitoring();
              }
            },
          ),
        ),
        if (_showPerformanceMonitor) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: PerformanceStatsPanel(
              metrics: _performanceService.getCurrentMetrics(),
            ),
          ),
        ],
        const Divider(),
        ListTile(
          leading: Icon(
            Icons.info_outline,
            color: colorScheme.onSurfaceVariant,
          ),
          title: const Text('渲染引擎状态'),
          subtitle: Text(PerformanceService.getImpellerStatus()),
        ),
        if (Platform.isMacOS || Platform.isWindows) ...[
          ListTile(
            leading: Icon(Icons.computer, color: colorScheme.primary),
            title: Text(Platform.isMacOS ? 'Metal 后端' : 'DirectX/Vulkan 后端'),
            subtitle: Text(
              Platform.isMacOS
                  ? 'Apple Silicon 和 Intel Mac 均支持 Metal 加速'
                  : '支持 NVIDIA/AMD/Intel 显卡硬件加速',
            ),
          ),
        ],
      ],
    );
  }

  String _getPerformanceLevelLabel(PerformanceLevel level) {
    return switch (level) {
      PerformanceLevel.low => '低功耗 (30 FPS)',
      PerformanceLevel.medium => '平衡 (60 FPS)',
      PerformanceLevel.high => '高性能 (60 FPS)',
      PerformanceLevel.ultra => '极致 (120 FPS)',
    };
  }

  void _showPerformanceLevelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('性能等级'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: PerformanceLevel.values.map((level) {
            return RadioListTile<PerformanceLevel>(
              title: Text(_getPerformanceLevelLabel(level)),
              subtitle: Text(_getPerformanceLevelDescription(level)),
              value: level,
              groupValue: _performanceService.config.performanceLevel,
              onChanged: (value) async {
                if (value != null) {
                  await _performanceService.setPerformanceLevel(value);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  setState(() {});
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  String _getPerformanceLevelDescription(PerformanceLevel level) {
    return switch (level) {
      PerformanceLevel.low => '适合电池供电或老旧设备',
      PerformanceLevel.medium => '平衡性能与功耗',
      PerformanceLevel.high => '推荐设置，最佳体验',
      PerformanceLevel.ultra => '适合高刷新率显示器',
    };
  }

  Widget _buildCustomizationSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _SettingsCard(
      title: '自定义设置',
      icon: Icons.tune,
      children: [
        ListTile(
          leading: Icon(Icons.grid_4x4, color: colorScheme.primary),
          title: const Text('默认画布尺寸'),
          subtitle: const Text('新建设计时的默认尺寸'),
          trailing: Text('$_defaultCanvasWidth × $_defaultCanvasHeight'),
          onTap: () => _showCanvasSizeDialog(context),
        ),
        ListTile(
          leading: Icon(Icons.inventory, color: colorScheme.secondary),
          title: const Text('低库存阈值'),
          subtitle: const Text('库存低于此数量时显示警告'),
          trailing: Text('$_lowStockThreshold'),
          onTap: () => _showLowStockDialog(context),
        ),
        ListTile(
          leading: Icon(Icons.file_download, color: colorScheme.tertiary),
          title: const Text('默认导出格式'),
          subtitle: const Text('导出设计时的默认格式'),
          trailing: Text(_defaultExportFormat.toUpperCase()),
          onTap: () => _showExportFormatDialog(context),
        ),
      ],
    );
  }

  Widget _buildExportSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _SettingsCard(
      title: '默认导出设置',
      icon: Icons.output_outlined,
      children: [
        SwitchListTile(
          secondary: Icon(Icons.picture_as_pdf, color: colorScheme.primary),
          title: const Text('导出PDF时包含颜色统计'),
          subtitle: const Text('在PDF中显示每种颜色的使用数量'),
          value: _exportPdfIncludeStats,
          onChanged: (value) async {
            final settingsService = SettingsService();
            await settingsService.setExportPdfIncludeStats(value);
            setState(() {
              _exportPdfIncludeStats = value;
            });
          },
        ),
        SwitchListTile(
          secondary: Icon(Icons.grid_on, color: colorScheme.secondary),
          title: const Text('导出时显示网格线'),
          subtitle: const Text('在导出图片中显示网格参考线'),
          value: _exportShowGrid,
          onChanged: (value) async {
            final settingsService = SettingsService();
            await settingsService.setExportShowGrid(value);
            setState(() {
              _exportShowGrid = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDataSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final storageService = StorageService();
    final dataPath = storageService.dataDirectoryPath;

    return _SettingsCard(
      title: '数据管理',
      icon: Icons.storage_outlined,
      children: [
        ListTile(
          leading: Icon(Icons.folder_open, color: colorScheme.primary),
          title: const Text('打开数据目录'),
          subtitle: Text(
            dataPath,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openDataDirectory(context),
        ),
        ListTile(
          leading: Icon(Icons.folder_outlined, color: colorScheme.primary),
          title: const Text('导出所有数据'),
          subtitle: const Text('导出所有设计和库存数据'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _exportAllData(context),
        ),
        ListTile(
          leading: Icon(Icons.upload_file, color: colorScheme.secondary),
          title: const Text('导入数据'),
          subtitle: const Text('从备份文件恢复数据'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _importData(context),
        ),
        const Divider(),
        ListTile(
          leading: Icon(Icons.delete_outline, color: colorScheme.error),
          title: Text('清除缓存', style: TextStyle(color: colorScheme.error)),
          subtitle: const Text('清除临时文件和缓存数据'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showClearCacheDialog(context),
        ),
        ListTile(
          leading: Icon(Icons.restore, color: colorScheme.error),
          title: Text('重置应用', style: TextStyle(color: colorScheme.error)),
          subtitle: const Text('清除所有数据并重置设置'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showResetAppDialog(context),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appProvider = context.watch<AppProvider>();

    return _SettingsCard(
      title: '关于',
      icon: Icons.info_outline,
      children: [
        ListTile(
          leading: Icon(Icons.apps, color: colorScheme.primary),
          title: const Text('应用名称'),
          subtitle: const Text(appName),
        ),
        ListTile(
          leading: Icon(Icons.verified, color: colorScheme.secondary),
          title: const Text('版本'),
          subtitle: Text(appVersion),
          onTap: () => _handleVersionTap(context),
        ),
        ListTile(
          leading: Icon(Icons.history, color: colorScheme.tertiary),
          title: const Text('更新日志'),
          subtitle: const Text('查看版本更新历史'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showChangelog(context),
        ),
        ListTile(
          leading: Icon(Icons.person, color: colorScheme.primary),
          title: const Text('开发者'),
          subtitle: const Text(developer),
        ),
        ListTile(
          leading: Icon(Icons.copyright, color: colorScheme.secondary),
          title: const Text('版权信息'),
          subtitle: const Text(copyright),
        ),
        const Divider(),
        ListTile(
          leading: Icon(Icons.code, color: colorScheme.tertiary),
          title: const Text('开源许可'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            showLicensePage(
              context: context,
              applicationName: appName,
              applicationVersion: appVersion,
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.favorite, color: colorScheme.error),
          title: const Text('关于兔可可的拼豆世界'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showAboutDialog(context),
        ),
        if (appProvider.godModeEnabled) ...[
          const Divider(),
          ListTile(
            leading: Icon(Icons.admin_panel_settings, color: colorScheme.error),
            title: Text('上帝模式已启用', style: TextStyle(color: colorScheme.error)),
            subtitle: const Text('连续点击版本号 7 次可关闭'),
            onTap: () => _handleVersionTap(context),
          ),
        ],
      ],
    );
  }

  void _handleVersionTap(BuildContext context) {
    final appProvider = context.read<AppProvider>();
    final now = DateTime.now();

    if (_lastVersionTapTime == null ||
        now.difference(_lastVersionTapTime!) > _tapTimeout) {
      _versionTapCount = 1;
    } else {
      _versionTapCount++;
    }

    _lastVersionTapTime = now;

    if (_versionTapCount >= _godModeTapThreshold) {
      _versionTapCount = 0;
      final newGodModeState = !appProvider.godModeEnabled;
      appProvider.setGodModeEnabled(newGodModeState);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newGodModeState ? '上帝模式已启用！' : '上帝模式已关闭'),
          backgroundColor: newGodModeState ? Colors.purple : Colors.grey[700],
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (!appProvider.godModeEnabled && _versionTapCount > 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '再点击 ${_godModeTapThreshold - _versionTapCount} 次启用上帝模式',
          ),
          duration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  Widget _buildGodModeSection(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return _SettingsCard(
      title: '上帝模式',
      icon: Icons.admin_panel_settings,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: colorScheme.errorContainer.withValues(alpha: 0.3),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: colorScheme.error, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '高级设置选项，仅供开发者使用',
                  style: TextStyle(
                    color: colorScheme.onErrorContainer,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        SwitchListTile(
          secondary: Icon(Icons.bug_report, color: colorScheme.primary),
          title: const Text('调试模式'),
          subtitle: const Text('启用详细日志和调试信息'),
          value: appProvider.debugModeEnabled,
          onChanged: (value) {
            appProvider.setDebugModeEnabled(value);
          },
        ),
        SwitchListTile(
          secondary: Icon(Icons.monitor_heart, color: colorScheme.secondary),
          title: const Text('性能监控'),
          subtitle: const Text('显示实时性能指标'),
          value: appProvider.performanceMonitorEnabled,
          onChanged: (value) {
            appProvider.setPerformanceMonitorEnabled(value);
            setState(() {
              _showPerformanceMonitor = value;
            });
            if (value) {
              _performanceService.startMonitoring();
            } else {
              _performanceService.stopMonitoring();
            }
          },
        ),
        if (_showPerformanceMonitor) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: PerformanceStatsPanel(
              metrics: _performanceService.getCurrentMetrics(),
            ),
          ),
        ],
        SwitchListTile(
          secondary: Icon(Icons.science, color: colorScheme.tertiary),
          title: const Text('实验性功能'),
          subtitle: const Text('启用未稳定的新功能'),
          value: appProvider.experimentalFeaturesEnabled,
          onChanged: (value) {
            appProvider.setExperimentalFeaturesEnabled(value);
          },
        ),
        const Divider(),
        ListTile(
          leading: Icon(Icons.speed, color: colorScheme.primary),
          title: const Text('性能设置'),
          subtitle: const Text('GPU加速、性能等级等'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showGodModePerformanceSettings(context),
        ),
        ListTile(
          leading: Icon(Icons.animation, color: colorScheme.secondary),
          title: const Text('动画控制'),
          subtitle: const Text('全局动画效果开关'),
          trailing: Switch(
            value: appProvider.animationsEnabled,
            onChanged: (value) {
              appProvider.setAnimationsEnabled(value);
            },
          ),
        ),
        const Divider(),
        ListTile(
          leading: Icon(Icons.developer_mode, color: colorScheme.tertiary),
          title: const Text('开发者选项'),
          subtitle: const Text('查看应用内部状态'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showDeveloperOptions(context),
        ),
      ],
    );
  }

  void _showGodModePerformanceSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('性能设置'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.memory),
                title: const Text('GPU 加速'),
                subtitle: Text(
                  _performanceService.config.enableGpuAcceleration
                      ? '已启用 - ${PerformanceService.getPlatformDefaultBackend()}'
                      : '已禁用',
                ),
                trailing: Switch(
                  value: _performanceService.config.enableGpuAcceleration,
                  onChanged: (value) async {
                    await _performanceService.setEnableGpuAcceleration(value);
                    Navigator.pop(context);
                    _showGodModePerformanceSettings(context);
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('性能等级'),
                subtitle: Text(
                  _getPerformanceLevelLabel(
                    _performanceService.config.performanceLevel,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  _showPerformanceLevelDialog(this.context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('渲染引擎'),
                subtitle: Text(PerformanceService.getImpellerStatus()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showDeveloperOptions(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final settingsService = SettingsService();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('开发者选项'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '应用状态',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildDeveloperInfoRow(
                '上帝模式',
                appProvider.godModeEnabled ? '启用' : '禁用',
              ),
              _buildDeveloperInfoRow(
                '调试模式',
                appProvider.debugModeEnabled ? '启用' : '禁用',
              ),
              _buildDeveloperInfoRow(
                '动画状态',
                appProvider.animationsEnabled ? '启用' : '禁用',
              ),
              _buildDeveloperInfoRow('主题模式', appProvider.themeMode.name),
              const Divider(),
              Text(
                '存储信息',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildDeveloperInfoRow(
                '设置已初始化',
                settingsService.containsKey('theme_mode') ? '是' : '否',
              ),
              const Divider(),
              Text(
                '性能信息',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildDeveloperInfoRow(
                'GPU加速',
                _performanceService.config.enableGpuAcceleration ? '启用' : '禁用',
              ),
              _buildDeveloperInfoRow(
                '性能等级',
                _getPerformanceLevelLabel(
                  _performanceService.config.performanceLevel,
                ),
              ),
              _buildDeveloperInfoRow(
                '渲染引擎',
                PerformanceService.getImpellerStatus(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
    }
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return '跟随系统设置';
      case ThemeMode.light:
        return '始终使用亮色主题';
      case ThemeMode.dark:
        return '始终使用暗色主题';
    }
  }

  void _showCanvasSizeDialog(BuildContext context) {
    final widthController = TextEditingController(
      text: _defaultCanvasWidth.toString(),
    );
    final heightController = TextEditingController(
      text: _defaultCanvasHeight.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('默认画布尺寸'),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: widthController,
                decoration: const InputDecoration(
                  labelText: '宽度',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: heightController,
                decoration: const InputDecoration(
                  labelText: '高度',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final width = int.tryParse(widthController.text) ?? 29;
              final height = int.tryParse(heightController.text) ?? 29;
              final settingsService = SettingsService();
              await settingsService.setDefaultCanvasWidth(width);
              await settingsService.setDefaultCanvasHeight(height);
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {
                  _defaultCanvasWidth = width;
                  _defaultCanvasHeight = height;
                });
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showLowStockDialog(BuildContext context) {
    final controller = TextEditingController(
      text: _lowStockThreshold.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('低库存阈值'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '阈值数量',
            border: OutlineInputBorder(),
            suffixText: '颗',
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final threshold = int.tryParse(controller.text) ?? 50;
              final settingsService = SettingsService();
              await settingsService.setLowStockThreshold(threshold);
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {
                  _lowStockThreshold = threshold;
                });
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showExportFormatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('默认导出格式'),
        content: RadioGroup<String>(
          groupValue: _defaultExportFormat,
          onChanged: (value) async {
            if (value != null) {
              final settingsService = SettingsService();
              await settingsService.setDefaultExportFormat(value);
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {
                  _defaultExportFormat = value;
                });
              }
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('PNG'),
                subtitle: const Text('适合屏幕显示和分享'),
                value: 'png',
              ),
              RadioListTile<String>(
                title: const Text('PDF'),
                subtitle: const Text('适合打印输出'),
                value: 'pdf',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _showChangelog(BuildContext context) async {
    showDialog(context: context, builder: (context) => const ChangelogDialog());
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AboutAppDialog(
        appName: appName,
        version: appVersion,
        developer: developer,
        copyright: copyright,
      ),
    );
  }

  void _exportAllData(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出所有数据'),
        content: const Text('将导出所有设计和库存数据到 JSON 文件。\n\n您可以选择保存位置。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('导出'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    String statusText = '准备导出...';
    double progress = 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('导出数据'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: progress / 100),
              const SizedBox(height: 16),
              Text(statusText),
            ],
          ),
        ),
      ),
    );

    final exportService = DataExportService();
    final success = await exportService.exportAllDataToFile(
      onProgress: (current, total, status) {
        statusText = status;
        progress = current.toDouble();
      },
    );

    if (context.mounted) {
      Navigator.pop(context);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('数据导出成功'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('导出已取消或失败')));
      }
    }
  }

  void _openDataDirectory(BuildContext context) async {
    final storageService = StorageService();
    final success = await storageService.openDataDirectory();
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已打开数据目录')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('无法打开数据目录')));
      }
    }
  }

  void _importData(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入数据'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('从备份文件恢复数据。'),
            SizedBox(height: 12),
            Text('• 已存在的设计将被重命名导入'),
            Text('• 库存数量将与现有库存合并'),
            Text('• 此操作不可撤销'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('选择文件'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    String statusText = '准备导入...';
    double progress = 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('导入数据'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: progress / 100),
              const SizedBox(height: 16),
              Text(statusText),
            ],
          ),
        ),
      ),
    );

    final exportService = DataExportService();
    final result = await exportService.importDataFromFile(
      onProgress: (current, total, status) {
        statusText = status;
        progress = current.toDouble();
      },
    );

    if (context.mounted) {
      Navigator.pop(context);

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.summary),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (result.cancelled) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('导入已取消')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? '导入失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除缓存'),
        content: const Text('确定要清除所有缓存数据吗？这不会影响您的设计和库存数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('缓存已清除')));
            },
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }

  void _showResetAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置应用'),
        content: const Text('确定要重置应用吗？这将删除所有设计、库存数据和设置，此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(context);

              final settingsService = SettingsService();
              await settingsService.clearAllSettings();

              final designStorageService = DesignStorageService();
              await designStorageService.clearAllDesigns();

              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('应用已重置')));
              }
            },
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(icon, size: 20, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class ChangelogDialog extends StatefulWidget {
  const ChangelogDialog({super.key});

  @override
  State<ChangelogDialog> createState() => _ChangelogDialogState();
}

class _ChangelogDialogState extends State<ChangelogDialog> {
  List<dynamic> _versions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChangelog();
  }

  Future<void> _loadChangelog() async {
    try {
      final String content = await rootBundle.loadString(
        'assets/changelog.json',
      );
      final Map<String, dynamic> data = json.decode(content);
      setState(() {
        _versions = data['versions'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('更新日志'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _versions.length,
                itemBuilder: (context, index) {
                  final version = _versions[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'v${version['version']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                version['date'] ?? '',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...((version['changes'] as List?) ?? []).map((
                            change,
                          ) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '• ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Expanded(child: Text(change.toString())),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}

class AboutAppDialog extends StatelessWidget {
  final String appName;
  final String version;
  final String developer;
  final String copyright;

  const AboutAppDialog({
    super.key,
    required this.appName,
    required this.version,
    required this.developer,
    required this.copyright,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.grid_on,
              size: 48,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            appName,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'BunnyCC Perler',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'v$version',
              style: TextStyle(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '一款专为拼豆爱好者设计的设计工具',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                developer,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            copyright,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
