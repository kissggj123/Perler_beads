# 拼豆设计器 v1.1.2 Bug修复与优化 Spec

## Why

用户反馈了多个 bug 和优化需求，包括黑屏问题、图片导入问题、Windows 标题乱码等，需要修复并增强用户体验。

## What Changes

- 修复新建工程或导入图片后返回黑屏的问题
- 修复导入某些图片生成灰色不可用状态的问题
- 增加 3D 立体效果开关选项
- 增加更多上帝模式效果
- 优化绘制时在格子上显示颜色代码
- 优化导入不符合格式的 CSV/XLSX 文件的解析
- 修复 Windows 下窗口标题乱码问题
- 新增保留最近 8 个更新日志

## Impact

- Affected code:
  - `lib/screens/design_editor_screen.dart` - 黑屏问题
  - `lib/screens/image_import_screen.dart` - 图片导入问题
  - `lib/widgets/bead_canvas_widget.dart` - 3D 效果开关、颜色代码显示
  - `lib/screens/settings_screen.dart` - 上帝模式增强
  - `lib/widgets/import_inventory_dialog.dart` - CSV/XLSX 解析优化
  - `windows/runner/main.cpp` - Windows 标题乱码
  - `lib/screens/settings_screen.dart` - 更新日志显示

## ADDED Requirements

### Requirement: 黑屏问题修复

系统 SHALL 在新建工程或导入图片后正确返回主界面，不出现黑屏。

#### Scenario: 返回主界面

- **WHEN** 用户新建工程或导入图片后点击返回
- **THEN** 应正确显示主界面
- **AND** 不出现黑屏

### Requirement: 图片导入修复

系统 SHALL 正确处理任意图片格式和尺寸，确保所有图片都能正确像素化。

#### Scenario: 导入任意图片

- **WHEN** 用户导入任意支持的图片格式（JPG、PNG、GIF、BMP、WebP 等）
- **THEN** 应正确生成像素化预览
- **AND** 不出现灰色不可用状态
- **AND** 无论图片尺寸大小都能正确处理

### Requirement: 大尺寸图片处理

系统 SHALL 正确处理任意尺寸图片，充分利用硬件加速。

#### Scenario: 导入大尺寸图片

- **WHEN** 用户导入大尺寸图片（如 1920x1080 或更大）
- **THEN** 系统应利用 GPU 加速进行像素化处理
- **AND** 不出现程序卡死
- **AND** 不渲染灰色不可用状态
- **AND** 正确生成像素化预览
- **AND** 处理效率显著提升

### Requirement: 硬件加速像素化

系统 SHALL 充分利用硬件加速进行图片像素化处理。

#### Scenario: GPU 加速像素化

- **WHEN** 用户导入图片进行像素化处理
- **THEN** 系统应使用 GPU 加速算法
- **AND** 处理速度显著提升
- **AND** 支持 Isolate 多线程处理大图片

### Requirement: 3D 立体效果开关

系统 SHALL 提供 3D 立体效果开关选项。

#### Scenario: 切换 3D 效果

- **WHEN** 用户在设置中切换"显示拼豆立体效果"
- **THEN** 编辑器中的拼豆应显示或隐藏立体效果

### Requirement: 上帝模式增强

系统 SHALL 在上帝模式中提供更多高级选项。

#### Scenario: 上帝模式选项

- **WHEN** 用户启用上帝模式
- **THEN** 可以访问更多高级设置选项

### Requirement: 格子颜色代码显示

系统 SHALL 在绘制时直接在格子上显示颜色代码。

#### Scenario: 显示颜色代码

- **WHEN** 用户在编辑器中绘制拼豆
- **THEN** 格子上应显示颜色代码（当格子足够大时）

### Requirement: CSV/XLSX 智能解析

系统 SHALL 智能解析不符合格式的 CSV/XLSX 文件。

#### Scenario: 智能解析

- **WHEN** 用户导入不符合标准格式的 CSV/XLSX 文件
- **THEN** 系统尝试自动解析颜色和代码
- **AND** 无法解析时让用户选择列映射

### Requirement: Windows 标题修复

系统 SHALL 在 Windows 下正确显示中文标题。

#### Scenario: Windows 标题显示

- **WHEN** 应用在 Windows 下运行
- **THEN** 窗口标题应正确显示中文
- **AND** 不出现乱码

### Requirement: 更新日志限制

系统 SHALL 只保留最近 8 个版本的更新日志。

#### Scenario: 显示更新日志

- **WHEN** 用户查看更新日志
- **THEN** 只显示最近 8 个版本的更新内容

## MODIFIED Requirements

无

## REMOVED Requirements

无
