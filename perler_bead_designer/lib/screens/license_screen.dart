import 'package:flutter/material.dart';

class LicenseScreen extends StatefulWidget {
  final VoidCallback onAgree;
  final VoidCallback? onDecline;

  const LicenseScreen({super.key, required this.onAgree, this.onDecline});

  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;

  static const String _softwareLicense = '''
兔可可的拼豆世界 软件许可协议

版权所有 © 2026 BunnyCC. 保留所有权利。

本软件许可协议（以下简称"协议"）是您（以下简称"用户"）与 BunnyCC（以下简称"开发者"）之间关于使用"兔可可的拼豆世界"软件（以下简称"软件"）的法律协议。

第1条 许可授予
开发者授予用户一项非独占、不可转让、有限制的许可，允许用户在个人计算机上安装和使用本软件。

第2条 使用限制
用户不得：
1. 复制、修改、分发、出售或出租本软件的任何部分
2. 对本软件进行逆向工程、反编译或反汇编
3. 移除本软件中的任何版权声明或其他所有权标识
4. 将本软件用于任何非法目的

第3条 知识产权
本软件受著作权法和其他知识产权法律保护。用户承认本软件的所有权归开发者所有。

第4条 免责声明
本软件按"现状"提供，不提供任何形式的明示或暗示担保，包括但不限于：
1. 适销性担保
2. 特定用途适用性担保
3. 不侵权担保

第5条 责任限制
在任何情况下，开发者不对任何直接、间接、偶然、特殊、惩罚性或后果性损害承担责任，包括但不限于：
1. 数据丢失
2. 利润损失
3. 业务中断

第6条 终止
如果用户违反本协议的任何条款，本许可将自动终止。终止后，用户必须销毁所有软件副本。

第7条 适用法律
本协议受中华人民共和国法律管辖。

第8条 完整协议
本协议构成用户与开发者之间关于本软件的完整协议。

如果您不同意本协议的任何条款，请不要安装或使用本软件。

安装或使用本软件即表示您同意受本协议条款约束。
''';

  static const String _openSourceLicenses = '''
开源组件许可协议

本软件使用了以下开源组件：

1. Flutter Framework
   许可协议：BSD 3-Clause License
   版权所有 © 2014 The Flutter Authors

2. Provider
   许可协议：MIT License
   版权所有 © 2019 Remi Rousselet

3. shared_preferences
   许可协议：BSD 3-Clause License
   版权所有 © 2013 The Flutter Authors

4. path_provider
   许可协议：BSD 3-Clause License
   版权所有 © 2013 The Flutter Authors

5. file_picker
   许可协议：MIT License
   版权所有 © 2018 Miguel Ruivo

6. pdf
   许可协议：Apache License 2.0
   版权所有 © 2014 David PHAM-VAN

7. image
   许可协议：MIT License
   版权所有 © 2014 Brendan Duncan

8. window_manager
   许可协议：MIT License
   版权所有 © 2021 LeanFlutter

以上开源组件的许可协议全文可在相应项目的 GitHub 仓库中找到。
''';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScrollPosition);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_checkScrollPosition);
    _scrollController.dispose();
    super.dispose();
  }

  void _checkScrollPosition() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      if (!_hasScrolledToBottom) {
        setState(() {
          _hasScrolledToBottom = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildLicenseContent(context)),
            _buildBottomButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.description_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '软件许可协议',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '请仔细阅读以下协议内容',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseContent(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLicenseSection(
              context,
              '软件许可协议',
              _softwareLicense,
              Icons.gavel,
            ),
            const SizedBox(height: 32),
            _buildLicenseSection(
              context,
              '开源组件许可',
              _openSourceLicenses,
              Icons.code,
            ),
            const SizedBox(height: 24),
            if (!_hasScrolledToBottom)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '请滚动阅读完整协议内容后继续',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (widget.onDecline != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onDecline,
                icon: const Icon(Icons.close),
                label: const Text('不同意'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          if (widget.onDecline != null) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _hasScrolledToBottom ? widget.onAgree : null,
              icon: const Icon(Icons.check),
              label: const Text('同意并继续'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
