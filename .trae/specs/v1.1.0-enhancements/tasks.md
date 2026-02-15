# Tasks

- [x] Task 1: 修复任务栏图标问题
  - [x] SubTask 1.1: 检查 macOS 任务栏图标配置
  - [x] SubTask 1.2: 检查 Windows 任务栏图标配置
  - [x] SubTask 1.3: 配置正确的应用图标资源
  - [x] SubTask 1.4: 验证任务栏图标正确显示

- [x] Task 2: 修复设置页选项无法修改的问题
  - [x] SubTask 2.1: 检查设置页所有开关和选项的实现
  - [x] SubTask 2.2: 检查 settings_service.dart 的保存逻辑
  - [x] SubTask 2.3: 修复所有设置项的持久化问题
  - [x] SubTask 2.4: 验证所有设置选项正常工作

- [x] Task 3: 新增上帝模式
  - [x] SubTask 3.1: 实现连续点击版本号 7 次触发上帝模式
  - [x] SubTask 3.2: 创建上帝模式设置选项 UI
  - [x] SubTask 3.3: 添加调试模式选项
  - [x] SubTask 3.4: 添加性能监控选项
  - [x] SubTask 3.5: 添加实验性功能选项
  - [x] SubTask 3.6: 添加动画效果开关

- [x] Task 4: GPU 加速优化
  - [x] SubTask 4.1: 配置 Flutter Impeller 渲染引擎
  - [x] SubTask 4.2: 启用 macOS Metal 加速
  - [x] SubTask 4.3: 启用 Windows Vulkan/DirectX 加速
  - [x] SubTask 4.4: 添加性能优化配置选项

- [x] Task 5: 新增界面动画效果
  - [x] SubTask 5.1: 添加页面切换动画
  - [x] SubTask 5.2: 添加卡片交互动画
  - [x] SubTask 5.3: 添加按钮点击动画
  - [x] SubTask 5.4: 添加列表项动画
  - [x] SubTask 5.5: 添加加载动画

- [x] Task 6: 更新版本号和更新日志
  - [x] SubTask 6.1: 更新 pubspec.yaml 版本号为 1.1.0
  - [x] SubTask 6.2: 更新 changelog.json
  - [x] SubTask 6.3: 更新 settings_screen.dart 中的版本号

# Task Dependencies

- [Task 2] depends on [Task 1]
- [Task 3] depends on [Task 2]
- [Task 4] 无依赖，可并行执行
- [Task 5] 无依赖，可并行执行
- [Task 6] depends on [Task 1, Task 2, Task 3, Task 4, Task 5]
