# 拼豆设计器 v2.1.2 完整重写版本 Spec

## Why

v2.1.0 版本开发过程中可能存在未完整实现的功能和崩溃问题，用户希望完整重写所有功能、修复崩溃问题、优化用户体验、新增创作性工具和实验性功能，最终发布 v2.1.2 并同步到 GitHub 仓库。

## What Changes

- 完整重写 v2.1.0 所有功能
- 修复导入图片后缩放崩溃问题
- 修复其他可能存在的崩溃问题
- 优化最近创作面板独立管理功能
- 新增 GPU 加速动画效果
- 新增许可协议和说明界面
- **优化拼豆数量计算（加入容差计算）**
- **新增版本检查更新功能**
- 优化智能抠图算法，提高准确度
- 新增创作性工具（镜像、旋转、复制粘贴）
- 优化 PDF 中文支持（优先系统字体，支持代理下载）
- 新增实验性3D拼装动画功能
- 发布 v2.1.2 版本并同步到 GitHub

## Impact

- Affected specs: 所有 v2.1.0 功能, v2.1.1 PDF 中文支持
- Affected code:
  - `lib/widgets/bead_canvas_widget.dart` - 画布组件
  - `lib/providers/design_editor_provider.dart` - 编辑器 Provider
  - `lib/screens/design_editor_screen.dart` - 编辑界面
  - `lib/services/image_processing_service.dart` - 图片处理服务
  - `lib/screens/settings_screen.dart` - 设置界面
  - `lib/services/settings_service.dart` - 设置服务
  - `lib/services/performance_service.dart` - 性能服务
  - `lib/utils/platform_utils.dart` - 平台工具
  - `lib/widgets/history_panel.dart` - 历史记录面板
  - `lib/main.dart` - 主入口
  - `lib/providers/app_provider.dart` - 应用 Provider
  - `lib/utils/pdf_generator.dart` - PDF 生成器
  - `lib/services/font_service.dart` - 字体服务
  - `lib/widgets/assembly_guide_widget.dart` - 3D拼装动画组件
  - `lib/services/assembly_guide_service.dart` - 拼装引导服务
  - `lib/screens/home_screen.dart` - 首页
  - `lib/screens/license_screen.dart` - 许可协议界面
  - `lib/screens/welcome_screen.dart` - 欢迎/说明界面
  - `lib/services/gpu_animation_service.dart` - GPU 动画服务
  - `lib/models/bead_count_result.dart` - **新增拼豆计算结果模型**
  - `lib/services/bead_count_service.dart` - **新增拼豆计算服务**
  - `lib/services/version_check_service.dart` - **新增版本检查服务**
  - `lib/services/update_service.dart` - **新增更新下载安装服务**

## ADDED Requirements

### Requirement: 崩溃修复

The system SHALL 确保应用稳定运行，不出现崩溃。

### Requirement: 最近创作面板优化

The system SHALL 提供独立的创作管理功能。

### Requirement: GPU 加速动画

The system SHALL 充分利用 GPU 性能提供更好的视觉效果。

### Requirement: 许可协议和说明

The system SHALL 在首次启动时显示许可协议和说明。

### Requirement: 拼豆数量精准计算

The system SHALL 提供更精准的拼豆数量计算，包含容差范围。

#### Scenario: 容差计算

- **WHEN** 计算拼豆数量时
- **THEN** 显示推荐数量和容差范围（如 100±5）

#### Scenario: 实时更新

- **WHEN** 用户编辑设计时
- **THEN** 拼豆数量实时更新

### Requirement: 版本检查更新

The system SHALL 提供版本检查更新功能。

#### Scenario: 启动检查

- **WHEN** 应用启动时
- **THEN** 自动检查是否有新版本

#### Scenario: 手动检查

- **WHEN** 用户点击检查更新按钮
- **THEN** 检查是否有新版本并提示

#### Scenario: 更新提示

- **WHEN** 发现新版本时
- **THEN** 显示更新日志和下载链接

#### Scenario: 手动下载更新

- **WHEN** 用户选择下载更新
- **THEN** 自动下载更新包到本地

#### Scenario: 自动安装更新

- **WHEN** 更新包下载完成
- **THEN** 提示用户安装更新
- **AND** 支持自动解压和替换安装

### Requirement: 创作性工具

The system SHALL 提供更多创作性编辑工具。

### Requirement: 抠图优化

The system SHALL 提供更准确的抠图功能。

### Requirement: PDF 中文支持优化

The system SHALL 优化 PDF 中文支持，优先使用系统字体。

### Requirement: 3D拼装动画指南（实验性）

The system SHALL 提供3D拼装动画引导功能。

## MODIFIED Requirements

None

## REMOVED Requirements

None
