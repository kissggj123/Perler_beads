# 拼豆设计器 v2.1.0 创世神版本 Spec

## Why

用户希望实现格子代号和坐标显示功能，打造"创世神版本"——所有设置和参数均可自定义调整，并确保 Windows 和 macOS 双平台兼容。同时新增智能抠图功能、主题色自定义、布局优化等增强功能。

## What Changes

- 优化格子内颜色代号显示
- 添加顶部和左侧坐标显示
- 新增人性化编辑器功能（撤销/重做快捷键、自动保存、历史记录面板等）
- 实现全参数可自定义（创世神模式）
- 双平台兼容性保障（Windows + macOS 双冗余策略）
- **新增智能抠图功能** - 导入图片后自动分离主体
- **新增主题色全自定义** - 用户可完全自定义应用主题色
- **优化窗口布局** - 解决非最大化时布局挤压问题
- **修复已知问题** - 确保所有功能正常可用

## Impact

- Affected code:
  - `lib/widgets/bead_canvas_widget.dart` - 格子绘制
  - `lib/providers/design_editor_provider.dart` - 显示设置
  - `lib/providers/app_provider.dart` - 全局设置
  - `lib/screens/settings_screen.dart` - 设置选项
  - `lib/services/settings_service.dart` - 设置持久化
  - `lib/screens/design_editor_screen.dart` - 编辑器功能
  - `lib/services/image_processing_service.dart` - 图像处理（抠图）
  - `lib/screens/image_import_screen.dart` - 图片导入
  - `lib/main.dart` - 主题配置
  - `lib/screens/main_layout.dart` - 布局优化

## ADDED Requirements

### Requirement: 格子内颜色代号显示

系统 SHALL 在格子内清晰显示颜色代号。

#### Scenario: 显示颜色代号

- **WHEN** 用户在编辑器中
- **THEN** 每个填充的格子内应显示颜色代号
- **AND** 代号应清晰可读

### Requirement: 顶部坐标显示

系统 SHALL 在画布顶部显示列坐标。

#### Scenario: 顶部坐标

- **WHEN** 用户在编辑器中
- **THEN** 画布顶部应显示 1, 2, 3... 列坐标
- **AND** 坐标应与格子对齐

### Requirement: 左侧坐标显示

系统 SHALL 在画布左侧显示行坐标。

#### Scenario: 左侧坐标

- **WHEN** 用户在编辑器中
- **THEN** 画布左侧应显示 1, 2, 3... 行坐标
- **AND** 坐标应与格子对齐

### Requirement: 坐标显示开关

系统 SHALL 提供坐标显示开关选项。

#### Scenario: 切换坐标显示

- **WHEN** 用户在设置中切换坐标显示
- **THEN** 坐标显示应相应切换

### Requirement: 人性化编辑器功能

系统 SHALL 提供人性化编辑器功能。

#### Scenario: 撤销/重做快捷键

- **WHEN** 用户按下 Ctrl+Z / Cmd+Z
- **THEN** 系统应撤销上一步操作
- **AND** 用户按下 Ctrl+Y / Cmd+Shift+Z 时应重做操作

#### Scenario: 自动保存

- **WHEN** 用户在编辑器中进行操作
- **THEN** 系统应自动保存设计（可配置间隔）
- **AND** 自动保存间隔可在设置中调整

#### Scenario: 历史记录面板

- **WHEN** 用户打开历史记录面板
- **THEN** 系统应显示操作历史列表
- **AND** 用户可点击任意历史记录跳转到该状态

### Requirement: 创世神模式 - 全参数可自定义

系统 SHALL 允许用户自定义所有参数。

#### Scenario: 快捷键自定义

- **WHEN** 用户进入快捷键设置
- **THEN** 用户可自定义所有快捷键绑定
- **AND** 支持重置为默认值

#### Scenario: 界面参数自定义

- **WHEN** 用户进入界面设置
- **THEN** 用户可调整格子大小、网格颜色、坐标字体大小等参数
- **AND** 所有参数实时预览

#### Scenario: 性能参数自定义

- **WHEN** 用户进入性能设置
- **THEN** 用户可调整 FPS 限制、缓存大小、GPU 加速等参数

#### Scenario: 编辑器参数自定义

- **WHEN** 用户进入编辑器设置
- **THEN** 用户可调整自动保存间隔、历史记录数量、画布默认尺寸等参数

### Requirement: 双平台兼容性（双冗余策略）

系统 SHALL 确保 Windows 和 macOS 双平台功能一致性。

#### Scenario: 平台检测与适配

- **WHEN** 程序启动时
- **THEN** 系统应检测当前平台
- **AND** 自动应用平台特定的默认设置

#### Scenario: 快捷键平台适配

- **WHEN** 用户在 Windows 上使用程序
- **THEN** 快捷键使用 Ctrl 作为修饰键
- **AND** 用户在 macOS 上使用程序时，快捷键使用 Cmd 作为修饰键

#### Scenario: 文件路径兼容

- **WHEN** 系统读写文件
- **THEN** 使用平台无关的路径处理
- **AND** Windows 和 macOS 均能正确访问数据目录

#### Scenario: 平台特定功能降级

- **WHEN** 某平台不支持某功能
- **THEN** 系统应自动降级到兼容模式
- **AND** 通知用户功能受限

### Requirement: 智能抠图功能

系统 SHALL 在导入图片后自动识别并分离主体。

#### Scenario: 自动主体识别

- **WHEN** 用户导入图片
- **THEN** 系统应自动分析图片内容
- **AND** 识别可能的主体区域

#### Scenario: 抠图预览

- **WHEN** 系统完成主体识别
- **THEN** 显示抠图预览结果
- **AND** 用户可选择接受或手动调整

#### Scenario: 手动抠图调整

- **WHEN** 用户对自动抠图结果不满意
- **THEN** 用户可手动调整抠图区域
- **AND** 支持画笔添加/擦除区域

#### Scenario: 背景透明化

- **WHEN** 用户确认抠图结果
- **THEN** 非主体区域应变为透明
- **AND** 透明区域在转换为拼豆时不填充颜色

### Requirement: 主题色全自定义

系统 SHALL 允许用户完全自定义应用主题色。

#### Scenario: 主题色选择

- **WHEN** 用户进入主题设置
- **THEN** 用户可选择主色调、次色调、强调色
- **AND** 实时预览主题效果

#### Scenario: 自定义配色方案

- **WHEN** 用户创建自定义配色方案
- **THEN** 用户可为每个界面元素设置颜色
- **AND** 配色方案可保存和切换

#### Scenario: 预设主题

- **WHEN** 用户选择预设主题
- **THEN** 系统应提供多种预设主题（亮色、暗色、护眼等）
- **AND** 用户可基于预设主题进一步自定义

### Requirement: 窗口布局优化

系统 SHALL 在窗口非最大化时保持良好布局。

#### Scenario: 响应式布局

- **WHEN** 用户调整窗口大小
- **THEN** 界面元素应自动调整布局
- **AND** 保持良好的可读性和可操作性

#### Scenario: 最小窗口限制

- **WHEN** 用户尝试缩小窗口
- **THEN** 系统应限制最小窗口尺寸
- **AND** 确保核心功能可见

#### Scenario: 侧边栏折叠

- **WHEN** 窗口宽度不足
- **THEN** 侧边栏应自动折叠为图标模式
- **AND** 用户仍可访问所有功能

### Requirement: 功能可用性保障

系统 SHALL 确保所有功能正常可用。

#### Scenario: 功能测试

- **WHEN** 用户使用任何功能
- **THEN** 功能应正常工作
- **AND** 不应出现崩溃或无响应

#### Scenario: 错误处理

- **WHEN** 发生错误
- **THEN** 系统应显示友好的错误提示
- **AND** 不应影响其他功能使用

#### Scenario: 数据完整性

- **WHEN** 系统保存数据
- **THEN** 数据应完整保存
- **AND** 支持异常恢复

## MODIFIED Requirements

无

## REMOVED Requirements

无
