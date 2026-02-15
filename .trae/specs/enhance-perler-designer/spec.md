# 拼豆设计器完整重写 Spec

## Why

用户对当前实现不满意，需要完全重写所有功能模块，确保每个功能都正确实现，同时添加品牌化和自定义功能。

## What Changes

- 完全重写所有核心功能模块
- 修改应用标题栏为"兔可可的拼豆世界"
- 修改应用包名为 `com.bunnycc.perler` (BunnyCC Perler)
- 添加"关于软件"页面
- 添加"更新日志"功能
- 实现高度自定义设置
- 提供图标设置指南

## Impact

- Affected specs: 所有功能模块需要完全重写
- Affected code: 整个项目代码库

## ADDED Requirements

### Requirement: 应用品牌化

系统 SHALL 提供完整的品牌化配置：

- 应用标题显示为"兔可可的拼豆世界"
- 包名为 `com.bunnycc.perler`
- 英文名为 BunnyCC Perler

#### Scenario: 应用启动

- **WHEN** 用户启动应用
- **THEN** 标题栏显示"兔可可的拼豆世界"
- **AND** 应用包名为 com.bunnycc.perler

### Requirement: 关于软件页面

系统 SHALL 提供关于软件页面：

- 显示应用名称"兔可可的拼豆世界"
- 显示版本号
- 显示开发者信息
- 显示版权信息

#### Scenario: 查看关于信息

- **WHEN** 用户点击设置中的"关于"
- **THEN** 显示关于软件对话框

### Requirement: 更新日志

系统 SHALL 提供更新日志功能：

- 显示版本历史
- 显示每个版本的更新内容

#### Scenario: 查看更新日志

- **WHEN** 用户点击"更新日志"
- **THEN** 显示版本更新历史

### Requirement: 新建设计功能

系统 SHALL 提供完整的新建设计功能：

- 弹出新建设计对话框
- 输入设计名称
- 选择画布尺寸（预设和自定义）
- 创建后自动打开编辑器

#### Scenario: 新建设计

- **WHEN** 用户点击"新建设计"
- **THEN** 显示对话框
- **AND** 用户可输入名称和尺寸
- **AND** 创建后自动打开编辑器

### Requirement: 导入图片功能

系统 SHALL 提供完整的图片导入功能：

- 选择图片文件
- 预览原始图片和处理后效果
- 设置输出尺寸
- 颜色匹配生成设计
- 生成后自动打开编辑器

#### Scenario: 导入图片生成设计

- **WHEN** 用户点击"导入图片"
- **THEN** 显示图片选择界面
- **AND** 用户可选择图片
- **AND** 用户可设置尺寸
- **AND** 生成设计后自动打开编辑器

### Requirement: 设计编辑器功能

系统 SHALL 提供完整的设计编辑器：

- 网格显示设计
- 颜色选择面板
- 绘制/擦除/填充工具
- 撤销/重做功能
- 统计面板
- 库存对比
- 保存功能

#### Scenario: 编辑设计

- **WHEN** 用户在编辑器中操作
- **THEN** 可以绘制、擦除、填充拼豆
- **AND** 可以撤销/重做
- **AND** 可以保存设计

### Requirement: 库存管理功能

系统 SHALL 提供完整的库存管理：

- 库存列表显示
- 添加/编辑/删除库存
- CSV/JSON导入导出
- 搜索和筛选

#### Scenario: 管理库存

- **WHEN** 用户进入库存管理
- **THEN** 可以查看所有库存
- **AND** 可以添加/编辑/删除
- **AND** 可以导入导出数据

### Requirement: 颜色库功能

系统 SHALL 提供完整的颜色库：

- 显示所有颜色
- 添加自定义颜色
- 颜色搜索

#### Scenario: 使用颜色库

- **WHEN** 用户查看颜色库
- **THEN** 显示所有可用颜色
- **AND** 可以添加自定义颜色

### Requirement: 导出功能

系统 SHALL 提供完整的导出功能：

- PNG导出
- PDF导出
- 材料清单CSV导出
- 材料清单PDF导出

#### Scenario: 导出设计

- **WHEN** 用户点击导出
- **THEN** 可选择导出格式
- **AND** 成功导出文件

### Requirement: 插件系统

系统 SHALL 提供插件系统：

- 颜色优化插件
- 抖动效果插件
- 轮廓提取插件

#### Scenario: 使用插件

- **WHEN** 用户在编辑器中使用插件
- **THEN** 插件效果正确应用

### Requirement: 高度自定义设置

系统 SHALL 支持高度自定义：

- 默认画布尺寸设置
- 默认导出格式设置
- 低库存阈值设置

#### Scenario: 自定义设置

- **WHEN** 用户修改设置
- **THEN** 设置保存并生效

## MODIFIED Requirements

无（全部重写）

## REMOVED Requirements

无
