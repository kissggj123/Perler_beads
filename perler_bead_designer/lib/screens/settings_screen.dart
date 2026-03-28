import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/design_editor_provider.dart';
import '../services/data_export_service.dart';
import '../services/design_storage_service.dart';
import '../services/performance_service.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../services/version_check_service.dart';
import '../widgets/performance_monitor.dart';
import '../widgets/theme_color_picker.dart';
import '../widgets/update_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  static const String appName = '兔可可的拼豆世界';
  static const String appVersion = '2.5.1';
  static const String developer = 'BunnyCC';
  static const String copyright =
      'Copyright © 2026 BunnyCC. All rights reserved.';

  bool _exportShowGrid = false;
  bool _exportPdfIncludeStats = true;
  int _defaultCanvasWidth = 29;
  int _defaultCanvasHeight = 29;
  int _lowStockThreshold = 50;
  String _defaultExportFormat = 'png';
  int _autoSaveInterval = 30;
  int _maxHistorySize = 50;

  final PerformanceService _performanceService = PerformanceService();
  bool _showPerformanceMonitor = false;

  int _versionTapCount = 0;
  DateTime? _lastVersionTapTime;
  static const int _godModeTapThreshold = 7;
  static const Duration _tapTimeout = Duration(seconds: 2);

  late AnimationController _versionTapAnimationController;
  late Animation<double> _versionTapScaleAnimation;
  late Animation<double> _versionTapGlowAnimation;

  @override
  void initState() {
    super.initState();
    _loadSettings();

    _versionTapAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _versionTapScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _versionTapAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _versionTapGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _versionTapAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _loadSettings() async {
    try {
      final settingsService = SettingsService();
      await settingsService.initialize();

      if (mounted) {
        setState(() {
          _exportShowGrid = settingsService.getExportShowGrid();
          _exportPdfIncludeStats = settingsService.getExportPdfIncludeStats();
          _defaultCanvasWidth = settingsService.getDefaultCanvasWidth();
          _defaultCanvasHeight = settingsService.getDefaultCanvasHeight();
          _lowStockThreshold = settingsService.getLowStockThreshold();
          _defaultExportFormat = settingsService.getDefaultExportFormat();
          _autoSaveInterval = settingsService.getAutoSaveInterval();
          _maxHistorySize = settingsService.getMaxHistorySize();
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  @override
  void dispose() {
    _versionTapAnimationController.dispose();
    super.dispose();
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
            _buildPerformanceSection(context),
            const SizedBox(height: 24),
            _buildCustomizationSection(context),
            const SizedBox(height: 24),
            _buildEditorSection(context),
            const SizedBox(height: 24),
            _buildShortcutSection(context),
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
        const Divider(),
        ListTile(
          leading: Icon(Icons.color_lens, color: colorScheme.primary),
          title: const Text('主题配色'),
          subtitle: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: appProvider.themeColors.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: appProvider.themeColors.secondaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: appProvider.themeColors.accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(appProvider.themeColors.name),
              if (appProvider.isCustomTheme) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '自定义',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _navigateToThemeColorPicker(context),
        ),
        const Divider(),
        SwitchListTile(
          secondary: Icon(Icons.view_sidebar, color: colorScheme.secondary),
          title: const Text('侧边栏自动折叠'),
          subtitle: const Text('窗口缩小时自动折叠侧边栏'),
          value: appProvider.sidebarAutoCollapse,
          onChanged: (value) {
            appProvider.setSidebarAutoCollapse(value);
          },
        ),
      ],
    );
  }

  void _navigateToThemeColorPicker(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ThemeColorPickerScreen()),
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
        SwitchListTile(
          secondary: Icon(Icons.memory, color: colorScheme.primary),
          title: const Text('GPU 加速'),
          subtitle: Text(
            _performanceService.config.enableGpuAcceleration
                ? '已启用 - ${PerformanceService.getPlatformDefaultBackend()}'
                : '已禁用',
          ),
          value: _performanceService.config.enableGpuAcceleration,
          onChanged: (value) async {
            try {
              await _performanceService.setEnableGpuAcceleration(value);
              setState(() {});
            } catch (e) {
              debugPrint('Error setting GPU acceleration: $e');
            }
          },
        ),
        const Divider(),
        ListTile(
          leading: Icon(Icons.video_settings, color: colorScheme.secondary),
          title: const Text('FPS 限制'),
          subtitle: Text(_performanceService.config.fpsLimit.label),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showFpsLimitDialog(context),
        ),
        ListTile(
          leading: Icon(Icons.storage, color: colorScheme.tertiary),
          title: const Text('缓存大小'),
          subtitle: Text(_performanceService.config.cacheSize.label),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showCacheSizeDialog(context),
        ),
        const Divider(),
        ListTile(
          leading: Icon(Icons.info_outline, color: colorScheme.primary),
          title: const Text('渲染引擎'),
          subtitle: Text(PerformanceService.getImpellerStatus()),
        ),
      ],
    );
  }

  void _showFpsLimitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('FPS 限制'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: FpsLimit.values.map((limit) {
            return RadioListTile<FpsLimit>(
              title: Text(limit.label),
              subtitle: Text(_getFpsLimitDescription(limit)),
              value: limit,
              groupValue: _performanceService.config.fpsLimit,
              onChanged: (value) async {
                if (value != null) {
                  try {
                    await _performanceService.setFpsLimit(value);
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                    if (mounted) {
                      setState(() {});
                    }
                  } catch (e) {
                    debugPrint('Error setting FPS limit: $e');
                  }
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

  String _getFpsLimitDescription(FpsLimit limit) {
    return switch (limit) {
      FpsLimit.fps30 => '适合电池供电或老旧设备',
      FpsLimit.fps60 => '推荐设置，流畅体验',
      FpsLimit.fps120 => '适合高刷新率显示器',
      FpsLimit.unlimited => '不限制帧率（可能增加功耗）',
    };
  }

  void _showCacheSizeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('缓存大小'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: CacheSize.values.map((size) {
            return RadioListTile<CacheSize>(
              title: Text(size.label),
              subtitle: Text(_getCacheSizeDescription(size)),
              value: size,
              groupValue: _performanceService.config.cacheSize,
              onChanged: (value) async {
                if (value != null) {
                  try {
                    await _performanceService.setCacheSize(value);
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                    if (mounted) {
                      setState(() {});
                    }
                  } catch (e) {
                    debugPrint('Error setting cache size: $e');
                  }
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

  String _getCacheSizeDescription(CacheSize size) {
    return switch (size) {
      CacheSize.small => '适合内存较小的设备',
      CacheSize.medium => '推荐设置，平衡性能与内存',
      CacheSize.large => '适合内存充足的设备',
      CacheSize.unlimited => '不限制缓存大小',
    };
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
                  try {
                    await _performanceService.setPerformanceLevel(value);
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                    if (mounted) {
                      setState(() {});
                    }
                  } catch (e) {
                    debugPrint('Error setting performance level: $e');
                  }
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
    final appProvider = context.watch<AppProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return _SettingsCard(
      title: '自定义设置',
      icon: Icons.tune,
      children: [
        SwitchListTile(
          secondary: Icon(Icons.view_in_ar, color: colorScheme.primary),
          title: const Text('显示拼豆立体效果'),
          subtitle: const Text('为拼豆添加高光和阴影效果'),
          value: appProvider.showBead3DEffect,
          onChanged: (value) {
            appProvider.setShowBead3DEffect(value);
          },
        ),
        const Divider(),
        ListTile(
          leading: Icon(Icons.grid_on, color: colorScheme.primary),
          title: const Text('格子大小'),
          subtitle: Text('当前: ${appProvider.cellSize.toStringAsFixed(1)}'),
          trailing: SizedBox(
            width: 150,
            child: Slider(
              value: appProvider.cellSize,
              min: 10,
              max: 50,
              divisions: 40,
              label: appProvider.cellSize.toStringAsFixed(1),
              onChanged: (value) {
                appProvider.setCellSizeImmediate(value);
              },
              onChangeEnd: (value) {
                appProvider.setCellSize(value);
              },
            ),
          ),
        ),
        ListTile(
          leading: Icon(Icons.palette, color: colorScheme.secondary),
          title: const Text('网格颜色'),
          subtitle: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _parseColor(appProvider.gridColor),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: colorScheme.outline),
                ),
              ),
              Text(appProvider.gridColor),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showGridColorPicker(context, appProvider),
        ),
        ListTile(
          leading: Icon(Icons.text_fields, color: colorScheme.tertiary),
          title: const Text('坐标字体大小'),
          subtitle: Text(
            appProvider.coordinateFontSize > 0
                ? '当前: ${appProvider.coordinateFontSize.toStringAsFixed(1)}'
                : '自动: ${(appProvider.cellSize * 0.35).toStringAsFixed(1)} (格子大小 × 0.35)',
          ),
          trailing: SizedBox(
            width: 150,
            child: Slider(
              value: appProvider.coordinateFontSize > 0
                  ? appProvider.coordinateFontSize
                  : appProvider.cellSize * 0.35,
              min: 4,
              max: 20,
              divisions: 32,
              label:
                  (appProvider.coordinateFontSize > 0
                          ? appProvider.coordinateFontSize
                          : appProvider.cellSize * 0.35)
                      .toStringAsFixed(1),
              onChanged: (value) {
                appProvider.setCoordinateFontSizeImmediate(value);
              },
              onChangeEnd: (value) {
                appProvider.setCoordinateFontSize(value);
              },
            ),
          ),
        ),
        const Divider(),
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

  Widget _buildEditorSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _SettingsCard(
      title: '编辑器设置',
      icon: Icons.edit_note,
      children: [
        ListTile(
          leading: Icon(Icons.save, color: colorScheme.primary),
          title: const Text('自动保存间隔'),
          subtitle: const Text('自动保存设计的时间间隔'),
          trailing: Text('$_autoSaveInterval 秒'),
          onTap: () => _showAutoSaveIntervalDialog(context),
        ),
        ListTile(
          leading: Icon(Icons.history, color: colorScheme.secondary),
          title: const Text('历史记录数量'),
          subtitle: const Text('可撤销/重做的最大步数'),
          trailing: Text('$_maxHistorySize 步'),
          onTap: () => _showMaxHistorySizeDialog(context),
        ),
      ],
    );
  }

  void _showAutoSaveIntervalDialog(BuildContext context) {
    final options = [10, 30, 60, 120];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('自动保存间隔'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((seconds) {
            return RadioListTile<int>(
              title: Text('$seconds 秒'),
              value: seconds,
              groupValue: _autoSaveInterval,
              onChanged: (value) async {
                if (value != null) {
                  final settingsService = SettingsService();
                  await settingsService.setAutoSaveInterval(value);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  if (mounted) {
                    setState(() {
                      _autoSaveInterval = value;
                    });
                    final editorProvider = context.read<DesignEditorProvider>();
                    editorProvider.setAutoSaveInterval(value);
                  }
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

  void _showMaxHistorySizeDialog(BuildContext context) {
    final options = [10, 25, 50, 100];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('历史记录数量'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((size) {
            return RadioListTile<int>(
              title: Text('$size 步'),
              value: size,
              groupValue: _maxHistorySize,
              onChanged: (value) async {
                if (value != null) {
                  final settingsService = SettingsService();
                  await settingsService.setMaxHistorySize(value);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  if (mounted) {
                    setState(() {
                      _maxHistorySize = value;
                    });
                    final editorProvider = context.read<DesignEditorProvider>();
                    editorProvider.setMaxHistorySize(value);
                  }
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

  Widget _buildShortcutSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsService = SettingsService();
    final isMacOS = Platform.isMacOS;

    String getShortcutDisplay(String key, bool isCtrlShortcut) {
      final savedKey =
          settingsService.getStringSetting('shortcut_$key') ??
          ShortcutSettings.getDefaults()[key]!;
      if (isCtrlShortcut) {
        final modifier = isMacOS ? 'Cmd' : 'Ctrl';
        return '$modifier + $savedKey';
      }
      return savedKey;
    }

    String getRedoShortcutDisplay() {
      final undoKey =
          settingsService.getStringSetting('shortcut_undo') ??
          ShortcutSettings.getDefaults()['undo']!;
      final modifier = isMacOS ? 'Cmd' : 'Ctrl';
      return '$modifier + Shift + $undoKey';
    }

    return _SettingsCard(
      title: '快捷键设置',
      icon: Icons.keyboard,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isMacOS
                      ? 'macOS 使用 Cmd 键作为修饰键'
                      : 'Windows/Linux 使用 Ctrl 键作为修饰键',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListTile(
          leading: Icon(Icons.undo, color: colorScheme.primary),
          title: const Text('撤销'),
          subtitle: Text('撤销上一步操作 (${getShortcutDisplay('undo', true)})'),
          trailing: _ShortcutKeyDisplay(
            shortcutKey: getShortcutDisplay('undo', true),
            onTap: () => _showShortcutEditDialog(context, 'undo', '撤销', true),
          ),
        ),
        ListTile(
          leading: Icon(Icons.redo, color: colorScheme.secondary),
          title: const Text('重做'),
          subtitle: Text(
            '重做已撤销的操作 ($getRedoShortcutDisplay 或 ${getShortcutDisplay('redo', true)})',
          ),
          trailing: _ShortcutKeyDisplay(
            shortcutKey: getShortcutDisplay('redo', true),
            onTap: () => _showShortcutEditDialog(context, 'redo', '重做', true),
          ),
        ),
        ListTile(
          leading: Icon(Icons.save, color: colorScheme.tertiary),
          title: const Text('保存'),
          subtitle: Text('保存当前设计 (${getShortcutDisplay('save', true)})'),
          trailing: _ShortcutKeyDisplay(
            shortcutKey: getShortcutDisplay('save', true),
            onTap: () => _showShortcutEditDialog(context, 'save', '保存', true),
          ),
        ),
        const Divider(),
        ListTile(
          leading: Icon(Icons.arrow_upward, color: colorScheme.primary),
          title: const Text('上移画布'),
          subtitle: const Text('向上移动画布视图'),
          trailing: _ShortcutKeyDisplay(
            shortcutKey: getShortcutDisplay('moveUp', false),
            onTap: () =>
                _showShortcutEditDialog(context, 'moveUp', '上移画布', false),
          ),
        ),
        ListTile(
          leading: Icon(Icons.arrow_downward, color: colorScheme.secondary),
          title: const Text('下移画布'),
          subtitle: const Text('向下移动画布视图'),
          trailing: _ShortcutKeyDisplay(
            shortcutKey: getShortcutDisplay('moveDown', false),
            onTap: () =>
                _showShortcutEditDialog(context, 'moveDown', '下移画布', false),
          ),
        ),
        ListTile(
          leading: Icon(Icons.arrow_back, color: colorScheme.tertiary),
          title: const Text('左移画布'),
          subtitle: const Text('向左移动画布视图'),
          trailing: _ShortcutKeyDisplay(
            shortcutKey: getShortcutDisplay('moveLeft', false),
            onTap: () =>
                _showShortcutEditDialog(context, 'moveLeft', '左移画布', false),
          ),
        ),
        ListTile(
          leading: Icon(Icons.arrow_forward, color: colorScheme.primary),
          title: const Text('右移画布'),
          subtitle: const Text('向右移动画布视图'),
          trailing: _ShortcutKeyDisplay(
            shortcutKey: getShortcutDisplay('moveRight', false),
            onTap: () =>
                _showShortcutEditDialog(context, 'moveRight', '右移画布', false),
          ),
        ),
        const Divider(),
        ListTile(
          leading: Icon(Icons.zoom_in, color: colorScheme.secondary),
          title: const Text('放大'),
          subtitle: const Text('放大画布视图'),
          trailing: _ShortcutKeyDisplay(
            shortcutKey: getShortcutDisplay('zoomIn', false),
            onTap: () =>
                _showShortcutEditDialog(context, 'zoomIn', '放大', false),
          ),
        ),
        ListTile(
          leading: Icon(Icons.zoom_out, color: colorScheme.tertiary),
          title: const Text('缩小'),
          subtitle: const Text('缩小画布视图'),
          trailing: _ShortcutKeyDisplay(
            shortcutKey: getShortcutDisplay('zoomOut', false),
            onTap: () =>
                _showShortcutEditDialog(context, 'zoomOut', '缩小', false),
          ),
        ),
        ListTile(
          leading: Icon(Icons.fit_screen, color: colorScheme.primary),
          title: const Text('重置视图'),
          subtitle: const Text('重置画布缩放和位置'),
          trailing: _ShortcutKeyDisplay(
            shortcutKey: getShortcutDisplay('resetView', false),
            onTap: () =>
                _showShortcutEditDialog(context, 'resetView', '重置视图', false),
          ),
        ),
        const Divider(),
        ListTile(
          leading: Icon(Icons.restore, color: colorScheme.error),
          title: const Text('重置所有快捷键'),
          subtitle: const Text('恢复为默认快捷键设置'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showResetShortcutsDialog(context),
        ),
      ],
    );
  }

  void _showShortcutEditDialog(
    BuildContext context,
    String shortcutKey,
    String shortcutName,
    bool isCtrlShortcut,
  ) {
    final settingsService = SettingsService();
    final currentKey =
        settingsService.getStringSetting('shortcut_$shortcutKey') ??
        ShortcutSettings.getDefaults()[shortcutKey]!;
    final isMacOS = Platform.isMacOS;
    final modifier = isMacOS ? 'Cmd' : 'Ctrl';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('设置 "$shortcutName" 快捷键'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '当前快捷键: ${isCtrlShortcut ? '$modifier + ' : ''}$currentKey',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (shortcutKey == 'undo') ...[
              const SizedBox(height: 8),
              Text(
                '提示: 重做可使用 $modifier + Shift + $currentKey',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text('点击下方输入框后按下新按键'),
            const SizedBox(height: 16),
            _ShortcutKeyInput(
              currentKey: currentKey,
              onKeyChanged: (newKey) {
                Navigator.pop(dialogContext);
                _saveShortcutKey(shortcutKey, newKey);
              },
            ),
          ],
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

  Future<void> _saveShortcutKey(String shortcutKey, String newKey) async {
    final settingsService = SettingsService();
    await settingsService.setStringSetting('shortcut_$shortcutKey', newKey);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('快捷键已保存')));
    }
  }

  void _showResetShortcutsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('重置快捷键'),
        content: const Text('确定要将所有快捷键恢复为默认值吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final settingsService = SettingsService();
              final defaults = ShortcutSettings.getDefaults();
              for (final entry in defaults.entries) {
                await settingsService.setStringSetting(
                  'shortcut_${entry.key}',
                  entry.value,
                );
              }
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
              if (mounted) {
                setState(() {});
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('快捷键已重置为默认值')));
              }
            },
            child: const Text('重置'),
          ),
        ],
      ),
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
    final versionCheckService = VersionCheckService();

    return _SettingsCard(
      title: '关于',
      icon: Icons.info_outline,
      children: [
        ListTile(
          leading: Icon(Icons.apps, color: colorScheme.primary),
          title: const Text('应用名称'),
          subtitle: const Text(appName),
        ),
        _buildAnimatedVersionTile(context),
        ListTile(
          leading: Icon(Icons.system_update, color: colorScheme.tertiary),
          title: const Text('检查更新'),
          subtitle: FutureBuilder<DateTime?>(
            future: Future.value(versionCheckService.getLastCheckTime()),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                final lastCheck = snapshot.data!;
                final now = DateTime.now();
                final difference = now.difference(lastCheck);
                if (difference.inHours < 1) {
                  return const Text('刚刚检查过');
                } else if (difference.inHours < 24) {
                  return Text('${difference.inHours} 小时前检查过');
                } else {
                  return Text('${difference.inDays} 天前检查过');
                }
              }
              return const Text('从未检查过更新');
            },
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showUpdateCheckDialog(context),
        ),
        SwitchListTile(
          secondary: Icon(Icons.update, color: colorScheme.primary),
          title: const Text('自动检查更新'),
          subtitle: const Text('应用启动时自动检查新版本'),
          value: versionCheckService.shouldAutoCheck(),
          onChanged: (value) async {
            await versionCheckService.setAutoCheckEnabled(value);
            setState(() {});
          },
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
          onLongPress: () => _showEasterEgg(context),
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

  Widget _buildAnimatedVersionTile(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _versionTapAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _versionTapScaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: _versionTapGlowAnimation.value > 0
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(
                          alpha: _versionTapGlowAnimation.value * 0.3,
                        ),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: ListTile(
              leading: Icon(Icons.verified, color: colorScheme.secondary),
              title: const Text('版本'),
              subtitle: Text(appVersion),
              onTap: () => _handleVersionTap(context),
            ),
          ),
        );
      },
    );
  }

  void _handleVersionTap(BuildContext context) {
    final appProvider = context.read<AppProvider>();
    final now = DateTime.now();

    HapticFeedback.lightImpact();

    _versionTapAnimationController.forward().then((_) {
      _versionTapAnimationController.reverse();
    });

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

      HapticFeedback.heavyImpact();

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newGodModeState ? '上帝模式已启用！' : '上帝模式已关闭'),
          backgroundColor: newGodModeState ? Colors.purple : Colors.grey[700],
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (!appProvider.godModeEnabled && _versionTapCount > 3) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '再点击 ${_godModeTapThreshold - _versionTapCount} 次启用上帝模式',
          ),
          duration: const Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showEasterEgg(BuildContext context) {
    final appProvider = context.read<AppProvider>();

    if (!appProvider.easterEggDiscovered) {
      appProvider.setEasterEggDiscovered(true);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber),
            const SizedBox(width: 8),
            const Text('恭喜发现彩蛋！'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🐰 你发现了隐藏的彩蛋功能！'),
            const SizedBox(height: 16),
            const Text('感谢使用兔可可的拼豆世界！'),
            const SizedBox(height: 8),
            Text(
              '开发者: $developer',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (!appProvider.hiddenFeaturesEnabled) ...[
              const Divider(),
              const Text('是否启用隐藏功能？'),
              const SizedBox(height: 8),
              const Text('隐藏功能包含一些实验性的开发者工具。', style: TextStyle(fontSize: 12)),
            ],
          ],
        ),
        actions: [
          if (!appProvider.hiddenFeaturesEnabled)
            TextButton(
              onPressed: () {
                appProvider.setHiddenFeaturesEnabled(true);
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('隐藏功能已启用！'),
                    backgroundColor: Colors.purple,
                  ),
                );
              },
              child: const Text('启用隐藏功能'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
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
        _buildGodModeSubSection('调试选项', Icons.bug_report, [
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
            secondary: Icon(Icons.layers, color: colorScheme.secondary),
            title: const Text('调试覆盖层'),
            subtitle: const Text('在界面上显示调试信息覆盖层'),
            value: appProvider.debugOverlayEnabled,
            onChanged: (value) {
              appProvider.setDebugOverlayEnabled(value);
            },
          ),
          SwitchListTile(
            secondary: Icon(Icons.touch_app, color: colorScheme.tertiary),
            title: const Text('显示触摸点'),
            subtitle: const Text('在屏幕上显示触摸位置'),
            value: appProvider.showTouchPoints,
            onChanged: (value) {
              appProvider.setShowTouchPoints(value);
            },
          ),
          SwitchListTile(
            secondary: Icon(Icons.border_outer, color: colorScheme.primary),
            title: const Text('显示布局边界'),
            subtitle: const Text('显示所有组件的布局边界'),
            value: appProvider.showLayoutBounds,
            onChanged: (value) {
              appProvider.setShowLayoutBounds(value);
            },
          ),
          SwitchListTile(
            secondary: Icon(Icons.palette, color: colorScheme.secondary),
            title: const Text('重绘彩虹'),
            subtitle: const Text('显示重绘区域的彩虹效果'),
            value: appProvider.showRepaintRainbow,
            onChanged: (value) {
              appProvider.setShowRepaintRainbow(value);
            },
          ),
        ]),
        const Divider(),
        _buildGodModeSubSection('性能监控', Icons.speed, [
          SwitchListTile(
            secondary: Icon(Icons.monitor_heart, color: colorScheme.primary),
            title: const Text('性能监控'),
            subtitle: const Text('显示实时性能指标'),
            value: appProvider.performanceMonitorEnabled,
            onChanged: (value) {
              appProvider.setPerformanceMonitorEnabled(value);
              setState(() {
                _showPerformanceMonitor = value;
              });
              try {
                if (value) {
                  _performanceService.startMonitoring();
                } else {
                  _performanceService.stopMonitoring();
                }
              } catch (e) {
                debugPrint('Error toggling performance monitoring: $e');
              }
            },
          ),
          SwitchListTile(
            secondary: Icon(Icons.speed, color: colorScheme.secondary),
            title: const Text('显示 FPS'),
            subtitle: const Text('在屏幕角落显示实时帧率'),
            value: appProvider.showFps,
            onChanged: (value) {
              appProvider.setShowFps(value);
            },
          ),
          SwitchListTile(
            secondary: Icon(Icons.memory, color: colorScheme.tertiary),
            title: const Text('显示内存信息'),
            subtitle: const Text('显示当前内存使用情况'),
            value: appProvider.showMemoryInfo,
            onChanged: (value) {
              appProvider.setShowMemoryInfo(value);
            },
          ),
          SwitchListTile(
            secondary: Icon(Icons.storage, color: colorScheme.primary),
            title: const Text('显示缓存统计'),
            subtitle: const Text('显示图片和数据缓存使用情况'),
            value: appProvider.showCacheStats,
            onChanged: (value) {
              appProvider.setShowCacheStats(value);
            },
          ),
        ]),
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
        _buildGodModeSubSection('画布调试', Icons.grid_on, [
          SwitchListTile(
            secondary: Icon(Icons.grid_4x4, color: colorScheme.primary),
            title: const Text('显示网格坐标'),
            subtitle: const Text('在画布上显示网格坐标信息'),
            value: appProvider.showGridCoordinates,
            onChanged: (value) {
              appProvider.setShowGridCoordinates(value);
            },
          ),
        ]),
        const Divider(),
        _buildGodModeSubSection('动画控制', Icons.animation, [
          SwitchListTile(
            secondary: Icon(
              Icons.slow_motion_video,
              color: colorScheme.primary,
            ),
            title: const Text('慢速动画'),
            subtitle: const Text('以慢速播放所有动画便于调试'),
            value: appProvider.enableSlowAnimations,
            onChanged: (value) {
              appProvider.setEnableSlowAnimations(value);
            },
          ),
          if (appProvider.enableSlowAnimations)
            ListTile(
              leading: Icon(Icons.speed, color: colorScheme.secondary),
              title: const Text('动画速度'),
              subtitle: Slider(
                value: appProvider.slowAnimationSpeed,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                label: '${(appProvider.slowAnimationSpeed * 100).toInt()}%',
                onChanged: (value) {
                  appProvider.setSlowAnimationSpeedImmediate(value);
                },
                onChangeEnd: (value) {
                  appProvider.setSlowAnimationSpeed(value);
                },
              ),
            ),
          SwitchListTile(
            secondary: Icon(Icons.animation, color: colorScheme.tertiary),
            title: const Text('全局动画开关'),
            subtitle: const Text('控制所有界面动画效果'),
            value: appProvider.animationsEnabled,
            onChanged: (value) {
              appProvider.setAnimationsEnabled(value);
            },
          ),
        ]),
        const Divider(),
        _buildGodModeSubSection('实验性功能', Icons.science, [
          SwitchListTile(
            secondary: Icon(Icons.science, color: colorScheme.primary),
            title: const Text('实验性功能'),
            subtitle: const Text('启用未稳定的新功能'),
            value: appProvider.experimentalFeaturesEnabled,
            onChanged: (value) {
              appProvider.setExperimentalFeaturesEnabled(value);
            },
          ),
          SwitchListTile(
            secondary: Icon(Icons.auto_awesome, color: colorScheme.secondary),
            title: const Text('隐藏功能'),
            subtitle: const Text('启用隐藏的开发者功能'),
            value: appProvider.hiddenFeaturesEnabled,
            onChanged: (value) {
              appProvider.setHiddenFeaturesEnabled(value);
            },
          ),
        ]),
        const Divider(),
        ListTile(
          leading: Icon(Icons.speed, color: colorScheme.primary),
          title: const Text('性能设置'),
          subtitle: const Text('GPU加速、性能等级等'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showGodModePerformanceSettings(context),
        ),
        ListTile(
          leading: Icon(Icons.developer_mode, color: colorScheme.tertiary),
          title: const Text('开发者选项'),
          subtitle: const Text('查看应用内部状态'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showDeveloperOptions(context),
        ),
        ListTile(
          leading: Icon(Icons.file_download, color: colorScheme.secondary),
          title: const Text('导出调试信息'),
          subtitle: const Text('导出应用状态和日志'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _exportDebugInfo(context),
        ),
        ListTile(
          leading: Icon(Icons.refresh, color: colorScheme.error),
          title: Text('重置上帝模式设置', style: TextStyle(color: colorScheme.error)),
          subtitle: const Text('重置所有上帝模式选项为默认值'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showResetGodModeDialog(context),
        ),
      ],
    );
  }

  Widget _buildGodModeSubSection(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  void _exportDebugInfo(BuildContext context) async {
    try {
      final appProvider = context.read<AppProvider>();
      final settingsService = SettingsService();
      await settingsService.initialize();
      final storageService = StorageService();
      await storageService.initialize();

      final debugInfo = {
        'timestamp': DateTime.now().toIso8601String(),
        'appVersion': appVersion,
        'platform': Platform.operatingSystem,
        'godModeSettings': {
          'godModeEnabled': appProvider.godModeEnabled,
          'debugModeEnabled': appProvider.debugModeEnabled,
          'performanceMonitorEnabled': appProvider.performanceMonitorEnabled,
          'experimentalFeaturesEnabled':
              appProvider.experimentalFeaturesEnabled,
          'showFps': appProvider.showFps,
          'showGridCoordinates': appProvider.showGridCoordinates,
          'showMemoryInfo': appProvider.showMemoryInfo,
          'showCacheStats': appProvider.showCacheStats,
          'showTouchPoints': appProvider.showTouchPoints,
          'showLayoutBounds': appProvider.showLayoutBounds,
          'showRepaintRainbow': appProvider.showRepaintRainbow,
          'enableSlowAnimations': appProvider.enableSlowAnimations,
          'slowAnimationSpeed': appProvider.slowAnimationSpeed,
          'hiddenFeaturesEnabled': appProvider.hiddenFeaturesEnabled,
          'easterEggDiscovered': appProvider.easterEggDiscovered,
          'debugOverlayEnabled': appProvider.debugOverlayEnabled,
        },
        'appSettings': {
          'themeMode': appProvider.themeMode.name,
          'animationsEnabled': appProvider.animationsEnabled,
          'pageTransitionsEnabled': appProvider.pageTransitionsEnabled,
          'listAnimationsEnabled': appProvider.listAnimationsEnabled,
          'buttonAnimationsEnabled': appProvider.buttonAnimationsEnabled,
          'cardAnimationsEnabled': appProvider.cardAnimationsEnabled,
        },
        'performanceSettings': {
          'gpuAcceleration': _performanceService.config.enableGpuAcceleration,
          'performanceLevel': _performanceService.config.performanceLevel.name,
          'renderEngine': PerformanceService.getImpellerStatus(),
        },
        'storageInfo': {
          'dataPath': storageService.dataDirectoryPath,
          'settingsInitialized': settingsService.containsKey('theme_mode'),
        },
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(debugInfo);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('调试信息'),
          content: SizedBox(
            width: 400,
            height: 400,
            child: SingleChildScrollView(
              child: SelectableText(
                jsonString,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: jsonString));
                ScaffoldMessenger.of(
                  dialogContext,
                ).showSnackBar(const SnackBar(content: Text('已复制到剪贴板')));
              },
              child: const Text('复制'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error exporting debug info: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导出调试信息失败: $e')));
      }
    }
  }

  void _showResetGodModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('重置上帝模式设置'),
        content: const Text('确定要重置所有上帝模式选项为默认值吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () async {
              try {
                final appProvider = this.context.read<AppProvider>();
                await appProvider.setDebugModeEnabled(false);
                await appProvider.setPerformanceMonitorEnabled(false);
                await appProvider.setExperimentalFeaturesEnabled(false);
                await appProvider.setShowFps(false);
                await appProvider.setShowGridCoordinates(false);
                await appProvider.setShowMemoryInfo(false);
                await appProvider.setShowCacheStats(false);
                await appProvider.setShowTouchPoints(false);
                await appProvider.setShowLayoutBounds(false);
                await appProvider.setShowRepaintRainbow(false);
                await appProvider.setEnableSlowAnimations(false);
                await appProvider.setSlowAnimationSpeed(0.5);
                await appProvider.setHiddenFeaturesEnabled(false);
                await appProvider.setDebugOverlayEnabled(false);

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (mounted) {
                  setState(() {
                    _showPerformanceMonitor = false;
                  });
                  ScaffoldMessenger.of(
                    this.context,
                  ).showSnackBar(const SnackBar(content: Text('上帝模式设置已重置')));
                }
              } catch (e) {
                debugPrint('Error resetting god mode settings: $e');
                if (mounted) {
                  ScaffoldMessenger.of(
                    this.context,
                  ).showSnackBar(SnackBar(content: Text('重置失败: $e')));
                }
              }
            },
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }

  void _showGodModePerformanceSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
                    try {
                      await _performanceService.setEnableGpuAcceleration(value);
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                        _showGodModePerformanceSettings(this.context);
                      }
                    } catch (e) {
                      debugPrint('Error setting GPU acceleration: $e');
                    }
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
                  Navigator.pop(dialogContext);
                  _showPerformanceLevelDialog(this.context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('渲染引擎'),
                subtitle: Text(PerformanceService.getImpellerStatus()),
              ),
              ListTile(
                leading: const Icon(Icons.speed),
                title: const Text('高性能渲染器'),
                subtitle: Text(
                  PerformanceService.getHighPerformanceRendererStatus(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('开发者选项'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '上帝模式状态',
                style: Theme.of(
                  dialogContext,
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
                '调试覆盖层',
                appProvider.debugOverlayEnabled ? '启用' : '禁用',
              ),
              _buildDeveloperInfoRow(
                '隐藏功能',
                appProvider.hiddenFeaturesEnabled ? '启用' : '禁用',
              ),
              _buildDeveloperInfoRow(
                '彩蛋已发现',
                appProvider.easterEggDiscovered ? '是' : '否',
              ),
              const Divider(),
              Text(
                '显示选项',
                style: Theme.of(
                  dialogContext,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildDeveloperInfoRow(
                'FPS 显示',
                appProvider.showFps ? '启用' : '禁用',
              ),
              _buildDeveloperInfoRow(
                '网格坐标',
                appProvider.showGridCoordinates ? '启用' : '禁用',
              ),
              _buildDeveloperInfoRow(
                '内存信息',
                appProvider.showMemoryInfo ? '启用' : '禁用',
              ),
              _buildDeveloperInfoRow(
                '缓存统计',
                appProvider.showCacheStats ? '启用' : '禁用',
              ),
              _buildDeveloperInfoRow(
                '触摸点',
                appProvider.showTouchPoints ? '启用' : '禁用',
              ),
              _buildDeveloperInfoRow(
                '布局边界',
                appProvider.showLayoutBounds ? '启用' : '禁用',
              ),
              _buildDeveloperInfoRow(
                '重绘彩虹',
                appProvider.showRepaintRainbow ? '启用' : '禁用',
              ),
              const Divider(),
              Text(
                '动画设置',
                style: Theme.of(
                  dialogContext,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildDeveloperInfoRow(
                '动画状态',
                appProvider.animationsEnabled ? '启用' : '禁用',
              ),
              _buildDeveloperInfoRow(
                '慢速动画',
                appProvider.enableSlowAnimations ? '启用' : '禁用',
              ),
              if (appProvider.enableSlowAnimations)
                _buildDeveloperInfoRow(
                  '动画速度',
                  '${(appProvider.slowAnimationSpeed * 100).toInt()}%',
                ),
              const Divider(),
              Text(
                '应用设置',
                style: Theme.of(
                  dialogContext,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildDeveloperInfoRow('主题模式', appProvider.themeMode.name),
              _buildDeveloperInfoRow(
                '页面切换动画',
                appProvider.pageTransitionsEnabled ? '启用' : '禁用',
              ),
              _buildDeveloperInfoRow(
                '列表动画',
                appProvider.listAnimationsEnabled ? '启用' : '禁用',
              ),
              const Divider(),
              Text(
                '存储信息',
                style: Theme.of(
                  dialogContext,
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
                  dialogContext,
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
              const Divider(),
              Text(
                '实验性功能',
                style: Theme.of(
                  dialogContext,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildDeveloperInfoRow(
                '实验性功能',
                appProvider.experimentalFeaturesEnabled ? '启用' : '禁用',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
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

  Color _parseColor(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  void _showGridColorPicker(BuildContext context, AppProvider appProvider) {
    final currentColor = _parseColor(appProvider.gridColor);
    Color selectedColor = currentColor;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('选择网格颜色'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(dialogContext).colorScheme.outline,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPresetColorChip(
                      dialogContext,
                      Colors.grey,
                      '灰色',
                      selectedColor,
                      (color) {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      },
                    ),
                    _buildPresetColorChip(
                      dialogContext,
                      Colors.black,
                      '黑色',
                      selectedColor,
                      (color) {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      },
                    ),
                    _buildPresetColorChip(
                      dialogContext,
                      Colors.blue,
                      '蓝色',
                      selectedColor,
                      (color) {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      },
                    ),
                    _buildPresetColorChip(
                      dialogContext,
                      Colors.red,
                      '红色',
                      selectedColor,
                      (color) {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      },
                    ),
                    _buildPresetColorChip(
                      dialogContext,
                      Colors.green,
                      '绿色',
                      selectedColor,
                      (color) {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      },
                    ),
                    _buildPresetColorChip(
                      dialogContext,
                      Colors.orange,
                      '橙色',
                      selectedColor,
                      (color) {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      },
                    ),
                    _buildPresetColorChip(
                      dialogContext,
                      Colors.purple,
                      '紫色',
                      selectedColor,
                      (color) {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      },
                    ),
                    _buildPresetColorChip(
                      dialogContext,
                      Colors.brown,
                      '棕色',
                      selectedColor,
                      (color) {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final hexColor =
                    '#${selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
                appProvider.setGridColor(hexColor);
                Navigator.pop(dialogContext);
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetColorChip(
    BuildContext context,
    Color color,
    String label,
    Color selectedColor,
    Function(Color) onSelected,
  ) {
    final isSelected = selectedColor.toARGB32() == color.toARGB32();
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onSelected(color);
        }
      },
      avatar: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1),
        ),
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
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final width = int.tryParse(widthController.text) ?? 29;
                final height = int.tryParse(heightController.text) ?? 29;
                final settingsService = SettingsService();
                await settingsService.setDefaultCanvasWidth(width);
                await settingsService.setDefaultCanvasHeight(height);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (mounted) {
                  setState(() {
                    _defaultCanvasWidth = width;
                    _defaultCanvasHeight = height;
                  });
                }
              } catch (e) {
                debugPrint('Error saving canvas size: $e');
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
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final threshold = int.tryParse(controller.text) ?? 50;
                final settingsService = SettingsService();
                await settingsService.setLowStockThreshold(threshold);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                if (mounted) {
                  setState(() {
                    _lowStockThreshold = threshold;
                  });
                }
              } catch (e) {
                debugPrint('Error saving low stock threshold: $e');
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('默认导出格式'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('PNG'),
              subtitle: const Text('适合屏幕显示和分享'),
              value: 'png',
              groupValue: _defaultExportFormat,
              onChanged: (value) async {
                if (value != null) {
                  try {
                    final settingsService = SettingsService();
                    await settingsService.setDefaultExportFormat(value);
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                    if (mounted) {
                      setState(() {
                        _defaultExportFormat = value;
                      });
                    }
                  } catch (e) {
                    debugPrint('Error saving export format: $e');
                  }
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('PDF'),
              subtitle: const Text('适合打印输出'),
              value: 'pdf',
              groupValue: _defaultExportFormat,
              onChanged: (value) async {
                if (value != null) {
                  try {
                    final settingsService = SettingsService();
                    await settingsService.setDefaultExportFormat(value);
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                    if (mounted) {
                      setState(() {
                        _defaultExportFormat = value;
                      });
                    }
                  } catch (e) {
                    debugPrint('Error saving export format: $e');
                  }
                }
              },
            ),
          ],
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

  void _showChangelog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (dialogContext) => const ChangelogDialog(),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AboutAppDialog(
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('导出所有数据'),
        content: const Text('将导出所有设计和库存数据到 JSON 文件。\n\n您可以选择保存位置。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('导出'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    String statusText = '准备导出...';
    double progress = 0.0;

    showDialog(
      context: this.context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
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

    try {
      final exportService = DataExportService();
      final success = await exportService.exportAllDataToFile(
        onProgress: (current, total, status) {
          statusText = status;
          progress = current.toDouble();
        },
      );

      if (mounted) {
        Navigator.pop(this.context);

        if (success) {
          ScaffoldMessenger.of(this.context).showSnackBar(
            const SnackBar(
              content: Text('数据导出成功'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(
            this.context,
          ).showSnackBar(const SnackBar(content: Text('导出已取消或失败')));
        }
      }
    } catch (e) {
      debugPrint('Error exporting data: $e');
      if (mounted) {
        Navigator.pop(this.context);
        ScaffoldMessenger.of(
          this.context,
        ).showSnackBar(SnackBar(content: Text('导出失败: $e')));
      }
    }
  }

  void _openDataDirectory(BuildContext context) async {
    try {
      final storageService = StorageService();
      await storageService.initialize();
      final success = await storageService.openDataDirectory();
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(
            this.context,
          ).showSnackBar(const SnackBar(content: Text('已打开数据目录')));
        } else {
          ScaffoldMessenger.of(
            this.context,
          ).showSnackBar(const SnackBar(content: Text('无法打开数据目录')));
        }
      }
    } catch (e) {
      debugPrint('Error opening data directory: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          this.context,
        ).showSnackBar(SnackBar(content: Text('打开数据目录失败: $e')));
      }
    }
  }

  void _importData(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('选择文件'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    String statusText = '准备导入...';
    double progress = 0.0;

    showDialog(
      context: this.context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
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

    try {
      final exportService = DataExportService();
      final result = await exportService.importDataFromFile(
        onProgress: (current, total, status) {
          statusText = status;
          progress = current.toDouble();
        },
      );

      if (mounted) {
        Navigator.pop(this.context);

        if (result.success) {
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(
              content: Text(result.summary),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        } else if (result.cancelled) {
          ScaffoldMessenger.of(
            this.context,
          ).showSnackBar(const SnackBar(content: Text('导入已取消')));
        } else {
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? '导入失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error importing data: $e');
      if (mounted) {
        Navigator.pop(this.context);
        ScaffoldMessenger.of(
          this.context,
        ).showSnackBar(SnackBar(content: Text('导入失败: $e')));
      }
    }
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清除缓存'),
        content: const Text('确定要清除所有缓存数据吗？这不会影响您的设计和库存数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(
                this.context,
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('重置应用'),
        content: const Text('确定要重置应用吗？这将删除所有设计、库存数据和设置，此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () async {
              try {
                Navigator.pop(dialogContext);

                final settingsService = SettingsService();
                await settingsService.clearAllSettings();

                final designStorageService = DesignStorageService();
                await designStorageService.clearAllDesigns();

                if (mounted) {
                  ScaffoldMessenger.of(
                    this.context,
                  ).showSnackBar(const SnackBar(content: Text('应用已重置')));
                }
              } catch (e) {
                debugPrint('Error resetting app: $e');
                if (mounted) {
                  ScaffoldMessenger.of(
                    this.context,
                  ).showSnackBar(SnackBar(content: Text('重置失败: $e')));
                }
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
      final allVersions = data['versions'] as List? ?? [];
      setState(() {
        _versions = allVersions.take(8).toList();
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

class _ShortcutKeyDisplay extends StatelessWidget {
  final String shortcutKey;
  final VoidCallback onTap;

  const _ShortcutKeyDisplay({required this.shortcutKey, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              shortcutKey,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.edit,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutKeyInput extends StatefulWidget {
  final String currentKey;
  final Function(String) onKeyChanged;

  const _ShortcutKeyInput({
    required this.currentKey,
    required this.onKeyChanged,
  });

  @override
  State<_ShortcutKeyInput> createState() => _ShortcutKeyInputState();
}

class _ShortcutKeyInputState extends State<_ShortcutKeyInput> {
  final FocusNode _focusNode = FocusNode();
  late String _currentKey;

  @override
  void initState() {
    super.initState();
    _currentKey = widget.currentKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          final keyLabel = event.logicalKey.keyLabel;
          if (keyLabel.isNotEmpty && keyLabel.length <= 2) {
            setState(() {
              _currentKey = keyLabel.toUpperCase();
            });
            widget.onKeyChanged(_currentKey);
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        child: Text(
          _currentKey,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class ThemeColorEditorDialog extends StatefulWidget {
  final ThemeColors initialColors;
  final Function(ThemeColors) onApply;

  const ThemeColorEditorDialog({
    super.key,
    required this.initialColors,
    required this.onApply,
  });

  @override
  State<ThemeColorEditorDialog> createState() => _ThemeColorEditorDialogState();
}

class _ThemeColorEditorDialogState extends State<ThemeColorEditorDialog> {
  late Color _primaryColor;
  late Color _secondaryColor;
  late Color _accentColor;
  late String _name;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _primaryColor = widget.initialColors.primaryColor;
    _secondaryColor = widget.initialColors.secondaryColor;
    _accentColor = widget.initialColors.accentColor;
    _name = widget.initialColors.name;
    _nameController.text = _name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('自定义主题配色'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '配色方案名称',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _name = value;
                },
              ),
              const SizedBox(height: 24),
              _buildColorPicker(
                '主色调',
                _primaryColor,
                (color) => setState(() => _primaryColor = color),
              ),
              const SizedBox(height: 16),
              _buildColorPicker(
                '次色调',
                _secondaryColor,
                (color) => setState(() => _secondaryColor = color),
              ),
              const SizedBox(height: 16),
              _buildColorPicker(
                '强调色',
                _accentColor,
                (color) => setState(() => _accentColor = color),
              ),
              const SizedBox(height: 24),
              Text('预览', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              _buildPreview(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => _saveColorScheme(),
          child: const Text('保存方案'),
        ),
        FilledButton(onPressed: _applyColors, child: const Text('应用')),
      ],
    );
  }

  Widget _buildColorPicker(
    String label,
    Color color,
    Function(Color) onChanged,
  ) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        GestureDetector(
          onTap: () => _showColorPickerDialog(color, onChanged),
          child: Container(
            width: 60,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
          ),
        ),
      ],
    );
  }

  void _showColorPickerDialog(Color initialColor, Function(Color) onChanged) {
    Color tempColor = initialColor;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('选择颜色'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ColorPickerWidget(
                initialColor: initialColor,
                onColorChanged: (color) {
                  tempColor = color;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              onChanged(tempColor);
              Navigator.pop(dialogContext);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _secondaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _primaryColor),
                  onPressed: () {},
                  child: const Text('主按钮'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryColor,
                    side: BorderSide(color: _primaryColor),
                  ),
                  onPressed: () {},
                  child: const Text('次按钮'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _applyColors() {
    final colors = ThemeColors(
      primaryColor: _primaryColor,
      secondaryColor: _secondaryColor,
      accentColor: _accentColor,
      name: _nameController.text.isNotEmpty ? _nameController.text : '自定义主题',
    );
    widget.onApply(colors);
    Navigator.pop(context);
  }

  void _saveColorScheme() {
    final appProvider = context.read<AppProvider>();
    final name = _nameController.text.isNotEmpty
        ? _nameController.text
        : '自定义方案 ${appProvider.savedColorSchemes.length + 1}';

    appProvider.saveCurrentColorScheme(name);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('配色方案已保存')));
  }
}

class ColorPickerWidget extends StatefulWidget {
  final Color initialColor;
  final Function(Color) onColorChanged;

  const ColorPickerWidget({
    super.key,
    required this.initialColor,
    required this.onColorChanged,
  });

  @override
  State<ColorPickerWidget> createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget> {
  late double _hue;
  late double _saturation;
  late double _value;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initialColor);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
  }

  Color get currentColor =>
      HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: SweepGradient(
              center: Alignment.center,
              colors: [
                HSVColor.fromAHSV(1.0, 0, 1, 1).toColor(),
                HSVColor.fromAHSV(1.0, 60, 1, 1).toColor(),
                HSVColor.fromAHSV(1.0, 120, 1, 1).toColor(),
                HSVColor.fromAHSV(1.0, 180, 1, 1).toColor(),
                HSVColor.fromAHSV(1.0, 240, 1, 1).toColor(),
                HSVColor.fromAHSV(1.0, 300, 1, 1).toColor(),
                HSVColor.fromAHSV(1.0, 360, 1, 1).toColor(),
              ],
            ),
          ),
          child: GestureDetector(
            onPanUpdate: (details) {
              final RenderBox box = context.findRenderObject() as RenderBox;
              final localPosition = box.globalToLocal(details.globalPosition);
              final centerX = box.size.width / 2;
              final centerY = box.size.height / 2;
              final dx = localPosition.dx - centerX;
              final dy = localPosition.dy - centerY;

              double angle = (atan2(dy, dx) * 180 / pi + 360) % 360;

              setState(() {
                _hue = angle.clamp(0.0, 360.0);
                widget.onColorChanged(currentColor);
              });
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('饱和度'),
            Expanded(
              child: Slider(
                value: _saturation,
                onChanged: (value) {
                  setState(() {
                    _saturation = value;
                    widget.onColorChanged(currentColor);
                  });
                },
              ),
            ),
          ],
        ),
        Row(
          children: [
            const Text('明度'),
            Expanded(
              child: Slider(
                value: _value,
                onChanged: (value) {
                  setState(() {
                    _value = value;
                    widget.onColorChanged(currentColor);
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 40,
          decoration: BoxDecoration(
            color: currentColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/logo.png',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
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
