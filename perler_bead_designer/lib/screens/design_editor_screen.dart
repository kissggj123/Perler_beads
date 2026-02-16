import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/design_editor_provider.dart';
import '../providers/app_provider.dart';
import '../widgets/bead_canvas_widget.dart';
import '../widgets/color_picker_panel.dart';
import '../widgets/bead_statistics_panel.dart';
import '../widgets/tool_bar_widget.dart';
import '../widgets/assembly_guide_widget.dart';
import '../services/settings_service.dart';
import '../services/gpu_animation_service.dart';
import '../services/assembly_guide_service.dart';
import '../utils/platform_utils.dart';

class DesignEditorScreen extends StatelessWidget {
  final BeadDesign? initialDesign;

  const DesignEditorScreen({super.key, this.initialDesign});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DesignEditorProvider(),
      child: _DesignEditorContent(initialDesign: initialDesign),
    );
  }
}

class _DesignEditorContent extends StatefulWidget {
  final BeadDesign? initialDesign;

  const _DesignEditorContent({this.initialDesign});

  @override
  State<_DesignEditorContent> createState() => _DesignEditorContentState();
}

class _DesignEditorContentState extends State<_DesignEditorContent>
    with TickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  final AssemblyGuideService _assemblyService = AssemblyGuideService();
  final GpuAnimationService _gpuAnimationService = GpuAnimationService();
  bool _showAssemblyGuide = false;
  late AnimationController _assemblyAnimationController;

  @override
  void initState() {
    super.initState();
    _assemblyAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..addStatusListener(_onAssemblyAnimationStatus);
    _gpuAnimationService.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeEditor();
      _focusNode.requestFocus();
    });
  }

  void _onAssemblyAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _assemblyService.isPlaying) {
      _assemblyService.nextStep();
      if (_assemblyService.isPlaying) {
        _assemblyAnimationController.reset();
        _assemblyAnimationController.forward();
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _assemblyAnimationController.dispose();
    _assemblyService.dispose();
    final provider = context.read<DesignEditorProvider>();
    provider.stopAutoSaveTimer();
    super.dispose();
  }

  void _initializeEditor() {
    final editorProvider = context.read<DesignEditorProvider>();
    final settingsService = SettingsService();
    editorProvider.loadShortcutSettings(settingsService);
    editorProvider.loadEditorSettings(settingsService);
    editorProvider.startAutoSaveTimer();
    if (widget.initialDesign != null) {
      editorProvider.loadDesignDirect(widget.initialDesign!);
    } else {
      _showNewDesignDialog();
    }
  }

  void _handleKeyEvent(KeyEvent event, DesignEditorProvider provider) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;
    final keyLabel = key.keyLabel.toUpperCase();
    final shortcuts = provider.shortcutSettings;

    if (keyLabel == shortcuts.moveUp ||
        keyLabel == shortcuts.moveDown ||
        keyLabel == shortcuts.moveLeft ||
        keyLabel == shortcuts.moveRight ||
        keyLabel == shortcuts.zoomIn ||
        keyLabel == shortcuts.zoomOut ||
        keyLabel == shortcuts.resetView) {
      provider.handleKeyboardMove(keyLabel);
      return;
    }

    final isCtrlOrCmdPressed =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

    if (isCtrlOrCmdPressed) {
      if (keyLabel == shortcuts.undo) {
        if (isShiftPressed) {
          provider.redo();
        } else {
          provider.undo();
        }
        return;
      }
      if (keyLabel == shortcuts.redo) {
        provider.redo();
        return;
      }
      if (keyLabel == shortcuts.save) {
        provider.saveDesign();
        return;
      }
      if (keyLabel == 'C') {
        if (provider.hasSelection) {
          provider.copySelection();
        } else {
          provider.copyAll();
        }
        return;
      }
      if (keyLabel == 'V') {
        if (provider.hasClipboard) {
          provider.pasteToCenter();
        }
        return;
      }
      if (keyLabel == 'X') {
        if (provider.hasSelection) {
          provider.copySelection();
          provider.deleteSelection();
        }
        return;
      }
      if (keyLabel == 'A') {
        provider.selectAll();
        return;
      }
    } else {
      switch (key) {
        case LogicalKeyboardKey.keyD:
          provider.setToolMode(ToolMode.draw);
          break;
        case LogicalKeyboardKey.keyE:
          provider.setToolMode(ToolMode.erase);
          break;
        case LogicalKeyboardKey.keyF:
          provider.setToolMode(ToolMode.fill);
          break;
        case LogicalKeyboardKey.keyS:
          provider.setToolMode(ToolMode.select);
          break;
        case LogicalKeyboardKey.keyG:
          provider.toggleGrid();
          break;
        case LogicalKeyboardKey.keyC:
          provider.toggleCoordinates();
          break;
        case LogicalKeyboardKey.delete:
        case LogicalKeyboardKey.backspace:
          if (provider.hasSelection) {
            provider.deleteSelection();
          }
          break;
        case LogicalKeyboardKey.escape:
          provider.clearSelection();
          break;
      }
    }
  }

  void _showNewDesignDialog() {
    final nameController = TextEditingController(text: '新设计');
    final widthController = TextEditingController(text: '29');
    final heightController = TextEditingController(text: '29');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('新建设计'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '设计名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
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
            const SizedBox(height: 8),
            Text(
              '常用尺寸: 29×29, 50×50, 100×100',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final width = int.tryParse(widthController.text) ?? 29;
              final height = int.tryParse(heightController.text) ?? 29;

              if (name.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('请输入设计名称')));
                return;
              }

              if (width <= 0 || height <= 0 || width > 500 || height > 500) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('尺寸必须在 1-500 之间')));
                return;
              }

              context.read<DesignEditorProvider>().createNewDesign(
                name: name,
                width: width,
                height: height,
              );
              Navigator.of(dialogContext).pop();
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        final provider = context.read<DesignEditorProvider>();
        _handleKeyEvent(event, provider);
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _handleBackButton().then((shouldPop) {
            if (shouldPop && context.mounted) {
              Navigator.of(context).pop();
            }
          });
        },
        child: Scaffold(
          body: Column(
            children: [
              _buildAppBar(context),
              const ToolBarWidget(),
              Expanded(child: _buildMainContent(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _handleBackButton()) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            tooltip: '返回',
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Consumer<DesignEditorProvider>(
              builder: (context, provider, _) {
                return Row(
                  children: [
                    const SizedBox(width: 16),
                    Icon(
                      Icons.grid_on,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '拼豆设计编辑器',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (provider.isDirty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '未保存',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    _buildAutoSaveIndicator(context, provider),
                  ],
                );
              },
            ),
          ),
          _buildAppBarActions(context),
        ],
      ),
    );
  }

  Widget _buildAppBarActions(BuildContext context) {
    return Consumer<DesignEditorProvider>(
      builder: (context, provider, _) {
        return Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.view_in_ar,
                color: _showAssemblyGuide
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              onPressed: provider.hasDesign
                  ? () => _toggleAssemblyGuide(provider)
                  : null,
              tooltip: '3D拼装动画',
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _showSettingsDialog(context, provider),
              tooltip: '设置',
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: provider.hasDesign
                  ? () async {
                      final success = await provider.saveDesign();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? '设计已保存' : '保存失败'),
                            backgroundColor: success
                                ? Colors.green
                                : Colors.red,
                          ),
                        );
                        if (success) {
                          _gpuAnimationService.emitCompletionParticles(
                            position: Offset(
                              MediaQuery.of(context).size.width / 2,
                              100,
                            ),
                            color: Colors.green,
                          );
                        }
                      }
                    }
                  : null,
              tooltip: '保存 (${PlatformUtils.ctrlKey}+S)',
            ),
            const SizedBox(width: 8),
          ],
        );
      },
    );
  }

  void _toggleAssemblyGuide(DesignEditorProvider provider) {
    setState(() {
      _showAssemblyGuide = !_showAssemblyGuide;
      if (_showAssemblyGuide && provider.currentDesign != null) {
        _assemblyService.generateAssemblySteps(provider.currentDesign!);
      } else {
        _assemblyService.stop();
      }
    });
  }

  Widget _buildMainContent(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 250, child: ColorPickerPanel()),
        Expanded(child: _buildCanvasArea(context)),
        const SizedBox(width: 280, child: BeadStatisticsPanel()),
      ],
    );
  }

  Widget _buildCanvasArea(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Consumer2<DesignEditorProvider, AppProvider>(
        builder: (context, provider, appProvider, _) {
          if (!provider.hasDesign) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_box_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '创建或加载一个设计',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _showNewDesignDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('新建设计'),
                  ),
                ],
              ),
            );
          }

          if (_showAssemblyGuide) {
            return _buildAssemblyGuideView(context, provider, appProvider);
          }

          return ParticleOverlay(
            enabled: appProvider.animationsEnabled,
            child: Column(
              children: [
                _buildCurrentColorIndicator(context, provider),
                Expanded(child: Center(child: BeadCanvasWidget())),
                _buildZoomControls(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAssemblyGuideView(
    BuildContext context,
    DesignEditorProvider provider,
    AppProvider appProvider,
  ) {
    return AnimatedBuilder(
      animation: _assemblyAnimationController,
      builder: (context, _) {
        return Column(
          children: [
            _buildAssemblyGuideHeader(context, provider),
            Expanded(
              child: AssemblyGuideWidget(
                design: provider.currentDesign!,
                cellSize: appProvider.cellSize,
                currentStep: _assemblyService.currentStep,
                isPlaying: _assemblyService.isPlaying,
                animationSpeed: _assemblyService.animationSpeed,
                showSameColorHint: _assemblyService.showSameColorHint,
                onPlay: () {
                  if (_assemblyService.currentStepIndex < 0) {
                    _assemblyService.start();
                  } else {
                    _assemblyService.resume();
                  }
                  _assemblyAnimationController.reset();
                  _assemblyAnimationController.forward();
                },
                onPause: () {
                  _assemblyAnimationController.stop();
                  _assemblyService.pause();
                },
                onReset: () {
                  _assemblyAnimationController.reset();
                  _assemblyService.reset();
                },
                onNextStep: () {
                  _assemblyService.nextStep();
                },
                onPreviousStep: () {
                  _assemblyService.previousStep();
                },
                onSpeedChanged: (speed) {
                  _assemblyService.setAnimationSpeed(speed);
                  _assemblyAnimationController.duration = Duration(
                    milliseconds: (500 / speed).round(),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAssemblyGuideHeader(
    BuildContext context,
    DesignEditorProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.view_in_ar,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 8),
          Text(
            '3D拼装动画模式',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            icon: const Icon(Icons.close),
            label: const Text('退出'),
            onPressed: () => _toggleAssemblyGuide(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentColorIndicator(
    BuildContext context,
    DesignEditorProvider provider,
  ) {
    final selectedColor = provider.selectedColor;
    final isPreviewMode = provider.isPreviewMode;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          if (isPreviewMode) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.preview,
                    size: 18,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '预览模式',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '点击拼豆查看颜色信息',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else ...[
            Text('当前颜色:', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(width: 12),
            if (selectedColor != null) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: selectedColor.color,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedColor.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${selectedColor.code} · ${selectedColor.hex}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ] else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '未选择颜色',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getToolModeText(provider.toolMode),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
          const Spacer(),
          _buildHistoryIndicator(context, provider),
        ],
      ),
    );
  }

  Widget _buildHistoryIndicator(
    BuildContext context,
    DesignEditorProvider provider,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.history,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          '${provider.undoCount}/${provider.redoCount}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAutoSaveIndicator(
    BuildContext context,
    DesignEditorProvider provider,
  ) {
    final isAutoSaving = provider.isAutoSaving;
    final statusText = provider.getAutoSaveStatusText();
    final autoSaveInterval = provider.autoSaveInterval;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAutoSaving
            ? Theme.of(context).colorScheme.tertiaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAutoSaving)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
            )
          else
            Icon(
              Icons.save_outlined,
              size: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isAutoSaving
                  ? Theme.of(context).colorScheme.onTertiaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (autoSaveInterval > 0 && !isAutoSaving) ...[
            const SizedBox(width: 4),
            Text(
              '(${autoSaveInterval}s)',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getToolModeText(ToolMode mode) {
    switch (mode) {
      case ToolMode.draw:
        return '绘制模式 (D)';
      case ToolMode.erase:
        return '擦除模式 (E)';
      case ToolMode.fill:
        return '填充模式 (F)';
      case ToolMode.select:
        return '选区模式 (S)';
    }
  }

  Widget _buildZoomControls(
    BuildContext context,
    DesignEditorProvider provider,
  ) {
    final shortcuts = provider.shortcutSettings;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '快捷键: ${shortcuts.moveUp}${shortcuts.moveDown}${shortcuts.moveLeft}${shortcuts.moveRight}-移动 | ${shortcuts.zoomIn}/${shortcuts.zoomOut}-缩放 | ${shortcuts.resetView}-重置视图 | D-绘制 E-擦除 F-填充 S-选区 G-网格 C-坐标 | ${PlatformUtils.ctrlKey}+C-复制 ${PlatformUtils.ctrlKey}+V-粘贴 ${PlatformUtils.ctrlKey}+X-剪切 ${PlatformUtils.ctrlKey}+A-全选 | ${PlatformUtils.ctrlKey}+${shortcuts.undo}-撤销 ${PlatformUtils.ctrlKey}+${shortcuts.redo}-重做 ${PlatformUtils.ctrlKey}+${shortcuts.save}-保存 | 鼠标中键拖动-平移',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(
    BuildContext context,
    DesignEditorProvider provider,
  ) {
    final widthController = TextEditingController(
      text: provider.width.toString(),
    );
    final heightController = TextEditingController(
      text: provider.height.toString(),
    );
    final nameController = TextEditingController(
      text: provider.currentDesign?.name ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设计设置'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '设计名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
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
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  icon: const Icon(Icons.keyboard),
                  label: const Text('自定义快捷键设置'),
                  onPressed: () =>
                      _showShortcutSettingsDialog(context, provider),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final width =
                  int.tryParse(widthController.text) ?? provider.width;
              final height =
                  int.tryParse(heightController.text) ?? provider.height;

              if (name.isNotEmpty) {
                provider.renameDesign(name);
              }
              if (width > 0 && height > 0 && width <= 500 && height <= 500) {
                provider.resizeDesign(width, height);
              }
              Navigator.of(context).pop();
            },
            child: const Text('应用'),
          ),
        ],
      ),
    );
  }

  void _showShortcutSettingsDialog(
    BuildContext context,
    DesignEditorProvider provider,
  ) {
    final currentSettings = provider.shortcutSettings;
    final controllers = {
      'undo': TextEditingController(text: currentSettings.undo),
      'redo': TextEditingController(text: currentSettings.redo),
      'save': TextEditingController(text: currentSettings.save),
      'moveUp': TextEditingController(text: currentSettings.moveUp),
      'moveDown': TextEditingController(text: currentSettings.moveDown),
      'moveLeft': TextEditingController(text: currentSettings.moveLeft),
      'moveRight': TextEditingController(text: currentSettings.moveRight),
      'zoomIn': TextEditingController(text: currentSettings.zoomIn),
      'zoomOut': TextEditingController(text: currentSettings.zoomOut),
      'resetView': TextEditingController(text: currentSettings.resetView),
    };

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('快捷键设置'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('点击输入框后按下新按键即可更改快捷键'),
                const SizedBox(height: 8),
                Text(
                  '撤销/重做/保存需要配合 ${PlatformUtils.ctrlKey} 使用',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                _buildShortcutRow(dialogContext, '撤销', controllers['undo']!),
                _buildShortcutRow(dialogContext, '重做', controllers['redo']!),
                _buildShortcutRow(dialogContext, '保存', controllers['save']!),
                const Divider(),
                _buildShortcutRow(dialogContext, '上移', controllers['moveUp']!),
                _buildShortcutRow(
                  dialogContext,
                  '下移',
                  controllers['moveDown']!,
                ),
                _buildShortcutRow(
                  dialogContext,
                  '左移',
                  controllers['moveLeft']!,
                ),
                _buildShortcutRow(
                  dialogContext,
                  '右移',
                  controllers['moveRight']!,
                ),
                const Divider(),
                _buildShortcutRow(dialogContext, '放大', controllers['zoomIn']!),
                _buildShortcutRow(dialogContext, '缩小', controllers['zoomOut']!),
                _buildShortcutRow(
                  dialogContext,
                  '重置视图',
                  controllers['resetView']!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              for (final controller in controllers.values) {
                controller.dispose();
              }
              Navigator.of(dialogContext).pop();
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final defaults = ShortcutSettings.getDefaults();
              controllers['undo']!.text = defaults['undo']!;
              controllers['redo']!.text = defaults['redo']!;
              controllers['save']!.text = defaults['save']!;
              controllers['moveUp']!.text = defaults['moveUp']!;
              controllers['moveDown']!.text = defaults['moveDown']!;
              controllers['moveLeft']!.text = defaults['moveLeft']!;
              controllers['moveRight']!.text = defaults['moveRight']!;
              controllers['zoomIn']!.text = defaults['zoomIn']!;
              controllers['zoomOut']!.text = defaults['zoomOut']!;
              controllers['resetView']!.text = defaults['resetView']!;
            },
            child: const Text('恢复默认'),
          ),
          FilledButton(
            onPressed: () async {
              final newSettings = ShortcutSettings(
                undo: controllers['undo']!.text.toUpperCase(),
                redo: controllers['redo']!.text.toUpperCase(),
                save: controllers['save']!.text.toUpperCase(),
                moveUp: controllers['moveUp']!.text.toUpperCase(),
                moveDown: controllers['moveDown']!.text.toUpperCase(),
                moveLeft: controllers['moveLeft']!.text.toUpperCase(),
                moveRight: controllers['moveRight']!.text.toUpperCase(),
                zoomIn: controllers['zoomIn']!.text.toUpperCase(),
                zoomOut: controllers['zoomOut']!.text.toUpperCase(),
                resetView: controllers['resetView']!.text.toUpperCase(),
              );
              await provider.updateShortcutSettings(newSettings);
              for (final controller in controllers.values) {
                controller.dispose();
              }
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutRow(
    BuildContext context,
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label)),
          const SizedBox(width: 16),
          Expanded(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                if (event is KeyDownEvent) {
                  final keyLabel = event.logicalKey.keyLabel;
                  if (keyLabel.isNotEmpty && keyLabel.length <= 2) {
                    controller.text = keyLabel.toUpperCase();
                  }
                }
              },
              child: TextField(
                controller: controller,
                readOnly: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  hintText: '点击后按键',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _handleBackButton() async {
    final provider = context.read<DesignEditorProvider>();

    if (!provider.isDirty) return true;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('未保存的更改'),
        content: const Text('您有未保存的更改，是否保存？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('discard'),
            child: const Text('不保存'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final success = await provider.saveDesign();
              if (context.mounted) {
                Navigator.of(context).pop(success ? 'save' : 'cancel');
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result == 'discard') {
      return true;
    } else if (result == 'save') {
      return true;
    }
    return false;
  }
}
