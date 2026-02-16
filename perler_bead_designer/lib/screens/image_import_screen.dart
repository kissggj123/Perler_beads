import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/image_processing_provider.dart';
import '../providers/color_palette_provider.dart';
import '../models/bead_design.dart';
import '../models/color_palette.dart';
import '../services/image_processing_service.dart'
    show
        DitheringMode,
        AlgorithmStyle,
        AlgorithmStyleExtension,
        ExperimentalEffect,
        ExperimentalEffectExtension,
        BackgroundRemovalMode,
        MaskEditTool;
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
  late final ImageProcessingProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ImageProcessingProvider();
    _designNameController.text =
        '导入设计 ${DateTime.now().millisecondsSinceEpoch % 10000}';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.initializeGpuProcessor();
    });
  }

  @override
  void dispose() {
    _designNameController.dispose();
    _scrollController.dispose();
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
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
        if (provider.warningMessage != null)
          _buildWarningBanner(context, provider),
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
                  recommendedSize: provider.recommendedSize,
                  alternativeSizes: provider.alternativeSizes,
                  onApplyRecommendedSize: provider.applyRecommendedSize,
                ),
                const SizedBox(height: 16),
                _buildBackgroundRemovalCard(context, provider),
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

  Widget _buildWarningBanner(
    BuildContext context,
    ImageProcessingProvider provider,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: Theme.of(context).colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              provider.warningMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: provider.clearWarning,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: Theme.of(context).colorScheme.onTertiaryContainer,
          ),
        ],
      ),
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
                    provider.saturation != 0 ||
                    provider.experimentalEffect != ExperimentalEffect.none)
                  TextButton(
                    onPressed: provider.resetAdjustments,
                    child: const Text('重置'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildGpuAndAutoAdjustSection(context, provider),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _buildOptimizedSlider(
              context,
              label: '亮度',
              value: provider.brightness,
              min: -1.0,
              max: 1.0,
              icon: Icons.brightness_6,
              provider: provider,
              onValueChanged: (value) =>
                  provider.setBrightness(value, generatePreview: false),
              onPreviewGenerate: (value) => provider.setBrightness(value),
            ),
            const SizedBox(height: 12),
            _buildOptimizedSlider(
              context,
              label: '对比度',
              value: provider.contrast,
              min: -1.0,
              max: 1.0,
              icon: Icons.contrast,
              provider: provider,
              onValueChanged: (value) =>
                  provider.setContrast(value, generatePreview: false),
              onPreviewGenerate: (value) => provider.setContrast(value),
            ),
            const SizedBox(height: 12),
            _buildOptimizedSlider(
              context,
              label: '饱和度',
              value: provider.saturation,
              min: -1.0,
              max: 1.0,
              icon: Icons.palette_outlined,
              provider: provider,
              onValueChanged: (value) =>
                  provider.setSaturation(value, generatePreview: false),
              onPreviewGenerate: (value) => provider.setSaturation(value),
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
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _buildExperimentalEffectsSection(context, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildExperimentalEffectsSection(
    BuildContext context,
    ImageProcessingProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.science,
              size: 20,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            const SizedBox(width: 8),
            Text(
              '实验性效果',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Beta',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '尝试各种艺术效果，为你的拼豆设计增添创意',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: ExperimentalEffect.values.length,
            itemBuilder: (context, index) {
              final effect = ExperimentalEffect.values[index];
              final isSelected = provider.experimentalEffect == effect;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: () => provider.setExperimentalEffect(effect),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 80,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.tertiaryContainer
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.tertiary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          effect.icon,
                          size: 28,
                          color: isSelected
                              ? Theme.of(context).colorScheme.tertiary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          effect.displayName,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: isSelected
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onTertiaryContainer
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                fontWeight: isSelected ? FontWeight.bold : null,
                              ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (provider.experimentalEffect != ExperimentalEffect.none) ...[
          const SizedBox(height: 12),
          _buildEffectIntensitySlider(context, provider),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    provider.experimentalEffect.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEffectIntensitySlider(
    BuildContext context,
    ImageProcessingProvider provider,
  ) {
    return Row(
      children: [
        Icon(
          Icons.tune,
          size: 20,
          color: Theme.of(context).colorScheme.tertiary,
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text('强度', style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: Slider(
            value: provider.effectIntensity,
            min: 0.1,
            max: 2.0,
            divisions: 19,
            onChanged: (value) =>
                provider.setEffectIntensity(value, generatePreview: false),
            onChangeEnd: (value) => provider.setEffectIntensity(value),
          ),
        ),
        SizedBox(
          width: 50,
          child: Text(
            provider.effectIntensity.toStringAsFixed(1),
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGpuAndAutoAdjustSection(
    BuildContext context,
    ImageProcessingProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.speed,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '智能优化',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFeatureToggle(
                  context,
                  icon: Icons.memory,
                  label: 'GPU 加速',
                  subtitle: provider.isGpuAvailable ? '已启用' : '不可用',
                  value:
                      provider.enableGpuAcceleration && provider.isGpuAvailable,
                  onChanged: provider.isGpuAvailable
                      ? (value) => provider.setEnableGpuAcceleration(value)
                      : null,
                  isEnabled: provider.isGpuAvailable,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFeatureToggle(
                  context,
                  icon: Icons.auto_fix_high,
                  label: '自动调整',
                  subtitle: provider.isAnalyzing
                      ? '分析中...'
                      : (provider.autoAdjustEnabled ? '已启用' : '关闭'),
                  value: provider.autoAdjustEnabled,
                  onChanged: (value) => provider.setAutoAdjustEnabled(value),
                  isEnabled: true,
                ),
              ),
            ],
          ),
          if (provider.autoAdjustEnabled &&
              provider.autoAdjustDescription != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (provider.isAnalyzing)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  else
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.autoAdjustDescription!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (provider.autoAdjustEnabled &&
              provider.autoAdjustment != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => provider.analyzeAndAutoAdjust(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('重新分析'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureToggle(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required void Function(bool)? onChanged,
    required bool isEnabled,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isEnabled
            ? (value
                  ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                  : colorScheme.surface)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isEnabled
                ? (value ? colorScheme.primary : colorScheme.onSurfaceVariant)
                : colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isEnabled
                        ? colorScheme.onSurface
                        : colorScheme.outline,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isEnabled
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildOptimizedSlider(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required IconData icon,
    required ImageProcessingProvider provider,
    required void Function(double) onValueChanged,
    required void Function(double) onPreviewGenerate,
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
            onChanged: onValueChanged,
            onChangeEnd: onPreviewGenerate,
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
                separatorBuilder: (context, index) => const SizedBox(width: 4),
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

  Widget _buildBackgroundRemovalCard(
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
                    const Icon(Icons.auto_fix_high),
                    const SizedBox(width: 8),
                    Text(
                      '智能抠图',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                Switch(
                  value: provider.backgroundRemovalEnabled,
                  onChanged: provider.isRemovingBackground
                      ? null
                      : (value) => provider.setBackgroundRemovalEnabled(value),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '自动识别并移除图片背景，让主体更加突出',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (provider.backgroundRemovalEnabled) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              _buildBackgroundRemovalModeSelector(context, provider),
              const SizedBox(height: 12),
              _buildToleranceSlider(context, provider),
              if (provider.backgroundMask != null) ...[
                const SizedBox(height: 12),
                _buildMaskEditTools(context, provider),
                const SizedBox(height: 12),
                _buildMaskPreview(context, provider),
              ],
              if (provider.isRemovingBackground) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '正在处理...',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundRemovalModeSelector(
    BuildContext context,
    ImageProcessingProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('抠图模式', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                provider.backgroundRemovalDescription ?? '选择模式',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              avatar: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('智能自动'),
              selected:
                  provider.backgroundRemovalMode == BackgroundRemovalMode.auto,
              onSelected: (_) =>
                  provider.setBackgroundRemovalMode(BackgroundRemovalMode.auto),
            ),
            ChoiceChip(
              avatar: const Icon(Icons.border_outer, size: 16),
              label: const Text('边缘填充'),
              selected:
                  provider.backgroundRemovalMode ==
                  BackgroundRemovalMode.edgeFloodFill,
              onSelected: (_) => provider.setBackgroundRemovalMode(
                BackgroundRemovalMode.edgeFloodFill,
              ),
            ),
            ChoiceChip(
              avatar: const Icon(Icons.color_lens, size: 16),
              label: const Text('颜色识别'),
              selected:
                  provider.backgroundRemovalMode ==
                  BackgroundRemovalMode.colorBased,
              onSelected: (_) => provider.setBackgroundRemovalMode(
                BackgroundRemovalMode.colorBased,
              ),
            ),
            ChoiceChip(
              avatar: const Icon(Icons.grain, size: 16),
              label: const Text('Canny边缘'),
              selected:
                  provider.backgroundRemovalMode ==
                  BackgroundRemovalMode.cannyEdge,
              onSelected: (_) => provider.setBackgroundRemovalMode(
                BackgroundRemovalMode.cannyEdge,
              ),
            ),
            ChoiceChip(
              avatar: const Icon(Icons.texture, size: 16),
              label: const Text('区域生长'),
              selected:
                  provider.backgroundRemovalMode ==
                  BackgroundRemovalMode.regionGrowing,
              onSelected: (_) => provider.setBackgroundRemovalMode(
                BackgroundRemovalMode.regionGrowing,
              ),
            ),
            ChoiceChip(
              avatar: const Icon(Icons.pan_tool, size: 16),
              label: const Text('手动'),
              selected:
                  provider.backgroundRemovalMode ==
                  BackgroundRemovalMode.manual,
              onSelected: (_) => provider.setBackgroundRemovalMode(
                BackgroundRemovalMode.manual,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToleranceSlider(
    BuildContext context,
    ImageProcessingProvider provider,
  ) {
    return Row(
      children: [
        Icon(
          Icons.tune,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text('容差', style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: Slider(
            value: provider.backgroundRemovalTolerance,
            min: 1.0,
            max: 100.0,
            divisions: 99,
            onChanged: (value) {
              provider.setBackgroundRemovalTolerance(value);
            },
            onChangeEnd: (value) {
              if (provider.backgroundRemovalEnabled) {
                provider.performBackgroundRemoval();
              }
            },
          ),
        ),
        SizedBox(
          width: 50,
          child: Text(
            provider.backgroundRemovalTolerance.toStringAsFixed(0),
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaskEditTools(
    BuildContext context,
    ImageProcessingProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('手动调整工具', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            ChoiceChip(
              avatar: const Icon(Icons.brush, size: 16),
              label: const Text('画笔'),
              selected: provider.currentMaskEditTool == MaskEditTool.brush,
              onSelected: (_) => provider.setMaskEditTool(MaskEditTool.brush),
            ),
            ChoiceChip(
              avatar: const Icon(Icons.cleaning_services, size: 16),
              label: const Text('橡皮'),
              selected: provider.currentMaskEditTool == MaskEditTool.eraser,
              onSelected: (_) => provider.setMaskEditTool(MaskEditTool.eraser),
            ),
            ChoiceChip(
              avatar: const Icon(Icons.auto_fix_high, size: 16),
              label: const Text('魔棒'),
              selected: provider.currentMaskEditTool == MaskEditTool.magicWand,
              onSelected: (_) =>
                  provider.setMaskEditTool(MaskEditTool.magicWand),
            ),
            ChoiceChip(
              avatar: const Icon(Icons.edit, size: 16),
              label: const Text('套索'),
              selected: provider.currentMaskEditTool == MaskEditTool.lasso,
              onSelected: (_) => provider.setMaskEditTool(MaskEditTool.lasso),
            ),
            ChoiceChip(
              avatar: const Icon(Icons.tune, size: 16),
              label: const Text('边缘细化'),
              selected:
                  provider.currentMaskEditTool == MaskEditTool.edgeRefinement,
              onSelected: (_) =>
                  provider.setMaskEditTool(MaskEditTool.edgeRefinement),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.line_weight,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 60,
              child: Text(
                '笔刷大小',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Expanded(
              child: Slider(
                value: provider.maskEditBrushSize.toDouble(),
                min: 5,
                max: 100,
                divisions: 19,
                onChanged: (value) {
                  provider.setMaskEditBrushSize(value.round());
                },
              ),
            ),
            SizedBox(
              width: 50,
              child: Text(
                provider.maskEditBrushSize.toString(),
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => provider.invertMask(),
              icon: const Icon(Icons.flip, size: 18),
              label: const Text('反转'),
            ),
            OutlinedButton.icon(
              onPressed: () => provider.dilateMask(),
              icon: const Icon(Icons.expand, size: 18),
              label: const Text('扩展'),
            ),
            OutlinedButton.icon(
              onPressed: () => provider.erodeMask(),
              icon: const Icon(Icons.compress, size: 18),
              label: const Text('收缩'),
            ),
            OutlinedButton.icon(
              onPressed: () => provider.smoothMask(),
              icon: const Icon(Icons.blur_on, size: 18),
              label: const Text('平滑'),
            ),
            OutlinedButton.icon(
              onPressed: () => provider.resetMask(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重置'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMaskPreview(
    BuildContext context,
    ImageProcessingProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text('抠图预览', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(
                    context,
                    provider.backgroundRemovalConfidence,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '置信度: ${(provider.backgroundRemovalConfidence * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Stack(
                children: [
                  _buildCheckerboardBackground(context),
                  if (provider.flutterBackgroundRemovedImage != null)
                    Center(
                      child: RawImage(
                        image: provider.flutterBackgroundRemovedImage,
                        fit: BoxFit.contain,
                      ),
                    ),
                  if (provider.backgroundMask != null)
                    GestureDetector(
                      onPanStart: (details) {
                        _handleMaskEdit(
                          provider,
                          details.localPosition,
                          context,
                        );
                      },
                      onPanUpdate: (details) {
                        _handleMaskEdit(
                          provider,
                          details.localPosition,
                          context,
                        );
                      },
                      child: Container(
                        color: Colors.transparent,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '提示：在预览区域拖动以使用当前工具编辑蒙版',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (provider.backgroundMask != null)
                Text(
                  '${provider.backgroundMask!.length}×${provider.backgroundMask![0].length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckerboardBackground(BuildContext context) {
    return CustomPaint(
      painter: CheckerboardPainter(
        color1: Colors.grey.shade200,
        color2: Colors.grey.shade300,
        squareSize: 10,
      ),
      size: const Size(double.infinity, double.infinity),
    );
  }

  void _handleMaskEdit(
    ImageProcessingProvider provider,
    Offset localPosition,
    BuildContext context,
  ) {
    if (provider.backgroundMask == null || provider.originalImage == null) {
      return;
    }

    final image = provider.originalImage!;

    final scaleX = image.width / 200.0;
    final scaleY = image.height / 200.0;

    final x = (localPosition.dx * scaleX).round().clamp(0, image.width - 1);
    final y = (localPosition.dy * scaleY).round().clamp(0, image.height - 1);

    provider.editMaskAtPoint(x, y);
  }

  Color _getConfidenceColor(BuildContext context, double confidence) {
    if (confidence >= 0.8) {
      return Colors.green.shade100;
    } else if (confidence >= 0.5) {
      return Colors.orange.shade100;
    } else {
      return Colors.red.shade100;
    }
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

      if (widget.onDesignCreated != null) {
        widget.onDesignCreated!(design);
      } else {
        Navigator.of(context).pop(design);
      }
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

class CheckerboardPainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final double squareSize;

  CheckerboardPainter({
    required this.color1,
    required this.color2,
    required this.squareSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = color1;
    final paint2 = Paint()..color = color2;

    final rows = (size.height / squareSize).ceil();
    final cols = (size.width / squareSize).ceil();

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final rect = Rect.fromLTWH(
          col * squareSize,
          row * squareSize,
          squareSize,
          squareSize,
        );
        canvas.drawRect(rect, (row + col) % 2 == 0 ? paint1 : paint2);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CheckerboardPainter oldDelegate) {
    return color1 != oldDelegate.color1 ||
        color2 != oldDelegate.color2 ||
        squareSize != oldDelegate.squareSize;
  }
}
