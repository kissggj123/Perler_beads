# Tasks

- [x] Task 1: 应用品牌化配置
  - [x] SubTask 1.1: 重写 macOS 应用配置（AppInfo.xcconfig）- 标题"兔可可的拼豆世界"
  - [x] SubTask 1.2: 重写 Windows 应用配置 - 标题和包名
  - [x] SubTask 1.3: 修改 pubspec.yaml 包名为 com.bunnycc.perler
  - [x] SubTask 1.4: 创建图标设置指南文档

- [x] Task 2: 关于软件和更新日志
  - [x] SubTask 2.1: 创建关于软件对话框组件
  - [x] SubTask 2.2: 创建更新日志数据模型
  - [x] SubTask 2.3: 创建更新日志页面组件
  - [x] SubTask 2.4: 在设置页面添加入口

- [x] Task 3: 重写新建设计功能
  - [x] SubTask 3.1: 重写新建设计对话框UI
  - [x] SubTask 3.2: 实现设计创建逻辑
  - [x] SubTask 3.3: 实现创建后导航到编辑器
  - [x] SubTask 3.4: 实现设计自动保存

- [x] Task 4: 重写导入图片功能
  - [x] SubTask 4.1: 重写图片选择界面
  - [x] SubTask 4.2: 实现图片预览组件
  - [x] SubTask 4.3: 实现尺寸设置功能
  - [x] SubTask 4.4: 实现颜色匹配算法
  - [x] SubTask 4.5: 实现设计生成逻辑
  - [x] SubTask 4.6: 实现生成后导航到编辑器

- [x] Task 5: 重写设计编辑器
  - [x] SubTask 5.1: 重写网格显示组件
  - [x] SubTask 5.2: 重写颜色选择面板
  - [x] SubTask 5.3: 实现绘制工具
  - [x] SubTask 5.4: 实现擦除工具
  - [x] SubTask 5.5: 实现填充工具
  - [x] SubTask 5.6: 实现撤销/重做功能
  - [x] SubTask 5.7: 重写统计面板
  - [x] SubTask 5.8: 实现库存对比功能
  - [x] SubTask 5.9: 实现保存功能

- [x] Task 6: 重写库存管理
  - [x] SubTask 6.1: 重写库存列表UI
  - [x] SubTask 6.2: 实现添加库存功能
  - [x] SubTask 6.3: 实现编辑库存功能
  - [x] SubTask 6.4: 实现删除库存功能
  - [x] SubTask 6.5: 实现CSV导入功能
  - [x] SubTask 6.6: 实现JSON导入功能
  - [x] SubTask 6.7: 实现CSV导出功能
  - [x] SubTask 6.8: 实现JSON导出功能

- [x] Task 7: 重写颜色库
  - [x] SubTask 7.1: 重写颜色库显示UI
  - [x] SubTask 7.2: 实现添加自定义颜色功能
  - [x] SubTask 7.3: 实现颜色搜索功能

- [x] Task 8: 重写导出功能
  - [x] SubTask 8.1: 实现PNG导出
  - [x] SubTask 8.2: 实现PDF导出
  - [x] SubTask 8.3: 实现材料清单CSV导出
  - [x] SubTask 8.4: 实现材料清单PDF导出

- [x] Task 9: 重写插件系统
  - [x] SubTask 9.1: 重写插件面板UI
  - [x] SubTask 9.2: 重写颜色优化插件
  - [x] SubTask 9.3: 重写抖动插件
  - [x] SubTask 9.4: 重写轮廓插件

- [x] Task 10: 高度自定义设置
  - [x] SubTask 10.1: 实现默认画布尺寸设置
  - [x] SubTask 10.2: 实现默认导出格式设置
  - [x] SubTask 10.3: 实现低库存阈值设置
  - [x] SubTask 10.4: 实现设置持久化

- [x] Task 11: 最终测试
  - [x] SubTask 11.1: macOS平台完整测试
  - [x] SubTask 11.2: Windows平台完整测试
  - [x] SubTask 11.3: 修复所有发现的问题

# Task Dependencies

- [Task 2] depends on [Task 1]
- [Task 3] depends on [Task 1]
- [Task 4] depends on [Task 1]
- [Task 5] depends on [Task 3, Task 4]
- [Task 6] depends on [Task 1]
- [Task 7] depends on [Task 1]
- [Task 8] depends on [Task 5]
- [Task 9] depends on [Task 5]
- [Task 10] depends on [Task 2]
- [Task 11] depends on [Task 3, Task 4, Task 5, Task 6, Task 7, Task 8, Task 9, Task 10]
