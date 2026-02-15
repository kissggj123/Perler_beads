# Tasks

- [x] Task 1: 修复黑屏问题
  - [x] SubTask 1.1: 检查新建工程后返回的导航逻辑
  - [x] SubTask 1.2: 检查导入图片后返回的导航逻辑
  - [x] SubTask 1.3: 修复导航问题
  - [x] SubTask 1.4: 验证返回后正确显示主界面

- [x] Task 2: 修复图片导入灰色问题
  - [x] SubTask 2.1: 检查图片导入处理逻辑
  - [x] SubTask 2.2: 检查预览生成逻辑
  - [x] SubTask 2.3: 修复灰色不可用状态问题
  - [x] SubTask 2.4: 添加大尺寸图片自动缩放处理
  - [x] SubTask 2.5: 添加图片尺寸限制和警告
  - [x] SubTask 2.6: 实现 GPU 加速像素化算法
  - [x] SubTask 2.7: 实现 Isolate 多线程处理大图片
  - [x] SubTask 2.8: 验证各种图片格式正常导入

- [x] Task 3: 新增 3D 立体效果开关
  - [x] SubTask 3.1: 在设置中添加"显示拼豆立体效果"开关
  - [x] SubTask 3.2: 在 settings_service.dart 中添加持久化
  - [x] SubTask 3.3: 修改 bead_canvas_widget.dart 支持开关
  - [x] SubTask 3.4: 验证开关正常工作

- [x] Task 4: 增强上帝模式
  - [x] SubTask 4.1: 添加更多上帝模式选项
  - [x] SubTask 4.2: 添加高级调试功能
  - [x] SubTask 4.3: 添加隐藏功能入口

- [x] Task 5: 优化格子颜色代码显示
  - [x] SubTask 5.1: 在 bead_canvas_widget.dart 中添加颜色代码显示
  - [x] SubTask 5.2: 根据格子大小决定是否显示
  - [x] SubTask 5.3: 验证显示效果

- [x] Task 6: 优化 CSV/XLSX 智能解析
  - [x] SubTask 6.1: 实现智能列检测算法
  - [x] SubTask 6.2: 添加列映射选择界面
  - [x] SubTask 6.3: 验证各种格式文件解析

- [x] Task 7: 修复 Windows 标题乱码
  - [x] SubTask 7.1: 检查 Windows main.cpp 编码问题
  - [x] SubTask 7.2: 修复 UTF-8 编码设置
  - [x] SubTask 7.3: 验证 Windows 标题正确显示

- [x] Task 8: 更新日志限制为 8 个
  - [x] SubTask 8.1: 修改更新日志显示逻辑
  - [x] SubTask 8.2: 只显示最近 8 个版本

- [x] Task 9: 更新版本号和更新日志
  - [x] SubTask 9.1: 更新 pubspec.yaml 版本号为 1.1.2
  - [x] SubTask 9.2: 更新 changelog.json
  - [x] SubTask 9.3: 更新 settings_screen.dart 中的版本号

# Task Dependencies

- [Task 3] 无依赖，可并行执行
- [Task 4] 无依赖，可并行执行
- [Task 5] 无依赖，可并行执行
- [Task 6] 无依赖，可并行执行
- [Task 7] 无依赖，可并行执行
- [Task 9] depends on [Task 1, Task 2, Task 3, Task 4, Task 5, Task 6, Task 7, Task 8]
