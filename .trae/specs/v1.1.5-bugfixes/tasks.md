# Tasks

- [x] Task 1: 修复最近创作选项失效问题
  - [x] SubTask 1.1: 检查最近创作列表的导出功能
  - [x] SubTask 1.2: 检查最近创作列表的重命名功能
  - [x] SubTask 1.3: 检查最近创作列表的打开编辑功能
  - [x] SubTask 1.4: 修复所有失效问题

- [x] Task 2: 优化版本号点击流畅度
  - [x] SubTask 2.1: 检查当前点击计数逻辑
  - [x] SubTask 2.2: 优化点击响应和计数重置逻辑
  - [x] SubTask 2.3: 添加点击反馈动画

- [x] Task 3: 修复 macOS 网格居中和坐标显示问题
  - [x] SubTask 3.1: 检查网格居中计算逻辑
  - [x] SubTask 3.2: 检查坐标显示逻辑
  - [x] SubTask 3.3: 修复 macOS 特定问题

- [x] Task 4: 优化缩放和移动控制
  - [x] SubTask 4.1: 实现 WASD 键盘移动控制
  - [x] SubTask 4.2: 实现 QE 键盘缩放控制
  - [x] SubTask 4.3: 添加工具栏按钮控制
  - [x] SubTask 4.4: 实现自定义组合键设置
  - [x] SubTask 4.5: 禁用绘画时鼠标影响绘画的问题

- [x] Task 5: 新增更多实验性图片效果
  - [x] SubTask 5.1: 添加更多图片处理算法
  - [x] SubTask 5.2: 添加实验性效果选项 UI

- [x] Task 6: 修复崩溃问题
  - [x] SubTask 6.1: 检查并修复空指针异常
  - [x] SubTask 6.2: 检查并修复边界条件问题
  - [x] SubTask 6.3: 添加错误处理

- [x] Task 6.5: 修复开发者选项和实验性功能显示问题
  - [x] SubTask 6.5.1: 检查开发者选项显示逻辑
  - [x] SubTask 6.5.2: 检查实验性功能显示逻辑
  - [x] SubTask 6.5.3: 修复显示和功能问题

- [x] Task 7: 新增预览模式
  - [x] SubTask 7.1: 添加预览模式切换按钮
  - [x] SubTask 7.2: 实现预览模式下禁用绘画
  - [x] SubTask 7.3: 实现点击查看颜色信息

- [x] Task 8: 优化绘画流畅性
  - [x] SubTask 8.1: 优化绘画事件处理
  - [x] SubTask 8.2: 减少不必要的重绘
  - [x] SubTask 8.3: 优化渲染性能

- [x] Task 9: 优化自定义颜色输入
  - [x] SubTask 9.1: 支持颜色代码输入（#224294 格式）
  - [x] SubTask 9.2: 添加颜色代码验证
  - [x] SubTask 9.3: 添加颜色预览

- [x] Task 10: 优化滑动条流畅性
  - [x] SubTask 10.1: 检查滑动条实现
  - [x] SubTask 10.2: 优化滑动响应

- [x] Task 11: 更新版本号和更新日志
  - [x] SubTask 11.1: 更新 pubspec.yaml 版本号为 1.1.5
  - [x] SubTask 11.2: 更新 changelog.json
  - [x] SubTask 11.3: 更新 settings_screen.dart 中的版本号

# Task Dependencies

- [Task 2] 无依赖，可并行执行
- [Task 3] 无依赖，可并行执行
- [Task 4] 无依赖，可并行执行
- [Task 5] 无依赖，可并行执行
- [Task 7] 无依赖，可并行执行
- [Task 8] 无依赖，可并行执行
- [Task 9] 无依赖，可并行执行
- [Task 10] 无依赖，可并行执行
- [Task 11] depends on [Task 1, Task 2, Task 3, Task 4, Task 5, Task 6, Task 7, Task 8, Task 9, Task 10]
