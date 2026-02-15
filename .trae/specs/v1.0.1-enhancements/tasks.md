# Tasks

- [x] Task 1: 修复设置开关问题
  - [x] SubTask 1.1: 检查 settings_screen.dart 中的开关实现
  - [x] SubTask 1.2: 检查 settings_service.dart 中的设置保存逻辑
  - [x] SubTask 1.3: 修复设置持久化问题
  - [x] SubTask 1.4: 验证设置开关正常工作

- [x] Task 2: 完善导入导出功能
  - [x] SubTask 2.1: 实现导出所有数据功能（设计和库存）
  - [x] SubTask 2.2: 实现导入数据功能
  - [x] SubTask 2.3: 添加数据格式兼容性处理
  - [x] SubTask 2.4: 添加导入导出进度提示

- [x] Task 3: 新增定位数据目录功能
  - [x] SubTask 3.1: 添加"打开数据目录"按钮
  - [x] SubTask 3.2: 实现跨平台打开目录功能（macOS/Windows）
  - [x] SubTask 3.3: 显示数据目录路径

- [x] Task 4: 新增国产拼豆品牌支持
  - [x] SubTask 4.1: 收集国产拼豆颜色数据（淘宝、拼多多系列）
  - [x] SubTask 4.2: 添加到 standard_colors.dart
  - [x] SubTask 4.3: 更新颜色库界面支持品牌筛选
  - [x] SubTask 4.4: 添加品牌分类标签

- [x] Task 5: 新增图片导入算法风格
  - [x] SubTask 5.1: 设计算法风格选项（像素艺术、卡通、写实等）
  - [x] SubTask 5.2: 实现像素艺术风格算法
  - [x] SubTask 5.3: 实现卡通风格算法
  - [x] SubTask 5.4: 实现写实风格算法
  - [x] SubTask 5.5: 更新图片导入界面添加风格选择

- [x] Task 6: 优化预览图交互
  - [x] SubTask 6.1: 实现点击格子显示颜色信息
  - [x] SubTask 6.2: 设计颜色信息弹窗UI
  - [x] SubTask 6.3: 显示颜色色号、名称、RGB值
  - [x] SubTask 6.4: 添加复制颜色信息功能

- [x] Task 7: 更新版本号和更新日志
  - [x] SubTask 7.1: 更新 pubspec.yaml 版本号为 1.0.1
  - [x] SubTask 7.2: 更新 changelog.json
  - [x] SubTask 7.3: 更新 settings_screen.dart 中的版本号

# Task Dependencies

- [Task 2] depends on [Task 1]
- [Task 3] 无依赖，可并行执行
- [Task 4] 无依赖，可并行执行
- [Task 5] 无依赖，可并行执行
- [Task 6] depends on [Task 5]
- [Task 7] depends on [Task 1, Task 2, Task 3, Task 4, Task 5, Task 6]
