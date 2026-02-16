# 拼豆设计器 v2.1.0 创世神版本 - 实现计划

## [x] Task 1: 优化坐标显示功能

- **Priority**: P0
- **Depends On**: None
- **Description**:
  - 修改 `_drawCoordinates` 方法，显示每个格子的坐标
  - 优化坐标显示样式，更醒目、更清晰
  - 调整坐标位置，顶部和左侧都有明显的坐标显示
- **Acceptance Criteria Addressed**: AC-1, AC-2, AC-3
- **Test Requirements**:
  - `human-judgment` TR-1.1: 验证所有格子都有坐标显示
  - `human-judgment` TR-1.2: 验证坐标显示在顶部和左侧
  - `human-judgment` TR-1.3: 验证坐标显示清晰易读
- **Notes**: 修改 `bead_canvas_widget.dart` 中的 `_drawCoordinates` 方法

## [x] Task 2: 优化格子内颜色代号显示

- **Priority**: P0
- **Depends On**: None
- **Description**:
  - 优化 `_drawColorCodes` 方法
  - 确保颜色代号在格子内居中显示
  - 根据颜色深浅自动调整文字颜色
- **Acceptance Criteria Addressed**: AC-4
- **Test Requirements**:
  - `human-judgment` TR-2.1: 验证颜色代号清晰可见
  - `human-judgment` TR-2.2: 验证颜色代号位置正确
- **Notes**: 检查 `bead_canvas_widget.dart` 中的 `_drawColorCodes` 方法

## [x] Task 3: 实现撤销/重做快捷键

- **Priority**: P0
- **Depends On**: None
- **Description**:
  - 添加 Ctrl+Z / Cmd+Z 撤销快捷键
  - 添加 Ctrl+Y / Cmd+Shift+Z 重做快捷键
  - 确保双平台快捷键正确适配
- **Acceptance Criteria Addressed**: AC-5
- **Test Requirements**:
  - `programmatic` TR-3.1: Windows 上 Ctrl+Z 触发撤销
  - `programmatic` TR-3.2: macOS 上 Cmd+Z 触发撤销
  - `programmatic` TR-3.3: Windows 上 Ctrl+Y 触发重做
  - `programmatic` TR-3.4: macOS 上 Cmd+Shift+Z 触发重做
- **Notes**: 修改 `design_editor_screen.dart` 添加键盘监听

## [x] Task 4: 实现自动保存功能

- **Priority**: P1
- **Depends On**: None
- **Description**:
  - 添加自动保存定时器
  - 自动保存间隔可配置（默认 30 秒）
  - 自动保存状态指示器
- **Acceptance Criteria Addressed**: AC-6
- **Test Requirements**:
  - `programmatic` TR-4.1: 自动保存定时器正确触发
  - `human-judgment` TR-4.2: 自动保存状态指示器显示正确
- **Notes**: 修改 `design_editor_provider.dart` 和 `design_editor_screen.dart`

## [x] Task 5: 实现历史记录面板

- **Priority**: P1
- **Depends On**: Task 3
- **Description**:
  - 创建历史记录面板组件
  - 显示操作历史列表
  - 支持点击跳转到任意历史状态
- **Acceptance Criteria Addressed**: AC-7
- **Test Requirements**:
  - `human-judgment` TR-5.1: 历史记录面板正确显示操作列表
  - `programmatic` TR-5.2: 点击历史记录可跳转到对应状态
- **Notes**: 创建 `lib/widgets/history_panel.dart`

## [x] Task 6: 实现快捷键自定义功能

- **Priority**: P1
- **Depends On**: Task 3
- **Description**:
  - 创建快捷键设置界面
  - 支持自定义所有快捷键绑定
  - 支持重置为默认值
- **Acceptance Criteria Addressed**: AC-8
- **Test Requirements**:
  - `human-judgment` TR-6.1: 快捷键设置界面正确显示
  - `programmatic` TR-6.2: 自定义快捷键正确保存和加载
  - `programmatic` TR-6.3: 重置功能正确恢复默认值
- **Notes**: 修改 `settings_screen.dart` 和 `settings_service.dart`

## [x] Task 7: 实现界面参数自定义

- **Priority**: P1
- **Depends On**: None
- **Description**:
  - 添加格子大小自定义选项
  - 添加网格颜色自定义选项
  - 添加坐标字体大小自定义选项
  - 添加实时预览功能
- **Acceptance Criteria Addressed**: AC-9
- **Test Requirements**:
  - `human-judgment` TR-7.1: 界面参数设置正确显示
  - `programmatic` TR-7.2: 参数修改实时生效
  - `programmatic` TR-7.3: 参数正确持久化保存
- **Notes**: 修改 `app_provider.dart` 和 `settings_screen.dart`

## [x] Task 8: 实现性能参数自定义

- **Priority**: P1
- **Depends On**: None
- **Description**:
  - 添加 FPS 限制自定义选项
  - 添加缓存大小自定义选项
  - 添加 GPU 加速开关
- **Acceptance Criteria Addressed**: AC-10
- **Test Requirements**:
  - `human-judgment` TR-8.1: 性能参数设置正确显示
  - `programmatic` TR-8.2: FPS 限制正确生效
  - `programmatic` TR-8.3: 缓存大小正确限制
- **Notes**: 修改 `performance_service.dart` 和 `settings_screen.dart`

## [x] Task 9: 实现编辑器参数自定义

- **Priority**: P1
- **Depends On**: Task 4
- **Description**:
  - 添加自动保存间隔自定义选项
  - 添加历史记录数量自定义选项
  - 添加画布默认尺寸自定义选项
- **Acceptance Criteria Addressed**: AC-11
- **Test Requirements**:
  - `human-judgment` TR-9.1: 编辑器参数设置正确显示
  - `programmatic` TR-9.2: 自动保存间隔正确生效
  - `programmatic` TR-9.3: 历史记录数量正确限制
- **Notes**: 修改 `design_editor_provider.dart` 和 `settings_screen.dart`

## [x] Task 10: 实现双平台兼容性

- **Priority**: P0
- **Depends On**: Task 3, Task 6
- **Description**:
  - 添加平台检测工具类
  - 实现快捷键平台自动适配
  - 实现文件路径平台兼容
  - 添加平台功能降级机制
- **Acceptance Criteria Addressed**: AC-12
- **Test Requirements**:
  - `programmatic` TR-10.1: 平台检测正确返回当前平台
  - `programmatic` TR-10.2: Windows 快捷键使用 Ctrl
  - `programmatic` TR-10.3: macOS 快捷键使用 Cmd
  - `programmatic` TR-10.4: 文件路径在双平台正确处理
- **Notes**: 创建 `lib/utils/platform_utils.dart`

## [x] Task 11: 实现智能抠图功能

- **Priority**: P0
- **Depends On**: None
- **Description**:
  - 实现自动主体识别算法（基于颜色差异、边缘检测）
  - 创建抠图预览界面
  - 实现手动抠图调整工具（画笔添加/擦除）
  - 实现背景透明化处理
- **Acceptance Criteria Addressed**: AC-13
- **Test Requirements**:
  - `human-judgment` TR-11.1: 自动抠图能正确识别主体
  - `human-judgment` TR-11.2: 抠图预览正确显示
  - `programmatic` TR-11.3: 手动调整工具正常工作
  - `programmatic` TR-11.4: 背景正确透明化
- **Notes**: 修改 `image_processing_service.dart` 和 `image_import_screen.dart`

## [x] Task 12: 实现主题色全自定义

- **Priority**: P1
- **Depends On**: None
- **Description**:
  - 创建主题色选择界面
  - 实现主色调、次色调、强调色自定义
  - 实现自定义配色方案保存和切换
  - 提供多种预设主题
- **Acceptance Criteria Addressed**: AC-14
- **Test Requirements**:
  - `human-judgment` TR-12.1: 主题色设置界面正确显示
  - `programmatic` TR-12.2: 主题色修改实时生效
  - `programmatic` TR-12.3: 配色方案正确保存和加载
  - `programmatic` TR-12.4: 预设主题切换正常工作
- **Notes**: 修改 `main.dart`、`app_provider.dart` 和 `settings_screen.dart`

## [x] Task 13: 优化窗口布局

- **Priority**: P1
- **Depends On**: None
- **Description**:
  - 实现响应式布局适配
  - 设置最小窗口尺寸限制
  - 实现侧边栏自动折叠功能
  - 优化各界面元素的布局约束
- **Acceptance Criteria Addressed**: AC-15
- **Test Requirements**:
  - `human-judgment` TR-13.1: 窗口缩小时布局不挤压
  - `programmatic` TR-13.2: 最小窗口尺寸限制生效
  - `programmatic` TR-13.3: 侧边栏自动折叠正常工作
- **Notes**: 修改 `main_layout.dart` 和相关界面文件

## [x] Task 14: 修复已知问题

- **Priority**: P0
- **Depends On**: None
- **Description**:
  - 全面测试所有功能
  - 修复发现的功能问题
  - 优化错误处理机制
  - 确保数据完整性
- **Acceptance Criteria Addressed**: AC-16
- **Test Requirements**:
  - `programmatic` TR-14.1: 所有功能正常可用
  - `programmatic` TR-14.2: 错误提示友好且不影响其他功能
  - `programmatic` TR-14.3: 数据保存完整
- **Notes**: 全面测试并修复问题

## [x] Task 15: 更新版本号和更新日志

- **Priority**: P1
- **Depends On**: Task 1-14
- **Description**:
  - 更新 pubspec.yaml 版本号到 2.1.0
  - 更新 settings_screen.dart 中的 appVersion
  - 更新 changelog.json 添加 v2.1.0 记录
- **Acceptance Criteria Addressed**: AC-17
- **Test Requirements**:
  - `programmatic` TR-15.1: 验证版本号正确更新
  - `programmatic` TR-15.2: 验证更新日志正确添加
- **Notes**: 更新三个文件：pubspec.yaml, settings_screen.dart, changelog.json

## Task Dependencies

```
Task 1 ──────────────────────────────────────────────────────┐
Task 2 ──────────────────────────────────────────────────────┤
Task 3 ──┬── Task 5 (历史记录面板) ───────────────────────────┤
         └── Task 6 (快捷键自定义) ──┐                         │
Task 4 ─────────────────────────────┼── Task 9 ───────────────┤
Task 7 ─────────────────────────────┤                         │
Task 8 ─────────────────────────────┤                         │
Task 10 (双平台兼容) ───────────────┘                         │
Task 11 (智能抠图) ────────────────────────────────────────────┤
Task 12 (主题色自定义) ────────────────────────────────────────┤
Task 13 (窗口布局优化) ────────────────────────────────────────┤
Task 14 (修复已知问题) ────────────────────────────────────────┤
                                                              ▼
                                                         Task 15 (版本更新)
```
