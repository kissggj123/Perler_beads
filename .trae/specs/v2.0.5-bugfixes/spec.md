# 拼豆设计器 v2.0.5 Bug修复 Spec

## Why

v2.0.0 版本存在导出文档功能错误和缩放移动功能失效的问题，需要修复。

## What Changes

- 修复导出文档功能错误（FileType.custom 问题）
- 修复缩放及移动功能失效的问题
- 优化导入图片输出尺寸设置，自动计算适合的宽高
- 新增导入图片自动完成图像调整（充分利用GPU特性）
- 测试所有功能确保正常工作

## Impact

- Affected code:
  - `lib/screens/home_screen.dart` - 导出功能
  - `lib/widgets/export_dialog.dart` - 导出对话框
  - `lib/widgets/bead_canvas_widget.dart` - 缩放移动
  - `lib/providers/design_editor_provider.dart` - 变换状态管理

## ADDED Requirements

### Requirement: 导出功能修复

系统 SHALL 正确导出文档，不出现 FileType.custom 错误。

#### Scenario: 导出文档

- **WHEN** 用户点击导出功能
- **THEN** 应正确弹出文件保存对话框
- **AND** 不出现 "Invalid argument (allowedExtensions)" 错误

### Requirement: 缩放移动功能修复

系统 SHALL 正确响应缩放和移动操作。

#### Scenario: 缩放操作

- **WHEN** 用户使用鼠标滚轮或 QE 键缩放
- **THEN** 画布应正确缩放

#### Scenario: 移动操作

- **WHEN** 用户使用鼠标拖动或 WASD 键移动
- **THEN** 画布应正确移动

### Requirement: 导入图片尺寸自动计算

系统 SHALL 自动计算适合的输出尺寸。

#### Scenario: 自动计算尺寸

- **WHEN** 用户导入图片
- **THEN** 系统应自动计算适合的宽高比
- **AND** 显示推荐的输出尺寸

### Requirement: GPU 加速图像调整

系统 SHALL 充分利用 GPU 特性自动完成图像调整。

#### Scenario: 自动图像调整

- **WHEN** 用户导入图片
- **THEN** 系统应自动应用最佳图像调整
- **AND** 利用 GPU 加速处理

### Requirement: 功能测试

系统 SHALL 确保所有功能正常工作。

#### Scenario: 功能完整性

- **WHEN** 用户使用任何功能
- **THEN** 功能应正常工作
- **AND** 不出现错误或崩溃

## MODIFIED Requirements

无

## REMOVED Requirements

无
