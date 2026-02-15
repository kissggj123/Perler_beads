# 设计编辑器Bug修复 Spec

## Why
设计编辑器存在几个影响用户体验的问题：未保存返回、关闭窗口提示、滚轮缩放功能异常。

## What Changes
- 修复点击"不保存"后不返回主界面的问题
- 修复新建工程关闭窗口时不提示保存的问题
- 修复鼠标滚轮上下滚动而非缩放的问题

## Impact
- Affected code:
  - `lib/screens/design_editor_screen.dart` - 返回逻辑和关闭提示
  - `lib/widgets/bead_canvas_widget.dart` - 滚轮缩放功能

## ADDED Requirements

### Requirement: 未保存返回主界面
系统 SHALL 在用户点击"不保存"后正确返回主界面。

#### Scenario: 不保存返回
- **WHEN** 用户有未保存的更改并点击返回
- **AND** 用户在提示对话框中点击"不保存"
- **THEN** 系统应返回主界面

### Requirement: 关闭窗口保存提示
系统 SHALL 在关闭窗口时检测未保存的更改并提示用户。

#### Scenario: 新建工程关闭提示
- **WHEN** 用户新建了一个设计
- **AND** 设计有未保存的更改
- **AND** 用户关闭窗口
- **THEN** 系统应显示保存提示对话框

### Requirement: 鼠标滚轮缩放
系统 SHALL 使用鼠标滚轮进行缩放操作，而非上下滚动画布。

#### Scenario: 滚轮缩放
- **WHEN** 用户在画布上滚动鼠标滚轮
- **THEN** 画布应进行缩放
- **AND** 不应上下滚动

## MODIFIED Requirements
无

## REMOVED Requirements
无
