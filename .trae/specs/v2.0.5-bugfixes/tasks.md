# Tasks

- [x] Task 1: 修复导出文档功能错误
  - [x] SubTask 1.1: 定位导出功能代码位置
  - [x] SubTask 1.2: 修复 FileType.custom 问题
  - [x] SubTask 1.3: 验证导出功能正常工作

- [x] Task 2: 修复缩放移动功能失效问题
  - [x] SubTask 2.1: 检查缩放移动相关代码
  - [x] SubTask 2.2: 修复缩放移动功能
  - [x] SubTask 2.3: 验证缩放移动正常工作

- [x] Task 3: 优化导入图片尺寸自动计算
  - [x] SubTask 3.1: 分析图片宽高比计算逻辑
  - [x] SubTask 3.2: 实现自动计算适合尺寸功能
  - [x] SubTask 3.3: 添加推荐尺寸显示

- [x] Task 4: 新增 GPU 加速图像调整
  - [x] SubTask 4.1: 实现自动图像调整功能
  - [x] SubTask 4.2: 优化 GPU 加速处理
  - [x] SubTask 4.3: 验证处理效果

- [x] Task 5: 测试所有功能
  - [x] SubTask 5.1: 测试导入图片功能
  - [x] SubTask 5.2: 测试设计编辑功能
  - [x] SubTask 5.3: 测试导出功能
  - [x] SubTask 5.4: 测试库存管理功能
  - [x] SubTask 5.5: 测试设置功能

- [x] Task 6: 更新版本号和更新日志
  - [x] SubTask 6.1: 更新 pubspec.yaml 版本号为 2.0.5
  - [x] SubTask 6.2: 更新 changelog.json
  - [x] SubTask 6.3: 更新 settings_screen.dart 中的版本号

# Task Dependencies

- [Task 1] 无依赖，可并行执行
- [Task 2] 无依赖，可并行执行
- [Task 3] 无依赖，可并行执行
- [Task 4] 无依赖，可并行执行
- [Task 5] depends on [Task 1, Task 2, Task 3, Task 4]
- [Task 6] depends on [Task 5]
