import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onStart;

  const WelcomeScreen({
    super.key,
    required this.onStart,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<WelcomePage> _pages = [
    WelcomePage(
      icon: Icons.palette_outlined,
      title: '欢迎使用\n兔可可的拼豆世界',
      description: '一款专业的拼豆设计工具，让您的创意无限延伸',
      features: [
        '直观的设计界面',
        '丰富的颜色选择',
        '便捷的编辑工具',
      ],
    ),
    WelcomePage(
      icon: Icons.grid_on_outlined,
      title: '设计画布',
      description: '在网格画布上自由创作您的拼豆作品',
      features: [
        '支持多种画布尺寸',
        '实时显示坐标和颜色代号',
        '撤销/重做功能',
        '自动保存设计',
      ],
    ),
    WelcomePage(
      icon: Icons.image_outlined,
      title: '图片导入',
      description: '将您喜爱的图片转换为拼豆设计',
      features: [
        '智能颜色匹配',
        '图片缩放和移动',
        '透明背景处理',
        '智能抠图功能',
      ],
    ),
    WelcomePage(
      icon: Icons.inventory_2_outlined,
      title: '库存管理',
      description: '管理您的拼豆库存，避免材料不足',
      features: [
        '记录拼豆库存数量',
        '自动对比所需数量',
        '低库存提醒',
        '材料清单导出',
      ],
    ),
    WelcomePage(
      icon: Icons.picture_as_pdf_outlined,
      title: '导出分享',
      description: '将您的作品导出为多种格式',
      features: [
        'PNG 图片导出',
        'PDF 文档导出',
        '包含坐标和统计',
        '支持中文显示',
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onStart();
    }
  }

  void _skipAll() {
    widget.onStart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildSkipButton(context),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(context, _pages[index]);
                },
              ),
            ),
            _buildBottomNavigation(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipButton(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextButton(
          onPressed: _skipAll,
          child: Text(
            '跳过',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, WelcomePage page) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          ...page.features.map((feature) => _buildFeatureItem(context, feature)),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPageIndicator(context),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _nextPage,
              icon: Icon(
                _currentPage < _pages.length - 1
                    ? Icons.arrow_forward
                    : Icons.play_arrow,
              ),
              label: Text(
                _currentPage < _pages.length - 1 ? '下一步' : '开始使用',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class WelcomePage {
  final IconData icon;
  final String title;
  final String description;
  final List<String> features;

  const WelcomePage({
    required this.icon,
    required this.title,
    required this.description,
    required this.features,
  });
}
