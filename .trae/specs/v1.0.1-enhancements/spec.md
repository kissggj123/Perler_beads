# 拼豆设计器 v1.0.1 功能增强 Spec

## Why
用户反馈了多个问题和功能需求，需要修复设置选项问题、完善导入导出功能、增加国产拼豆支持、增强图片导入算法和预览交互。

## What Changes
- 修复设置选项"导出时显示网格线"无法开启的问题
- 完善数据导入导出功能
- 新增定位到程序数据目录功能
- 新增国产拼豆品牌支持（淘宝、拼多多系列）
- 新增更多图片导入算法风格
- 优化预览图交互，点击格子显示颜色信息

## Impact
- Affected code:
  - `lib/screens/settings_screen.dart` - 修复设置开关
  - `lib/services/settings_service.dart` - 设置持久化
  - `lib/screens/settings_screen.dart` - 导入导出功能
  - `lib/data/standard_colors.dart` - 新增国产拼豆颜色
  - `lib/services/image_processing_service.dart` - 新增算法
  - `lib/widgets/image_preview_widget.dart` - 预览交互

## ADDED Requirements

### Requirement: 设置开关修复
系统 SHALL 正确保存和读取"导出时显示网格线"设置。

#### Scenario: 切换网格线设置
- **WHEN** 用户切换"导出时显示网格线"开关
- **THEN** 设置应被正确保存
- **AND** 下次打开设置页面时显示正确状态

### Requirement: 数据导入导出功能
系统 SHALL 提供完整的数据导入导出功能。

#### Scenario: 导出所有数据
- **WHEN** 用户点击"导出所有数据"
- **THEN** 系统应导出所有设计和库存数据为备份文件

#### Scenario: 导入数据
- **WHEN** 用户点击"导入数据"
- **THEN** 系统应支持从备份文件恢复数据

### Requirement: 定位程序数据目录
系统 SHALL 提供一键打开程序数据目录的功能。

#### Scenario: 打开数据目录
- **WHEN** 用户点击"打开数据目录"
- **THEN** 系统应在文件管理器中打开数据存储目录

### Requirement: 国产拼豆品牌支持
系统 SHALL 支持更多国产拼豆品牌。

#### Scenario: 使用国产拼豆
- **WHEN** 用户选择拼豆品牌
- **THEN** 应包含淘宝、拼多多等国产系列颜色

### Requirement: 图片导入算法风格
系统 SHALL 提供多种图片导入算法风格。

#### Scenario: 选择算法风格
- **WHEN** 用户导入图片时
- **THEN** 可选择不同的算法风格（如像素艺术、卡通风格、写实风格等）

### Requirement: 预览图交互
系统 SHALL 在预览图上提供颜色信息交互。

#### Scenario: 点击预览格子
- **WHEN** 用户点击预览图上的格子
- **THEN** 显示该格子的颜色色号、名称等信息

## MODIFIED Requirements
无

## REMOVED Requirements
无
