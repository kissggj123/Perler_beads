# 拼豆设计器 v2.0 核心重构 Spec

## Why
v1.x 版本存在核心问题：图片导入后预览界面和完成设计后只显示灰色而非正确的像素化结果。这是由于图片处理算法存在 bug。同时需要修复 logo 显示问题和其他已知问题，确保 2.0 版本功能正常。

## What Changes
- **修复核心问题**：图片导入后正确显示像素化预览和设计结果
- **修复 logo 显示**：主界面和关于页面正确显示应用 logo
- **重构图片处理流程**：确保图片处理算法正确工作
- **修复其他已知问题**：确保所有功能正常工作

## Impact
- Affected code:
  - `lib/services/image_processing_service.dart` - 图片处理核心算法
  - `lib/providers/image_processing_provider.dart` - 图片处理状态管理
  - `lib/screens/image_import_screen.dart` - 图片导入界面
  - `lib/screens/home_screen.dart` - 主界面 logo
  - `lib/screens/settings_screen.dart` - 关于页面 logo
  - `lib/widgets/image_preview_widget.dart` - 预览组件

## ADDED Requirements

### Requirement: 图片像素化核心修复
系统 SHALL 正确处理图片导入，生成正确的像素化预览和设计结果。

#### Scenario: 导入图片预览
- **WHEN** 用户导入任意图片
- **THEN** 预览界面应显示正确的像素化结果
- **AND** 不应显示灰色或空白

#### Scenario: 完成设计
- **WHEN** 用户完成图片导入并创建设计
- **THEN** 设计应正确显示像素化的图案
- **AND** 所有颜色应正确匹配

### Requirement: Logo 显示修复
系统 SHALL 在所有位置正确显示应用 logo。

#### Scenario: 主界面 logo
- **WHEN** 用户打开应用
- **THEN** 主界面应正确显示应用 logo

#### Scenario: 关于页面 logo
- **WHEN** 用户查看关于页面
- **THEN** 关于页面应正确显示应用 logo

### Requirement: 图片处理算法重构
系统 SHALL 使用正确的图片处理算法。

#### Scenario: 颜色匹配
- **WHEN** 图片被像素化处理
- **THEN** 每个像素应正确匹配到最近的拼豆颜色
- **AND** 不应出现灰色占位符

#### Scenario: 算法风格
- **WHEN** 用户选择不同的算法风格
- **THEN** 应正确应用对应的效果
- **AND** 不应导致灰色结果

### Requirement: 功能完整性
系统 SHALL 确保所有核心功能正常工作。

#### Scenario: 设计编辑
- **WHEN** 用户编辑设计
- **THEN** 所有工具（绘制、擦除、填充）应正常工作

#### Scenario: 导出功能
- **WHEN** 用户导出设计
- **THEN** 应正确导出 PNG/PDF 文件

#### Scenario: 库存管理
- **WHEN** 用户管理库存
- **THEN** 导入导出功能应正常工作

## MODIFIED Requirements
无

## REMOVED Requirements
无
