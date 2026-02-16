# 拼豆设计器 v2.1.2 完整重写版本 - 任务列表

## Phase 0: 崩溃问题修复

### [x] Task 0.1: 修复图片缩放崩溃问题

- **Priority**: P0
- **Description**:
  - 定位导入图片后缩放崩溃的根本原因
  - 修复缩放时的空指针或越界问题
  - 添加缩放操作的安全检查
- **Notes**: 检查 `bead_canvas_widget.dart` 和 `design_editor_provider.dart`

### [x] Task 0.2: 修复其他潜在崩溃问题

- **Priority**: P0
- **Description**:
  - 全面检查代码中的空指针风险
  - 添加边界检查
  - 优化异常处理机制
- **Notes**: 全面代码审查

## Phase 1: 核心显示功能重写

### [x] Task 1: 重写坐标显示功能

- **Priority**: P0
- **Description**:
  - 重写 `_drawCoordinates` 方法
  - 顶部显示列坐标，左侧显示行坐标
  - 坐标显示清晰易读
- **Notes**: 修改 `lib/widgets/bead_canvas_widget.dart`

### [x] Task 2: 重写格子内颜色代号显示

- **Priority**: P0
- **Description**:
  - 重写 `_drawColorCodes` 方法
  - 颜色代号居中显示
  - 根据背景色自动调整文字颜色
- **Notes**: 修改 `lib/widgets/bead_canvas_widget.dart`

## Phase 2: 人性化编辑器功能

### [x] Task 3: 重写撤销/重做快捷键

- **Priority**: P0
- **Description**:
  - 添加键盘监听器
  - Windows: Ctrl+Z/Y，macOS: Cmd+Z/Shift+Z
- **Notes**: 修改 `lib/screens/design_editor_screen.dart`

### [x] Task 4: 重写自动保存功能

- **Priority**: P1
- **Description**:
  - 添加自动保存定时器
  - 自动保存间隔可配置
- **Notes**: 修改 `lib/providers/design_editor_provider.dart`

### [x] Task 5: 重写历史记录面板

- **Priority**: P1
- **Depends On**: Task 3
- **Description**:
  - 创建历史记录面板组件
  - 支持点击跳转到任意历史状态
- **Notes**: 创建 `lib/widgets/history_panel.dart`

### [x] Task 6: 重写快捷键自定义功能

- **Priority**: P1
- **Depends On**: Task 3
- **Description**:
  - 创建快捷键设置界面
  - 支持自定义和重置
- **Notes**: 修改 `lib/screens/settings_screen.dart`

## Phase 3: 参数自定义功能

### [x] Task 7: 重写界面参数自定义

- **Priority**: P1
- **Description**:
  - 格子大小、网格颜色、坐标字体大小自定义
- **Notes**: 修改 `lib/providers/app_provider.dart`

### [x] Task 8: 重写性能参数自定义

- **Priority**: P1
- **Description**:
  - FPS 限制、缓存大小、GPU 加速开关
- **Notes**: 修改 `lib/services/performance_service.dart`

### [x] Task 9: 重写编辑器参数自定义

- **Priority**: P1
- **Depends On**: Task 4
- **Description**:
  - 自动保存间隔、历史记录数量、画布默认尺寸
- **Notes**: 修改 `lib/providers/design_editor_provider.dart`

## Phase 4: 双平台兼容性

### [x] Task 10: 重写双平台兼容性

- **Priority**: P0
- **Depends On**: Task 3, Task 6
- **Description**:
  - 平台检测、快捷键适配、文件路径兼容
- **Notes**: 创建 `lib/utils/platform_utils.dart`

## Phase 5: 智能抠图功能

### [x] Task 11: 重写智能抠图功能

- **Priority**: P0
- **Description**:
  - 自动主体识别算法
  - 手动抠图调整工具
- **Notes**: 修改 `lib/services/image_processing_service.dart`

## Phase 6: 主题色自定义

### [x] Task 12: 重写主题色全自定义

- **Priority**: P1
- **Description**:
  - 主题色选择界面
  - 预设主题切换
- **Notes**: 修改 `lib/main.dart` 和 `lib/providers/app_provider.dart`

## Phase 7: 窗口布局优化

### [x] Task 13: 重写窗口布局优化

- **Priority**: P1
- **Description**:
  - 响应式布局、最小窗口尺寸、侧边栏折叠
- **Notes**: 修改 `lib/main.dart` 和 `lib/widgets/main_layout.dart`

## Phase 8: 创作性工具

### [x] Task 14: 实现镜像工具

- **Priority**: P1
- **Description**:
  - 水平/垂直镜像功能
- **Notes**: 修改 `lib/providers/design_editor_provider.dart`

### [x] Task 15: 实现旋转工具

- **Priority**: P1
- **Description**:
  - 90°/180° 旋转功能
- **Notes**: 修改 `lib/providers/design_editor_provider.dart`

### [x] Task 16: 实现复制/粘贴选区功能

- **Priority**: P1
- **Description**:
  - 矩形选区、复制粘贴
- **Notes**: 修改 `lib/providers/design_editor_provider.dart`

## Phase 9: PDF 中文支持优化

### [x] Task 17: 创建字体服务

- **Priority**: P1
- **Description**:
  - 系统字体检测
  - 字体加载优先级
- **Notes**: 创建 `lib/services/font_service.dart`

### [x] Task 18: 优化字体下载策略

- **Priority**: P1
- **Depends On**: Task 17
- **Description**:
  - 中国大陆镜像源
  - 系统代理检测
- **Notes**: 修改 `lib/services/font_service.dart`

### [x] Task 19: 优化 PDF 坐标布局

- **Priority**: P1
- **Depends On**: Task 17
- **Description**:
  - 坐标区域宽度、字体大小优化
- **Notes**: 修改 `lib/utils/pdf_generator.dart`

## Phase 10: 最近创作面板优化

### [x] Task 20: 优化最近创作面板

- **Priority**: P1
- **Description**:
  - 重命名、删除、排序、预览图、详细信息
- **Notes**: 修改 `lib/screens/home_screen.dart`

## Phase 11: GPU 加速动画

### [x] Task 21: 创建 GPU 动画服务

- **Priority**: P2
- **Description**:
  - GPU 加速粒子效果
  - 动画效果开关
- **Notes**: 创建 `lib/services/gpu_animation_service.dart`

### [x] Task 22: 集成 GPU 动画到界面

- **Priority**: P2
- **Depends On**: Task 21
- **Description**:
  - 粒子效果、界面切换动画
- **Notes**: 修改相关界面文件

## Phase 12: 许可协议和说明

### [x] Task 23: 创建许可协议界面

- **Priority**: P1
- **Description**:
  - 软件许可协议、开源组件许可
- **Notes**: 创建 `lib/screens/license_screen.dart`

### [x] Task 24: 创建欢迎/说明界面

- **Priority**: P1
- **Depends On**: Task 23
- **Description**:
  - 应用功能介绍、使用指南
- **Notes**: 创建 `lib/screens/welcome_screen.dart`

## Phase 13: 拼豆数量精准计算

### [x] Task 25: 创建拼豆计算服务

- **Priority**: P1
- **Description**:
  - 创建 `BeadCountService` 服务
  - 实现容差计算算法（考虑边缘损耗、颜色差异等）
  - 创建 `BeadCountResult` 模型（包含推荐数量和容差范围）
- **Acceptance Criteria**:
  - 拼豆数量计算包含容差范围
  - 容差计算合理（如 ±5%）
- **Notes**: 创建 `lib/services/bead_count_service.dart` 和 `lib/models/bead_count_result.dart`

### [x] Task 26: 集成拼豆计算到界面

- **Priority**: P1
- **Depends On**: Task 25
- **Description**:
  - 编辑时实时更新拼豆数量
  - 显示容差范围（如 "红色: 100±5 颗"）
  - 材料清单显示容差
- **Notes**: 修改 `lib/screens/design_editor_screen.dart` 和 `lib/widgets/material_list_dialog.dart`

## Phase 14: 版本检查更新

### [x] Task 27: 创建版本检查服务

- **Priority**: P1
- **Description**:
  - 创建 `VersionCheckService` 服务
  - 从 GitHub Releases API 获取最新版本
  - 比较版本号判断是否需要更新
  - 获取更新日志和下载链接
- **Acceptance Criteria**:
  - 正确获取 GitHub 最新版本
  - 版本比较逻辑正确
- **Notes**: 创建 `lib/services/version_check_service.dart`

### [x] Task 28: 创建更新下载安装服务

- **Priority**: P1
- **Depends On**: Task 27
- **Description**:
  - 创建 `UpdateService` 服务
  - 实现更新包下载功能（支持进度显示）
  - 实现自动解压功能
  - 实现自动安装/替换功能
  - 支持下载暂停和继续
- **Acceptance Criteria**:
  - 更新包下载正常
  - 下载进度正确显示
  - 自动安装功能正常
- **Notes**: 创建 `lib/services/update_service.dart`

### [x] Task 29: 集成版本检查和更新到应用

- **Priority**: P1
- **Depends On**: Task 28
- **Description**:
  - 应用启动时自动检查更新
  - 设置页面添加手动检查更新按钮
  - 显示更新提示对话框（包含更新日志）
  - 添加下载进度显示
  - 添加安装确认对话框
  - 支持跳过此版本
- **Acceptance Criteria**:
  - 启动时自动检查
  - 手动检查功能正常
  - 下载进度正确显示
  - 自动安装功能正常
- **Notes**: 修改 `lib/main.dart` 和 `lib/screens/settings_screen.dart`

## Phase 15: 3D拼装动画功能（实验性）

### [x] Task 30: 创建3D拼装动画服务

- **Priority**: P2
- **Description**:
  - 同色系格子位置计算
  - 放置顺序算法
- **Notes**: 创建 `lib/services/assembly_guide_service.dart`

### [x] Task 31: 创建3D拼装动画组件

- **Priority**: P2
- **Depends On**: Task 30
- **Description**:
  - 3D拼豆模型渲染
  - 拼装动画效果
- **Notes**: 创建 `lib/widgets/assembly_guide_widget.dart`

### [x] Task 32: 集成3D拼装动画到编辑器

- **Priority**: P2
- **Depends On**: Task 31
- **Description**:
  - 点击格子触发动画
  - 动画控制按钮
- **Notes**: 修改 `lib/screens/design_editor_screen.dart`

## Phase 16: Bug 修复和测试

### [x] Task 33: 全面测试和修复

- **Priority**: P0
- **Depends On**: Task 0.1-32
- **Description**:
  - 全面测试所有功能
  - 修复发现的问题
- **Notes**: 全面测试

## Phase 17: 发布和同步

### [x] Task 34: 更新版本号和更新日志

- **Priority**: P1
- **Depends On**: Task 0.1-33
- **Description**:
  - 更新 pubspec.yaml 版本号到 2.1.2
  - 更新 settings_screen.dart 中的 appVersion
  - 更新 changelog.json 添加 v2.1.2 记录
- **Notes**: 更新三个文件

### [x] Task 35: 构建应用

- **Priority**: P1
- **Depends On**: Task 34
- **Description**:
  - 构建 macOS 应用
  - 构建 Windows 应用
  - 测试构建结果
- **Notes**: 使用 flutter build 命令

### [x] Task 36: 同步到 GitHub 仓库

- **Priority**: P1
- **Depends On**: Task 35
- **Description**:
  - 提交所有更改到 Git
  - 推送到 GitHub 仓库
  - 创建 GitHub Release
  - 上传构建文件
- **Notes**: 使用 git 命令和 GitHub API

## Task Dependencies

```
Task 0.1, 0.2 (崩溃修复) ────────────────────────────────────────────┐
Task 1-16 (核心功能重写) ─────────────────────────────────────────────┤
Task 17-19 (PDF中文支持) ─────────────────────────────────────────────┤
Task 20 (最近创作面板) ───────────────────────────────────────────────┤
Task 21-22 (GPU动画) ─────────────────────────────────────────────────┤
Task 23-24 (许可协议) ────────────────────────────────────────────────┤
Task 25-26 (拼豆计算优化) ────────────────────────────────────────────┤
Task 27-29 (版本检查更新) ────────────────────────────────────────────┤
Task 30-32 (3D拼装动画) ──────────────────────────────────────────────┤
                                                                       ▼
Task 33 (Bug修复) ─────────────────────────────────────────────────────┤
                                                                       ▼
Task 34 (版本更新) ─── Task 35 (构建) ─── Task 36 (GitHub同步) ────────┘
```
