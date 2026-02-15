import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/image_processing_provider.dart';
import '../providers/color_palette_provider.dart';
import '../models/bead_design.dart';
import '../models/color_palette.dart';
import '../services/image_processing_service.dart'
    show DitheringMode, AlgorithmStyle, AlgorithmStyleExtension;
import '../widgets/image_preview_widget.dart';
import '../widgets/size_settings_widget.dart';

class ImageImportScreen extends StatefulWidget {
  final void Function(BeadDesign design)? onDesignCreated;

  const ImageImportScreen({super.key, this.onDesignCreated});

  @override
  State<ImageImportScreen> createState() => _ImageImportScreenState();
}

class _ImageImportScreenState extends State<ImageImportScreen> {
  final TextEditingController _designNameController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _designNameController.text =
        '导入设计 ${DateTime.now().millisecondsSinceEpoch % 10000}';
  }

  @override
  void dispose() {
    _designNameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ImageProcessingProvider(),
      child: Consumer<ImageProcessingProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: _buildAppBar(context, provider),
            body: _buildBody(context, provider),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ImageProcessingProvider provider,
  ) {
    return AppBar(
      title: const Text('导入图片'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        if (provider.hasImage)
          TextButton.icon(
            onPressed: provider.isProcessing
                ? null
                : () => _processAndNavigate(context, provider),
            icon: const Icon(Icons.check),
            label: const Text('生成设计'),
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, ImageProcessingProvider provider) {
    if (provider.state == ProcessingState.error) {
      return _buildErrorView(context, provider);
    }

    if (!provider.hasImage) {
      return _buildEmptyView(context, provider);
    }

    return _buildContentView(context, provider);
  }

  Widget _buildEmptyView(
    BuildContext context,
    ImageProcessingProvider provider,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.image_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '选择一张图片开始',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '图片将被转换为拼豆设计图案',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '支持 JPG、PNG、GIF 等常见格式',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: () => provider.selectImage(),
              icon: const Icon(Icons.photo_library),
              label: const Text('选择图片'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(
    BuildContext context,
    ImageProcessingProvider provider,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.errorContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '出错了',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              provider.errorMessage ?? '未知错误',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    provider.clearError();
                    Navigator.of(context).pop();
                  },
                  child: const Text('返回'),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: () {
                    provider.clearError();
                    provider.selectImage();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentView(
    BuildContext context,
    ImageProcessingProvider provider,
  ) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStepIndicator(context, provider),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final paletteProvider = context
                        .watch<ColorPaletteProvider>();
                    return ImagePreviewWidget(
                      originalImage: provider.flutterOriginalImage,
                      previewImage: provider.flutterPreviewImage,
                      outputWidth: provider.outputWidth,
                      outputHeight: provider.outputHeight,
                      isLoading: provider.state == ProcessingState.loading,
                      colorPalette: ColorPalette(
                        id: 'current',
                        name: '当前调色板',
                        colors: paletteProvider.allColors,
                      ),
                      cellColorProvider: (x, y) {
                        return provider.getPixelColor(x, y);
                      },
                      onCellTap: (cellInfo) {
                        ColorInfoDialog.show(context, cellInfo);
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                SizeSettingsWidget(
                  width: provider.outputWidth,
                  height: provider.outputHeight,
                  maintainAspectRatio: provider.maintainAspectRatio,
                  onWidthChanged: provider.setOutputWidth,
                  onHeightChanged: provider.setOutputHeight,
                  onMaintainAspectRatioChanged: provider.setMaintainAspectRatio,
                  onPresetSelected: provider.applyPreset,
                ),
                const SizedBox(height: 16),
                _buildImageAdjustmentsCard(context, provider),
                const SizedBox(height: 16),
                _buildDesignNameInput(context),
                const SizedBox(height: 16),
                _buildColorPaletteSelector(context),
                if (provider.isProcessing) ...[
                  const SizedBox(height: 16),
                  _buildProgressIndicator(provider),
                ],
                const SizedBox(height: 24),
                _buildActionButtons(context, provider),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(
    BuildContext context,
    ImageProcessingProvider provider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            _buildStepItem(
              context,
              number: 1,
              title: '选择图片',
              isCompleted: provider.hasImage,
              isActive: true,
            ),
            Expanded(
              child: Container(
                height: 2,
                color: provider.hasImage
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            _buildStepItem(
              context,
              number: 2,
              title: '调整设置',
              isCompleted: false,
              isActive: provider.hasImage,
            ),
            Expanded(
              child: Container(
                height: 2,
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            _buildStepItem(
              context,
              number: 3,
              title: '生成设计',
              isCompleted: provider.resultDesign != null,
              isActive: provider.hasImage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(
    BuildContext context, {
    required int number,
    required String title,
    required bool isCompleted,
    required bool isActive,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted
                ? colorScheme.primary
                : isActive
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, color: colorScheme.onPrimary, size: 18)
                : Text(
                    number.toString(),
                    style: TextStyle(
                      color: isActive
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.outline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isActive ? colorScheme.onSurface : colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildImageAdjustmentsCard(
    BuildContext context,
    ImageProcessingProvider provider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune),
                    const SizedBox(width: 8),
                    Text(
                      '图像调整',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                if (provider.brightness != 0 ||
                    provider.contrast != 0 ||
                    provider.saturation != 0)
                  TextButton(
                    onPressed: provider.resetAdjustments,
                    child: const Text('重置'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSlider(
              context,
              label: '亮度',
              value: provider.brightness,
              min: -1.0,
              max: 1.0,
              icon: Icons.brightness_6,
              onChanged: provider.setBrightness,
            ),
            const SizedBox(height: 12),
            _buildSlider(
              context,
              label: '对比度',
              value: provider.contrast,
              min: -1.0,
              max: 1.0,
              icon: Icons.contrast,
              onChanged: provider.setContrast,
            ),
            const SizedBox(height: 12),
            _buildSlider(
              context,
              label: '饱和度',
              value: provider.saturation,
              min: -1.0,
              max: 1.0,
              icon: Icons.palette_outlined,
              onChanged: provider.setSaturation,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('算法风格', style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.5),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AlgorithmStyle>(
                  value: provider.algorithmStyle,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down),
                  style: Theme.of(context).textTheme.bodyMedium,
                  items: AlgorithmStyle.values.map((style) {
                    return DropdownMenuItem(
                      value: style,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            style.displayName,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            style.description,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (style) {
                    if (style != null) {
                      provider.setAlgorithmStyle(style);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text('抖动算法', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('无'),
                  selected: provider.ditheringMode == DitheringMode.none,
                  onSelected: (_) =>
                      provider.setDitheringMode(DitheringMode.none),
                ),
                ChoiceChip(
                  label: const Text('Floyd-Steinberg'),
                  selected:
                      provider.ditheringMode == DitheringMode.floydSteinberg,
                  onSelected: (_) =>
                      provider.setDitheringMode(DitheringMode.floydSteinberg),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required IconData icon,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: 20,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 50,
          child: Text(
            (value * 100).toStringAsFixed(0),
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesignNameInput(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit),
                const SizedBox(width: 8),
                Text('设计名称', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _designNameController,
              decoration: const InputDecoration(
                hintText: '输入设计名称',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPaletteSelector(BuildContext context) {
    final paletteProvider = context.watch<ColorPaletteProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.palette),
                const SizedBox(width: 8),
                Text('颜色库', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${paletteProvider.totalColorCount} 种颜色',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '图片将被匹配到最接近的拼豆颜色',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: paletteProvider.allColors.length > 30
                    ? 30
                    : paletteProvider.allColors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 4),
                itemBuilder: (context, index) {
                  final color = paletteProvider.allColors[index];
                  return Tooltip(
                    message: '${color.name}\n${color.code}',
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (paletteProvider.totalColorCount > 30)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '还有 ${paletteProvider.totalColorCount - 30} 种颜色...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ImageProcessingProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: provider.progress,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '正在处理图片...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(value: provider.progress),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${(provider.progress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ImageProcessingProvider provider,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: provider.isProcessing
                ? null
                : () => provider.selectImage(),
            icon: const Icon(Icons.refresh),
            label: const Text('更换图片'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: FilledButton.icon(
            onPressed: provider.isProcessing
                ? null
                : () => _processAndNavigate(context, provider),
            icon: provider.isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text('生成设计'),
          ),
        ),
      ],
    );
  }

  Future<void> _processAndNavigate(
    BuildContext context,
    ImageProcessingProvider provider,
  ) async {
    final paletteProvider = context.read<ColorPaletteProvider>();
    final palette = ColorPalette(
      id: 'current',
      name: '当前调色板',
      colors: paletteProvider.allColors,
    );

    final design = await provider.processImage(
      palette,
      designName: _designNameController.text.trim().isEmpty
          ? '导入设计'
          : _designNameController.text.trim(),
    );

    if (design != null && mounted) {
      if (widget.onDesignCreated != null) {
        widget.onDesignCreated!(design);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('设计已生成: ${design.width}×${design.height}'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop(design);
    } else if (mounted && provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
