# 兔可可的拼豆世界 🐰🧩

一款专为拼豆爱好者设计的桌面应用程序，支持 macOS 和 Windows 平台。

## ✨ 功能特性

### 🎨 设计创建

- **新建设计** - 创建自定义尺寸的空白画布，支持多种预设尺寸
- **导入图片** - 将图片自动转换为拼豆设计，支持智能颜色匹配
- **设计编辑器** - 直观的网格编辑界面，支持绘制、擦除、填充工具

### 📦 库存管理

- **库存追踪** - 记录每种颜色拼豆的数量
- **导入导出** - 支持 CSV 和 JSON 格式的数据导入导出
- **低库存警告** - 自动提醒库存不足的颜色

### 🎯 颜色库

- **内置颜色** - 包含 Perler、Hama、Artkal 等品牌的 125+ 种标准颜色
- **自定义颜色** - 支持添加自定义颜色到颜色库
- **颜色搜索** - 快速搜索和筛选颜色

### 📤 导出功能

- **PNG 导出** - 高质量图片导出，支持多种缩放比例
- **PDF 导出** - 适合打印的 PDF 文档，支持多种页面尺寸
- **材料清单** - 导出详细的材料使用清单（CSV/PDF）

### 🔌 插件系统

- **颜色优化** - 自动优化颜色使用，减少颜色种类
- **抖动效果** - Floyd-Steinberg 抖动算法，改善颜色过渡
- **轮廓提取** - 自动提取设计轮廓

### ⚙️ 高度自定义

- **主题切换** - 支持亮色/暗色主题
- **默认设置** - 自定义默认画布尺寸、导出格式、库存阈值
- **快捷键** - 丰富的键盘快捷键支持

## 🖥️ 系统要求

| 平台    | 最低要求                        |
| ------- | ------------------------------- |
| macOS   | macOS 10.14 (Mojave) 或更高版本 |
| Windows | Windows 10 或更高版本           |

## 📥 安装

### macOS

1. 下载 `兔可可的拼豆世界.dmg`
2. 打开 DMG 文件
3. 将应用拖拽到 Applications 文件夹
4. 首次运行可能需要在"系统偏好设置 > 安全性与隐私"中允许运行

### Windows

1. 下载 `兔可可的拼豆世界.zip`
2. 解压到任意目录
3. 运行 `兔可可的拼豆世界.exe`

## 🚀 从源码构建

### 环境准备

1. 安装 [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.10.7 或更高版本)
2. 配置 Flutter 环境：
   ```bash
   flutter doctor
   ```

### 克隆项目

```bash
git clone https://github.com/your-username/bunnycc-perler.git
cd bunnycc-perler
```

### 安装依赖

```bash
flutter pub get
```

### 运行应用

```bash
# macOS
flutter run -d macos

# Windows
flutter run -d windows
```

### 构建发布版本

```bash
# macOS
flutter build macos --release

# Windows
flutter build windows --release
```

构建产物位置：

- macOS: `build/macos/Build/Products/Release/`
- Windows: `build/windows/x64/runner/Release/`

## ⌨️ 快捷键

### 设计编辑器

| 快捷键         | 功能           |
| -------------- | -------------- |
| `D`            | 切换到绘制模式 |
| `E`            | 切换到擦除模式 |
| `F`            | 切换到填充模式 |
| `G`            | 切换网格显示   |
| `C`            | 切换坐标显示   |
| `Ctrl+Z`       | 撤销           |
| `Ctrl+Y`       | 重做           |
| `Ctrl+Shift+Z` | 重做           |
| `Ctrl+S`       | 保存设计       |

## 📁 项目结构

```
bunnycc_perler/
├── lib/
│   ├── main.dart              # 应用入口
│   ├── models/                # 数据模型
│   │   ├── bead_color.dart    # 拼豆颜色模型
│   │   ├── bead_design.dart   # 设计模型
│   │   ├── color_palette.dart # 颜色库模型
│   │   └── inventory.dart     # 库存模型
│   ├── providers/             # 状态管理
│   ├── screens/               # 页面
│   │   ├── home_screen.dart   # 首页
│   │   ├── design_editor_screen.dart  # 设计编辑器
│   │   ├── inventory_screen.dart      # 库存管理
│   │   ├── image_import_screen.dart   # 图片导入
│   │   └── settings_screen.dart       # 设置
│   ├── services/              # 服务层
│   ├── widgets/               # UI 组件
│   ├── plugins/               # 插件
│   ├── data/                  # 数据文件
│   └── utils/                 # 工具类
├── assets/
│   └── changelog.json         # 更新日志
├── macos/                     # macOS 平台配置
├── windows/                   # Windows 平台配置
└── pubspec.yaml               # 项目配置
```

## 🛠️ 技术栈

- **框架**: [Flutter](https://flutter.dev/)
- **状态管理**: [Provider](https://pub.dev/packages/provider)
- **图片处理**: [image](https://pub.dev/packages/image)
- **PDF 生成**: [pdf](https://pub.dev/packages/pdf)
- **文件选择**: [file_picker](https://pub.dev/packages/file_picker)
- **本地存储**: [shared_preferences](https://pub.dev/packages/shared_preferences)
- **CSV 处理**: [csv](https://pub.dev/packages/csv)

## 📝 更新日志

### v2.2.0-fix (2026-03-28)

- 修复：检测更新失败的问题（GitHub API连接问题）
- 修复：ClientException with SocketException: Failed host lookup
- 新增：重试机制（最多3次重试）
- 新增：更短的超时时间（15秒）
- 新增：高性能渲染器（实验性）
- 新增：本地版本信息缓存加载

### v2.3.0 (2026-03-28)

- 新增：纯像素代码生成的动物图标（兔子、猫、狗、鸟、熊猫）
- 新增：点击拼豆格显示坐标和颜色代码
- 新增：点击任意网格高亮显示相同颜色的所有格子
- 优化：网格坐标显示逻辑
- 修复：引导界面缺少主程序图标
- 修复：上帝模式及隐藏选项不起作用
- 修复：应用内版本号显示问题
- 修复：主题色页缺少返回按钮

### v1.0.0 (2026-02-15)

- 首次发布
- 支持新建设计功能
- 支持导入图片生成设计
- 支持设计编辑器（绘制、擦除、填充）
- 支持库存管理（CSV/JSON导入导出）
- 支持颜色库管理
- 支持PNG/PDF导出
- 支持材料清单导出
- 支持插件系统（颜色优化、抖动、轮廓）
- 支持深色/浅色主题切换

## 📄 许可证

随便修改就完事 开源！

## 🤝 贡献

请随意修改和分发本项目的代码！

---

<p align="center">
  Made with ❤️ by BunnyCC
</p>
