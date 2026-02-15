# Tasks

- [x] Task 1: 项目初始化与环境配置
  - [x] SubTask 1.1: 创建Flutter项目并配置macOS和Windows平台支持
  - [x] SubTask 1.2: 配置项目依赖（image, file_picker, pdf, shared_preferences, provider）
  - [x] SubTask 1.3: 设置项目目录结构和代码规范

- [x] Task 2: 数据模型设计
  - [x] SubTask 2.1: 创建拼豆颜色模型（BeadColor）
  - [x] SubTask 2.2: 创建库存模型（Inventory）
  - [x] SubTask 2.3: 创建设计图模型（BeadDesign）
  - [x] SubTask 2.4: 创建颜色库模型（ColorPalette）

- [x] Task 3: 本地存储服务
  - [x] SubTask 3.1: 实现库存数据存储服务
  - [x] SubTask 3.2: 实现设计图存储服务
  - [x] SubTask 3.3: 实现应用设置存储服务

- [x] Task 4: 拼豆颜色库模块
  - [x] SubTask 4.1: 创建内置标准拼豆颜色库数据
  - [x] SubTask 4.2: 实现颜色库管理功能（查看、添加、删除自定义颜色）
  - [x] SubTask 4.3: 实现颜色搜索和筛选功能

- [x] Task 5: 库存管理模块
  - [x] SubTask 5.1: 创建库存列表UI界面
  - [x] SubTask 5.2: 实现CSV/JSON文件导入功能
  - [x] SubTask 5.3: 实现手动添加/编辑拼豆库存功能
  - [x] SubTask 5.4: 实现库存导出功能

- [x] Task 6: 图片处理模块
  - [x] SubTask 6.1: 实现图片文件选择和加载
  - [x] SubTask 6.2: 实现图片尺寸调整和像素化处理
  - [x] SubTask 6.3: 实现颜色匹配算法（将图片颜色映射到拼豆颜色）
  - [x] SubTask 6.4: 实现拼豆设计图生成

- [x] Task 7: 设计编辑器模块
  - [x] SubTask 7.1: 创建设计编辑器UI界面（网格显示）
  - [x] SubTask 7.2: 实现单个拼豆选择和编辑功能
  - [x] SubTask 7.3: 实现拼豆数量统计和显示
  - [x] SubTask 7.4: 实现库存对比和不足提示

- [x] Task 8: 内置模型/插件系统
  - [x] SubTask 8.1: 设计插件接口规范
  - [x] SubTask 8.2: 实现基础颜色优化算法（内置模型）
  - [x] SubTask 8.3: 实现插件加载和管理机制

- [x] Task 9: 导出功能模块
  - [x] SubTask 9.1: 实现设计图导出为PNG
  - [x] SubTask 9.2: 实现设计图导出为PDF
  - [x] SubTask 9.3: 实现材料清单导出（CSV/PDF）

- [x] Task 10: 主界面和导航
  - [x] SubTask 10.1: 创建主界面布局（侧边栏导航）
  - [x] SubTask 10.2: 实现主题切换功能（深色/浅色）
  - [x] SubTask 10.3: 实现各模块页面路由
  - [x] SubTask 10.4: 修复首页导入图片按钮导航到ImageImportScreen
  - [x] SubTask 10.5: 修复创建设计后导航到DesignEditorScreen
  - [x] SubTask 10.6: 修复设计列表点击导航到DesignEditorScreen
  - [x] SubTask 10.7: 修复库存概览显示真实库存数据

- [x] Task 11: 测试与优化
  - [x] SubTask 11.1: 验证所有导航功能正常工作
  - [x] SubTask 11.2: 验证导入图片完整流程
  - [x] SubTask 11.3: 验证设计编辑器完整功能
  - [x] SubTask 11.4: macOS和Windows平台测试

# Task Dependencies

- [Task 2] depends on [Task 1]
- [Task 3] depends on [Task 2]
- [Task 4] depends on [Task 2]
- [Task 5] depends on [Task 3, Task 4]
- [Task 6] depends on [Task 4]
- [Task 7] depends on [Task 6]
- [Task 8] depends on [Task 6, Task 7]
- [Task 9] depends on [Task 7]
- [Task 10] depends on [Task 1]
- [Task 11] depends on [Task 5, Task 6, Task 7, Task 8, Task 9, Task 10]
