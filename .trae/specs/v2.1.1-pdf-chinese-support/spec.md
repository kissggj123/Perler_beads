# PDF 导出中文支持和坐标优化 Spec

## Why

当前 PDF 导出功能存在两个问题：

1. 中文字符无法正确显示，导致导出的 PDF 中中文显示为方块或空白
2. 坐标显示挤在一起，影响可读性

## What Changes

- 添加中文字体支持到 PDF 导出功能
- 优化 PDF 中坐标的布局和间距
- 改进坐标显示的清晰度

## Impact

- Affected specs: PDF 导出功能
- Affected code: `lib/services/pdf_export_service.dart`

## ADDED Requirements

### Requirement: PDF 中文字体支持

The system SHALL 在 PDF 导出时正确渲染中文字符。

#### Scenario: 导出包含中文的设计

- **WHEN** 用户导出包含中文标注的设计为 PDF
- **THEN** PDF 中正确显示所有中文字符

### Requirement: PDF 坐标布局优化

The system SHALL 在 PDF 中以合理的间距显示坐标。

#### Scenario: 导出带有坐标的设计

- **WHEN** 用户导出带有坐标显示的设计为 PDF
- **THEN** 坐标以清晰、不重叠的方式显示
- **AND** 坐标与格子对齐正确

## MODIFIED Requirements

None

## REMOVED Requirements

None
