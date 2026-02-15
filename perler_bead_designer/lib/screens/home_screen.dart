import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bead_design.dart';
import '../providers/app_provider.dart';
import '../providers/color_palette_provider.dart';
import '../providers/inventory_provider.dart';
import '../services/design_storage_service.dart';
import '../utils/animations.dart';
import '../widgets/design_list_tile.dart';
import 'design_editor_screen.dart';
import 'image_import_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DesignStorageService _designStorageService = DesignStorageService();
  List<BeadDesign> _recentDesigns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final designs = await _designStorageService.loadAllDesigns();
      if (mounted) {
        setState(() {
          _recentDesigns = designs.take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToInventory() {
    final appProvider = context.read<AppProvider>();
    appProvider.setCurrentPageIndex(AppPage.inventory.pageIndex);
  }

  void _openDesignEditor(BeadDesign design) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DesignEditorScreen(initialDesign: design),
      ),
    );
  }

  Future<void> _createNewDesign() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _NewDesignDialog(),
    );

    if (result != null) {
      final design = BeadDesign.create(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: result['name'] as String,
        width: result['width'] as int,
        height: result['height'] as int,
      );

      await _designStorageService.saveDesign(design);
      await _loadData();

      if (mounted) {
        _openDesignEditor(design);
      }
    }
  }

  Future<void> _importImage() async {
    final result = await Navigator.of(context).push<BeadDesign>(
      MaterialPageRoute(
        builder: (context) => ImageImportScreen(
          onDesignCreated: (design) {
            Navigator.of(context).pop(design);
          },
        ),
      ),
    );

    if (result != null && mounted) {
      await _designStorageService.saveDesign(result);
      await _loadData();
      _openDesignEditor(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorPaletteProvider = context.watch<ColorPaletteProvider>();

    return Scaffold(
      body: _isLoading
          ? const Center(child: LoadingAnimation())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeHeader(context),
                    const SizedBox(height: 32),
                    _buildQuickActions(context),
                    const SizedBox(height: 32),
                    _buildRecentDesigns(context),
                    const SizedBox(height: 32),
                    _buildInventoryOverview(context, colorPaletteProvider),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FadeInWidget(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primaryContainer,
              colorScheme.primaryContainer.withValues(alpha: 0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '欢迎使用兔可可的拼豆世界',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '开始创建您的拼豆作品，释放无限创意',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.grid_on,
              size: 80,
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '快速开始',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SlideInWidget(
                delay: const Duration(milliseconds: 100),
                child: _ActionCard(
                icon: Icons.add,
                title: '新建设计',
                subtitle: '创建空白设计画布',
                color: colorScheme.primary,
                onTap: _createNewDesign,
              ),
            ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SlideInWidget(
                delay: const Duration(milliseconds: 200),
                child: _ActionCard(
                icon: Icons.image,
                title: '导入图片',
                subtitle: '从图片生成设计',
                color: colorScheme.secondary,
                onTap: _importImage,
              ),
            ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SlideInWidget(
                delay: const Duration(milliseconds: 300),
                child: _ActionCard(
                icon: Icons.inventory_2,
                title: '库存管理',
                subtitle: '管理拼豆库存',
                color: colorScheme.tertiary,
                onTap: _navigateToInventory,
              ),
            ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentDesigns(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '最近的设计',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (_recentDesigns.isNotEmpty)
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward),
                label: const Text('查看全部'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_recentDesigns.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.design_services_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无设计',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '点击上方"新建设计"开始创作',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentDesigns.length,
            itemBuilder: (context, index) {
              final design = _recentDesigns[index];
              return DesignListTile(
                design: design,
                index: index,
                onTap: () => _openDesignEditor(design),
                onDelete: () async {
                  await _designStorageService.deleteDesign(design.id);
                  await _loadData();
                },
                onExport: () {},
              );
            },
          ),
      ],
    );
  }

  Widget _buildInventoryOverview(
    BuildContext context,
    ColorPaletteProvider colorPaletteProvider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final inventoryProvider = context.watch<InventoryProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '库存概览',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _navigateToInventory,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('管理库存'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.palette, color: colorScheme.primary),
                      const SizedBox(height: 12),
                      Text(
                        '${colorPaletteProvider.totalColorCount}',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '可用颜色',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.inventory_2, color: colorScheme.secondary),
                      const SizedBox(height: 12),
                      Text(
                        '${inventoryProvider.colorCount}',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '库存颜色',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber, color: colorScheme.tertiary),
                      const SizedBox(height: 12),
                      Text(
                        '${inventoryProvider.lowStockItems.length}',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '库存不足',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewDesignDialog extends StatefulWidget {
  const _NewDesignDialog();

  @override
  State<_NewDesignDialog> createState() => _NewDesignDialogState();
}

class _NewDesignDialogState extends State<_NewDesignDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: '新建设计');
  final _widthController = TextEditingController(text: '29');
  final _heightController = TextEditingController(text: '29');
  int _width = 29;
  int _height = 29;

  final List<int> _presetSizes = [15, 29, 35, 50, 100];

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _updateSize(int size) {
    setState(() {
      _width = size;
      _height = size;
      _widthController.text = size.toString();
      _heightController.text = size.toString();
    });
  }

  void _onWidthChanged(String value) {
    final parsed = int.tryParse(value);
    if (parsed != null && parsed > 0 && parsed <= 500) {
      setState(() => _width = parsed);
    }
  }

  void _onHeightChanged(String value) {
    final parsed = int.tryParse(value);
    if (parsed != null && parsed > 0 && parsed <= 500) {
      setState(() => _height = parsed);
    }
  }

  bool _validateAndSubmit() {
    if (!_formKey.currentState!.validate()) return false;

    final name = _nameController.text.trim();
    final width = int.tryParse(_widthController.text) ?? 29;
    final height = int.tryParse(_heightController.text) ?? 29;

    Navigator.of(context).pop({
      'name': name.isEmpty ? '新建设计' : name,
      'width': width.clamp(1, 500),
      'height': height.clamp(1, 500),
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.add_box_outlined, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Text('新建设计'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '设计名称',
                  hintText: '输入设计名称',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }
                  if (value.trim().length > 50) {
                    return '名称不能超过50个字符';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                '预设尺寸',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetSizes.map((size) {
                  final isSelected = _width == size && _height == size;
                  return ChoiceChip(
                    label: Text('$size×$size'),
                    selected: isSelected,
                    selectedColor: colorScheme.primaryContainer,
                    onSelected: (selected) {
                      if (selected) _updateSize(size);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                '自定义尺寸',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _widthController,
                      decoration: const InputDecoration(
                        labelText: '宽度',
                        suffixText: '格',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: _onWidthChanged,
                      validator: (value) {
                        final parsed = int.tryParse(value ?? '');
                        if (parsed == null || parsed <= 0) {
                          return '请输入有效数值';
                        }
                        if (parsed > 500) {
                          return '最大500格';
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.close, color: colorScheme.outline),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      decoration: const InputDecoration(
                        labelText: '高度',
                        suffixText: '格',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: _onHeightChanged,
                      validator: (value) {
                        final parsed = int.tryParse(value ?? '');
                        if (parsed == null || parsed <= 0) {
                          return '请输入有效数值';
                        }
                        if (parsed > 500) {
                          return '最大500格';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: colorScheme.outline,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '画布将有 $_width×$_height = ${_width * _height} 个格子',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          onPressed: _validateAndSubmit,
          icon: const Icon(Icons.add),
          label: const Text('创建设计'),
        ),
      ],
    );
  }
}
