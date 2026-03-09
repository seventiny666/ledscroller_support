# LedScreen - LED霓虹灯效果iOS应用

一个功能强大的LED霓虹灯效果展示应用，支持自定义文字、颜色、动画和特效。

## 功能特点

### 核心功能
- 🎨 **自定义LED文字**：支持自定义文字内容、字体、大小和颜色
- ✨ **霓虹发光效果**：可调节的霓虹强度和阴影效果
- 🎬 **多种动画效果**：静止、左滚、右滚、上滚、下滚
- 🖼️ **背景自定义**：纯色背景、渐变背景、图片背景
- 💾 **保存和管理**：保存自己的创作，随时查看和编辑

### 特殊效果
- 💖 **爱心流星雨**：浪漫的爱心流星雨动画效果
- 🎆 **烟花效果**：两种不同的烟花绽放动画
- 🕐 **翻页时钟**：动态翻页时钟效果

### 模版功能
- 🌟 **霓虹灯看板**：4个预设霓虹灯模版（Drink Juice, Dance party!, Nice Day, party hard）
- 🎤 **偶像应援**：4个偶像应援模版
- 📺 **LED横幅**：4个LED横幅模版
- 📝 **预设卡片**：多个预设LED文字效果

### 页面结构
- **首页**：展示所有LED效果和特殊动画
- **模版**：分类展示各种模版（霓虹灯看板、偶像应援、LED横幅、数字时钟、其他分类）
- **我的创作**：管理用户创建的LED效果
- **设置**：应用设置和关于信息

## 最新更新

### UI优化
- ✅ 首页卡片尺寸优化（宽度：屏幕宽度-40px，左右边距26px，间距17px）
- ✅ 卡片边框透明度调整为40%
- ✅ 创作页面标题改为"我的创作"
- ✅ 时钟封面去掉文字，只显示时钟图案

### 模版预览功能
- ✅ 点击模版卡片进入预览页面（横屏显示）
- ✅ 预览页面显示背景图片和文字效果
- ✅ 两个胶囊按钮：
  - **编辑**：进入编辑页面，可修改内容并保存为新LED
  - **预览**：进入沉浸式全屏预览

### 编辑功能增强
- ✅ 从模版创建新LED时，默认加载模版的文字、字体、背景图等
- ✅ 保存后创建新LED（不修改原模版）
- ✅ 新LED自动保存到"我的创作"页面顶部
- ✅ Toast提示："新页面已保存到我的创作页面"

## 技术栈

- **语言**：Swift
- **框架**：UIKit
- **最低版本**：iOS 13.0+
- **架构**：MVC + TabBar导航

## 项目结构

```
LedScreen/
├── AppDelegate.swift              # 应用委托
├── SceneDelegate.swift            # 场景委托
├── MainTabBarController.swift    # 主TabBar控制器
├── LEDSquareViewController.swift # 首页
├── TemplateSquareViewController.swift # 模版页面
├── MyCreationsViewController.swift    # 我的创作页面
├── SettingsViewController.swift       # 设置页面
├── LEDCreateViewController.swift      # 创建/编辑页面
├── LEDPreviewViewController.swift     # 模版预览页面
├── LEDFullScreenViewController.swift  # 全屏显示页面
├── LEDItem.swift                      # 数据模型
├── FireworksViewController.swift      # 烟花效果1
├── FireworksBloomViewController.swift # 烟花效果2
├── FlipClockViewController.swift      # 翻页时钟
├── LoveRainViewController.swift       # 爱心流星雨
└── Assets.xcassets/                   # 图片资源
    ├── neon_1~4.jpg                   # 霓虹灯看板背景
    ├── idol_1~4.jpg                   # 偶像应援背景
    ├── led_1~4.jpg                    # LED横幅背景
    └── clock_1.jpg                    # 时钟背景
```

## 快速开始

### 1. 克隆项目
```bash
git clone <repository-url>
cd LedScreenIos
```

### 2. 打开项目
```bash
open LedScreen.xcodeproj
```

### 3. 编译运行
- 按 `Command + B` 编译项目
- 按 `Command + R` 运行应用

## 使用说明

### 创建自定义LED
1. 点击首页右上角的"+"按钮
2. 输入文字内容
3. 在"字体"标签页调整字体、大小、颜色、霓虹强度
4. 在"背景"标签页选择背景颜色或图片
5. 在"动画"标签页设置滚动效果和速度
6. 点击"保存"

### 使用模版
1. 进入"模版"页面
2. 选择分类（霓虹灯看板、偶像应援、LED横幅等）
3. 点击任意模版卡片
4. 在预览页面：
   - 点击"编辑"：修改内容并保存为新LED
   - 点击"预览"：查看完整效果

### 管理创作
1. 进入"我的创作"页面
2. 查看所有创建的LED
3. 点击卡片查看全屏效果
4. 左滑卡片：
   - 编辑：修改LED内容
   - 删除：删除LED

## 数据存储

应用使用 `UserDefaults` 存储用户数据：
- 用户创建的LED效果
- 预设卡片和模版
- 特殊效果配置

数据会自动保存，无需手动操作。

## 开发文档

- **ARCHITECTURE.md**：项目架构说明
- **CHECKLIST.md**：功能检查清单
- **DEMO_GUIDE.md**：演示指南
- **所有错误已修复-可以运行.md**：最新修复记录

## 已知问题

- AppIcon有7个未分配的子项（不影响功能）

## 贡献

欢迎提交Issue和Pull Request！

## 许可证

[添加许可证信息]

## 联系方式

[添加联系方式]

---

**最后更新**：2026年3月2日
**版本**：1.0.0
**状态**：✅ 所有功能正常，可以运行
