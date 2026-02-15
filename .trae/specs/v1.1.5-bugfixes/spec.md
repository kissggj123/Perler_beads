# 拼豆设计器 v1.1.5 Bug修复与优化 Spec

## Why
用户反馈了多个 bug 和优化需求，包括最近创作选项失效、网格显示问题、绘画体验优化等，需要修复并增强用户体验。

## What Changes
- 修复最近创作下的导出、重命名、打开编辑选项失效的问题
- 优化点击版本号过程不够流畅的问题
- 修复 macOS 下网格不居中、不显示坐标的问题
- 优化缩放和移动控制（WASD 移动、QE 缩放或自定义组合键）
- 新增更多导入图片下的实验性选项效果
- 修复某些无法使用的功能及可能崩溃的问题
- 新增预览功能（禁用绘画状态）可点击查看颜色信息
- 优化绘画过程不够丝滑的问题
- 优化添加自定义颜色可直接使用颜色代码（如 #224294）
- 优化滑动条不够流畅的问题

## Impact
- Affected code:
  - `lib/screens/home_screen.dart` - 最近创作选项
  - `lib/screens/settings_screen.dart` - 版本号点击
  - `lib/widgets/bead_canvas_widget.dart` - 网格居中、坐标显示、缩放移动
  - `lib/screens/design_editor_screen.dart` - 绘画优化、预览模式
  - `lib/screens/image_import_screen.dart` - 实验性选项
  - `lib/widgets/color_picker_panel.dart` - 自定义颜色输入
  - `lib/widgets/` - 滑动条优化

## ADDED Requirements

### Requirement: 最近创作选项修复
系统 SHALL 正确响应最近创作下的导出、重命名、打开编辑选项。

#### Scenario: 最近创作选项
- **WHEN** 用户点击最近创作下的导出、重命名或打开编辑
- **THEN** 应正确执行相应操作
- **AND** 不出现失效或无响应

### Requirement: 版本号点击优化
系统 SHALL 提供流畅的版本号点击体验。

#### Scenario: 点击版本号
- **WHEN** 用户连续点击版本号
- **THEN** 点击响应应流畅
- **AND** 计数器应正确累加

### Requirement: macOS 网格修复
系统 SHALL 在 macOS 下正确居中显示网格和坐标。

#### Scenario: macOS 网格显示
- **WHEN** 用户在 macOS 下使用编辑器
- **THEN** 网格应正确居中显示
- **AND** 坐标应正确显示

### Requirement: 缩放移动控制优化
系统 SHALL 提供更好的缩放和移动控制方式。

#### Scenario: 键盘控制
- **WHEN** 用户按下 WASD 键
- **THEN** 画布应相应移动
- **WHEN** 用户按下 QE 键
- **THEN** 画布应相应缩放

#### Scenario: 自定义组合键
- **WHEN** 用户在设置中自定义组合键
- **THEN** 应使用自定义的组合键控制

### Requirement: 实验性选项增强
系统 SHALL 在图片导入中提供更多实验性选项效果。

#### Scenario: 实验性效果
- **WHEN** 用户启用实验性选项
- **THEN** 可以使用更多图片处理效果

### Requirement: 崩溃问题修复
系统 SHALL 修复所有可能导致崩溃的问题。

#### Scenario: 稳定性
- **WHEN** 用户使用任何功能
- **THEN** 应用不应崩溃
- **AND** 错误应被正确处理

### Requirement: 开发者选项和实验性功能修复
系统 SHALL 正确显示和使用开发者选项及实验性功能。

#### Scenario: 开发者选项显示
- **WHEN** 用户启用上帝模式
- **THEN** 开发者选项应正确显示
- **AND** 所有选项应正常工作

#### Scenario: 实验性功能显示
- **WHEN** 用户启用实验性功能
- **THEN** 实验性功能选项应正确显示
- **AND** 功能应正常工作

### Requirement: 预览模式
系统 SHALL 提供预览模式，禁用绘画状态，可点击查看颜色信息。

#### Scenario: 预览模式
- **WHEN** 用户切换到预览模式
- **THEN** 绘画功能被禁用
- **AND** 点击格子可查看颜色信息

### Requirement: 绘画优化
系统 SHALL 提供丝滑的绘画体验。

#### Scenario: 绘画流畅性
- **WHEN** 用户在画布上绘画
- **THEN** 绘画响应应流畅
- **AND** 无明显延迟

### Requirement: 自定义颜色代码
系统 SHALL 支持直接输入颜色代码添加自定义颜色。

#### Scenario: 颜色代码输入
- **WHEN** 用户输入颜色代码（如 #224294）
- **THEN** 应正确解析并添加颜色

### Requirement: 滑动条优化
系统 SHALL 提供流畅的滑动条交互体验。

#### Scenario: 滑动条交互
- **WHEN** 用户拖动滑动条
- **THEN** 滑动应流畅
- **AND** 响应及时

## MODIFIED Requirements
无

## REMOVED Requirements
无
