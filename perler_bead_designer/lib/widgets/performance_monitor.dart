import 'dart:io';

import 'package:flutter/material.dart';

import '../services/performance_service.dart';

class PerformanceMonitorOverlay extends StatefulWidget {
  final Widget child;
  final bool showOverlay;
  final Alignment alignment;

  const PerformanceMonitorOverlay({
    super.key,
    required this.child,
    this.showOverlay = false,
    this.alignment = Alignment.topRight,
  });

  @override
  State<PerformanceMonitorOverlay> createState() => _PerformanceMonitorOverlayState();
}

class _PerformanceMonitorOverlayState extends State<PerformanceMonitorOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final PerformanceService _performanceService = PerformanceService();
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    if (widget.showOverlay) {
      _performanceService.initialize().then((_) {
        _performanceService.startMonitoring();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _performanceService.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showOverlay)
          Positioned(
            top: widget.alignment == Alignment.topRight ||
                    widget.alignment == Alignment.topLeft ||
                    widget.alignment == Alignment.topCenter
                ? 0
                : null,
            bottom: widget.alignment == Alignment.bottomRight ||
                    widget.alignment == Alignment.bottomLeft ||
                    widget.alignment == Alignment.bottomCenter
                ? 0
                : null,
            left: widget.alignment == Alignment.topLeft ||
                    widget.alignment == Alignment.bottomLeft ||
                    widget.alignment == Alignment.centerLeft
                ? 0
                : null,
            right: widget.alignment == Alignment.topRight ||
                    widget.alignment == Alignment.bottomRight ||
                    widget.alignment == Alignment.centerRight
                ? 0
                : null,
            child: _buildOverlay(),
          ),
      ],
    );
  }

  Widget _buildOverlay() {
    return AnimatedBuilder(
      animation: _performanceService,
      builder: (context, child) {
        final metrics = _performanceService.getCurrentMetrics();
        
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Material(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              child: _isExpanded
                  ? _buildExpandedPanel(metrics)
                  : _buildCollapsedPanel(metrics),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollapsedPanel(PerformanceMetrics metrics) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = true),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFpsIndicator(metrics.frameRate),
            const SizedBox(width: 8),
            const Icon(
              Icons.expand_more,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedPanel(PerformanceMetrics metrics) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const Divider(height: 1, color: Colors.white24),
          _buildMetricsGrid(metrics),
          const Divider(height: 1, color: Colors.white24),
          _buildFrameGraph(),
          const Divider(height: 1, color: Colors.white24),
          _buildBackendInfo(metrics),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '性能监控',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          InkWell(
            onTap: () => setState(() => _isExpanded = false),
            child: const Icon(
              Icons.expand_less,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(PerformanceMetrics metrics) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'FPS',
                  metrics.frameRateFormatted,
                  _getFpsColor(metrics.frameRate),
                  Icons.speed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricItem(
                  '帧时间',
                  metrics.frameTimeFormatted,
                  Colors.blue,
                  Icons.timer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'GPU',
                  metrics.gpuUsageFormatted,
                  _getGpuColor(metrics.gpuUsage),
                  Icons.memory,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricItem(
                  '丢帧',
                  '${metrics.droppedFrames}',
                  metrics.droppedFrames > 10 ? Colors.red : Colors.green,
                  Icons.warning_amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFrameGraph() {
    final timings = _performanceService.frameTimings;
    if (timings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          '等待数据...',
          style: TextStyle(color: Colors.white54, fontSize: 10),
        ),
      );
    }

    return SizedBox(
      height: 50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: CustomPaint(
          size: const Size(double.infinity, 50),
          painter: FrameGraphPainter(
            timings: timings.length > 60
                ? timings.sublist(timings.length - 60)
                : timings,
            targetFrameTime: 1000.0 / _performanceService.config.targetFrameRate,
          ),
        ),
      ),
    );
  }

  Widget _buildBackendInfo(PerformanceMetrics metrics) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                metrics.isGpuAccelerated
                    ? Icons.check_circle
                    : Icons.cancel,
                color: metrics.isGpuAccelerated
                    ? Colors.green
                    : Colors.orange,
                size: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'GPU 加速: ${metrics.isGpuAccelerated ? "已启用" : "已禁用"}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '后端: ${metrics.platformBackend}',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFpsIndicator(double fps) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getFpsColor(fps).withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _getFpsColor(fps)),
      ),
      child: Text(
        '${fps.toStringAsFixed(0)} FPS',
        style: TextStyle(
          color: _getFpsColor(fps),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getFpsColor(double fps) {
    if (fps >= 55) return Colors.green;
    if (fps >= 45) return Colors.lightGreen;
    if (fps >= 30) return Colors.orange;
    return Colors.red;
  }

  Color _getGpuColor(double usage) {
    if (usage < 50) return Colors.green;
    if (usage < 75) return Colors.orange;
    return Colors.red;
  }
}

class FrameGraphPainter extends CustomPainter {
  final List<FrameTimingInfo> timings;
  final double targetFrameTime;

  FrameGraphPainter({
    required this.timings,
    required this.targetFrameTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (timings.isEmpty) return;

    final barWidth = size.width / timings.length;
    final maxTime = targetFrameTime * 2;

    for (int i = 0; i < timings.length; i++) {
      final timing = timings[i];
      final barHeight = (timing.frameTime / maxTime * size.height).clamp(2.0, size.height);
      
      final color = timing.isDropped
          ? Colors.red.withOpacity(0.8)
          : timing.frameTime > targetFrameTime
              ? Colors.orange.withOpacity(0.6)
              : Colors.green.withOpacity(0.6);

      final rect = Rect.fromLTWH(
        i * barWidth,
        size.height - barHeight,
        barWidth - 1,
        barHeight,
      );

      canvas.drawRect(rect, Paint()..color = color);
    }

    final targetY = size.height - (targetFrameTime / maxTime * size.height);
    canvas.drawLine(
      Offset(0, targetY),
      Offset(size.width, targetY),
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant FrameGraphPainter oldDelegate) {
    return timings != oldDelegate.timings;
  }
}

class PerformanceStatsPanel extends StatelessWidget {
  final PerformanceMetrics metrics;

  const PerformanceStatsPanel({
    super.key,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '性能统计',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _buildRatingBadge(metrics.performanceRating),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              context,
              '帧率',
              metrics.frameRateFormatted,
              Icons.speed,
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              context,
              '帧时间',
              metrics.frameTimeFormatted,
              Icons.timer,
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              context,
              'GPU 使用率',
              metrics.gpuUsageFormatted,
              Icons.memory,
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              context,
              '丢帧数',
              '${metrics.droppedFrames}',
              Icons.warning_amber,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Platform.isMacOS || Platform.isIOS
                      ? Icons.apple
                      : Icons.computer,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '渲染后端: ${metrics.platformBackend}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildRatingBadge(PerformanceRating rating) {
    final (color, text) = switch (rating) {
      PerformanceRating.excellent => (Colors.green, '优秀'),
      PerformanceRating.good => (Colors.lightGreen, '良好'),
      PerformanceRating.fair => (Colors.orange, '一般'),
      PerformanceRating.poor => (Colors.red, '较差'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
