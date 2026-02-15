import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/design_storage_service.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String appName = '兔可可的拼豆世界';
  static const String appVersion = '1.0.0';
  static const String developer = 'BunnyCC';
  static const String copyright =
      'Copyright © 2026 BunnyCC. All rights reserved.';

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
            _buildCustomizationSection(context),
            const SizedBox(height: 24),
            _buildExportSection(context),
            const SizedBox(height: 24),
            _buildDataSection(context),
            const SizedBox(height: 24),
            _buildAboutSection(context),
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

  Widget _buildCustomizationSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsService = SettingsService();

    return _SettingsCard(
      title: '自定义设置',
      icon: Icons.tune,
      children: [
        ListTile(
          leading: Icon(Icons.grid_4x4, color: colorScheme.primary),
          title: const Text('默认画布尺寸'),
          subtitle: const Text('新建设计时的默认尺寸'),
          trailing: const Text('29 × 29'),
          onTap: () => _showCanvasSizeDialog(context),
        ),
        ListTile(
          leading: Icon(Icons.inventory, color: colorScheme.secondary),
          title: const Text('低库存阈值'),
          subtitle: const Text('库存低于此数量时显示警告'),
          trailing: const Text('50'),
          onTap: () => _showLowStockDialog(context),
        ),
        ListTile(
          leading: Icon(Icons.file_download, color: colorScheme.tertiary),
          title: const Text('默认导出格式'),
          subtitle: const Text('导出设计时的默认格式'),
          trailing: const Text('PNG'),
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
          value: true,
          onChanged: (value) {},
        ),
        SwitchListTile(
          secondary: Icon(Icons.grid_on, color: colorScheme.secondary),
          title: const Text('导出时显示网格线'),
          subtitle: const Text('在导出图片中显示网格参考线'),
          value: false,
          onChanged: (value) {},
        ),
      ],
    );
  }

  Widget _buildDataSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _SettingsCard(
      title: '数据管理',
      icon: Icons.storage_outlined,
      children: [
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
          subtitle: const Text(appVersion),
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
      ],
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
    final widthController = TextEditingController(text: '29');
    final heightController = TextEditingController(text: '29');

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
            onPressed: () => Navigator.pop(context),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showLowStockDialog(BuildContext context) {
    final controller = TextEditingController(text: '50');

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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('PNG'),
              subtitle: const Text('适合屏幕显示和分享'),
              value: 'png',
              groupValue: 'png',
              onChanged: (value) => Navigator.pop(context),
            ),
            RadioListTile<String>(
              title: const Text('PDF'),
              subtitle: const Text('适合打印输出'),
              value: 'pdf',
              groupValue: 'png',
              onChanged: (value) => Navigator.pop(context),
            ),
          ],
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

  void _exportAllData(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('导出功能开发中...')));
  }

  void _importData(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('导入功能开发中...')));
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
