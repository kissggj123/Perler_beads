# PDF 导出优化 - 任务列表

## [x] Task 1: 添加 PDF 中文字体支持

- **Priority**: P0
- **Depends On**: None
- **Description**:
  - 在 `pubspec.yaml` 中添加中文字体资源
  - 修改 `pdf_export_service.dart` 加载中文字体
  - 配置 pdf 库使用中文字体渲染
- **Acceptance Criteria**:
  - PDF 导出时中文字符正确显示
  - 不影响英文和数字的正常显示
- **Notes**: 使用 pdf 包的字体加载功能

## [x] Task 2: 优化 PDF 坐标布局

- **Priority**: P0
- **Depends On**: None
- **Description**:
  - 增加坐标区域的宽度
  - 调整坐标文字的间距
  - 优化坐标与格子的对齐方式
  - 确保坐标不重叠
- **Acceptance Criteria**:
  - 坐标显示清晰、不拥挤
  - 坐标与格子正确对齐
  - 缩放时布局保持正确
- **Notes**: 修改 `pdf_export_service.dart` 中的坐标绘制逻辑

## [x] Task 3: 测试和验证

- **Priority**: P1
- **Depends On**: Task 1, Task 2
- **Description**:
  - 测试中文导出功能
  - 测试坐标显示效果
  - 测试不同尺寸设计的导出
- **Acceptance Criteria**:
  - 所有测试通过
  - 导出效果符合预期
- **Notes**: 手动测试验证

## Task Dependencies

```
Task 1 (中文字体支持) ──┬── Task 3 (测试验证)
Task 2 (坐标布局优化) ─┘
```
