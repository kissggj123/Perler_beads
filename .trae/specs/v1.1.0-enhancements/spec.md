# 拼豆设计器 v1.1.0 功能增强 Spec

## Why
用户反馈了任务栏图标、设置页问题，并希望增加上帝模式、性能优化和动画效果等高级功能。

## What Changes
- 修复程序运行时任务栏图标显示 Flutter 原生图标的问题
- 修复设置页选项无法变更修改的问题
- 新增上帝模式（隐藏的高级设置选项）
- 新增 GPU 加速支持（NVIDIA N卡和 Apple ARM 芯片优化）
- 新增界面动画效果

## Impact
- Affected code:
  - `macos/Runner/` - macOS 任务栏图标
  - `windows/runner/` - Windows 任务栏图标
  - `lib/screens/settings_screen.dart` - 设置页修复和上帝模式
  - `lib/services/settings_service.dart` - 设置持久化修复
  - `lib/main.dart` - GPU 加速配置
  - `lib/widgets/` - 动画效果

## ADDED Requirements

### Requirement: 任务栏图标修复
系统 SHALL 在运行时显示正确的应用图标，而非 Flutter 默认图标。

#### Scenario: 任务栏图标显示
- **WHEN** 用户启动应用
- **THEN** 任务栏应显示应用自定义图标
- **AND** 不显示 Flutter 默认图标

### Requirement: 设置页选项修复
系统 SHALL 正确保存和读取所有设置选项。

#### Scenario: 修改设置
- **WHEN** 用户修改任意设置选项
- **THEN** 设置应被正确保存
- **AND** 重启应用后设置保持不变

### Requirement: 上帝模式
系统 SHALL 提供隐藏的高级设置选项（上帝模式）。

#### Scenario: 启用上帝模式
- **WHEN** 用户连续点击版本号 7 次
- **THEN** 显示上帝模式选项
- **AND** 包含高级设置选项

#### Scenario: 上帝模式选项
- **WHEN** 上帝模式启用后
- **THEN** 用户可以访问调试模式、性能监控、实验性功能等

### Requirement: GPU 加速优化
系统 SHALL 利用 GPU 加速提升性能。

#### Scenario: NVIDIA GPU 加速
- **WHEN** 应用运行在配备 NVIDIA GPU 的 Windows 设备上
- **THEN** 启用 CUDA 加速渲染

#### Scenario: Apple ARM 优化
- **WHEN** 应用运行在 Apple Silicon Mac 上
- **THEN** 启用 Metal 加速和 ARM 优化

### Requirement: 界面动画效果
系统 SHALL 提供流畅的界面动画效果。

#### Scenario: 页面切换动画
- **WHEN** 用户切换页面
- **THEN** 显示平滑的过渡动画

#### Scenario: 交互动画
- **WHEN** 用户点击按钮或卡片
- **THEN** 显示涟漪或缩放动画效果

## MODIFIED Requirements
无

## REMOVED Requirements
无
