import 'package:flutter/material.dart';

import '../services/version_check_service.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final ReleaseInfo releaseInfo;
  final bool isManualCheck;

  const UpdateDialog({
    super.key,
    required this.releaseInfo,
    this.isManualCheck = false,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  final UpdateService _updateService = UpdateService();
  final VersionCheckService _versionCheckService = VersionCheckService();
  bool _isDownloading = false;
  DownloadProgress? _downloadProgress;

  @override
  void initState() {
    super.initState();
    _updateService.addListener(_onDownloadProgress);
  }

  @override
  void dispose() {
    _updateService.removeListener(_onDownloadProgress);
    super.dispose();
  }

  void _onDownloadProgress() {
    if (mounted) {
      setState(() {
        _downloadProgress = _updateService.progress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.system_update, color: colorScheme.primary),
          const SizedBox(width: 12),
          const Text('发现新版本'),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVersionInfo(context),
            const SizedBox(height: 16),
            if (_isDownloading)
              _buildDownloadProgress(context)
            else
              _buildReleaseNotes(context),
          ],
        ),
      ),
      actions: _isDownloading
          ? _buildDownloadingActions(context)
          : _buildNormalActions(context),
    );
  }

  Widget _buildVersionInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'v${widget.releaseInfo.version}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '发布日期: ${widget.releaseInfo.formattedPublishedAt}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (widget.releaseInfo.assets.isNotEmpty)
                  Text(
                    '文件大小: ${widget.releaseInfo.assets.first.formattedSize}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReleaseNotes(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final formattedNotes = _versionCheckService.formatReleaseNotes(
      widget.releaseInfo.releaseNotes,
    );

    return Container(
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Text(
          formattedNotes.isEmpty ? '暂无更新说明' : formattedNotes,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  Widget _buildDownloadProgress(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        LinearProgressIndicator(
          value: _downloadProgress?.progress ?? 0,
          backgroundColor: colorScheme.surfaceContainerHighest,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _downloadProgress?.formattedDownloadedSize ?? '0 KB',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${((_downloadProgress?.progress ?? 0) * 100).toStringAsFixed(1)}%',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              _downloadProgress?.formattedTotalSize ?? '0 KB',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        if (_downloadProgress?.status == DownloadStatus.paused)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '下载已暂停',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.tertiary),
            ),
          ),
        if (_downloadProgress?.status == DownloadStatus.error)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _downloadProgress?.errorMessage ?? '下载失败',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildNormalActions(BuildContext context) {
    final platformAsset = widget.releaseInfo.getAssetForCurrentPlatform();

    return [
      if (!widget.isManualCheck)
        TextButton(
          onPressed: () async {
            await _versionCheckService.skipVersion(widget.releaseInfo.version);
            if (mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('已跳过此版本')));
            }
          },
          child: const Text('跳过此版本'),
        ),
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('稍后提醒'),
      ),
      if (platformAsset != null)
        FilledButton.icon(
          onPressed: () => _startDownload(platformAsset),
          icon: const Icon(Icons.download),
          label: const Text('立即下载'),
        )
      else
        FilledButton.icon(
          onPressed: _openReleasePage,
          icon: const Icon(Icons.open_in_new),
          label: const Text('前往下载'),
        ),
    ];
  }

  List<Widget> _buildDownloadingActions(BuildContext context) {
    final status = _downloadProgress?.status;

    return [
      if (status == DownloadStatus.downloading)
        TextButton(
          onPressed: () {
            _updateService.pauseDownload();
          },
          child: const Text('暂停'),
        ),
      if (status == DownloadStatus.paused)
        FilledButton(
          onPressed: () {
            _updateService.resumeDownload();
          },
          child: const Text('继续'),
        ),
      if (status == DownloadStatus.completed)
        FilledButton.icon(
          onPressed: _installUpdate,
          icon: const Icon(Icons.install_desktop),
          label: const Text('安装更新'),
        ),
      TextButton(
        onPressed: () {
          _updateService.cancelDownload();
          Navigator.of(context).pop();
        },
        child: const Text('取消'),
      ),
    ];
  }

  Future<void> _startDownload(ReleaseAsset asset) async {
    setState(() {
      _isDownloading = true;
    });

    await _updateService.downloadUpdate(asset);
  }

  Future<void> _installUpdate() async {
    final filePath = await _updateService.installUpdate();
    if (filePath != null && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('正在打开更新文件...')));
    }
  }

  void _openReleasePage() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('请访问 GitHub 发布页面下载: ${widget.releaseInfo.htmlUrl}'),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

Future<void> showUpdateCheckDialog(BuildContext context) async {
  final versionCheckService = VersionCheckService();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  final result = await versionCheckService.checkForUpdate(forceCheck: true);

  if (context.mounted) {
    Navigator.of(context).pop();

    if (result.hasUpdate && result.releaseInfo != null) {
      showDialog(
        context: context,
        builder: (context) =>
            UpdateDialog(releaseInfo: result.releaseInfo!, isManualCheck: true),
      );
    } else if (result.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.errorMessage!)));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('当前已是最新版本')));
    }
  }
}
