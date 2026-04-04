# LedScrollerIOS 项目记忆

## 项目概述
- **项目名称**：LedScroller (LED跑马灯)
- **平台**：iOS (iPhone & iPad)
- **语言**：Swift
- **架构**：MVC
- **版本**：1.2.9
- **最低系统**：iOS 15.0（2026-04-04从14.0提升，移除StoreKit1/VIPManager依赖）

## 核心功能
- LED文字创作编辑器
- 多种滚动动画效果
- 霓虹发光效果
- 三种边框系统（跑马灯、灯牌、线性）
- 粒子特效引擎
- 代码生成功能
- 国际化支持（10种语言）
- VIP订阅系统

## 边框系统索引说明

### Lightboard Border 布局（3行4列，索引0-11）
- **第一行（索引0-3）**：免费
  - style1 [0] | style2 [1] | style3 [2] | style4 [3]
- **第二行（索引4-7）**：VIP
  - style5 [4] | style6 [5] | style7 [6] | style8 [7]
- **第三行（索引8-11）**：VIP
  - style9 [8] | style10 [9] | style11 [10] | style12 [11]

### Linear Border 布局（特殊排序）
UI显示顺序与枚举rawValue不一致：
- **UI第一行**：white(7), red(0), green(1), blue(2)
- **UI第二行**：yellow(3), purple(4), cyan(5), orange(6)
- **UI第三行**：pink(8), gold(9), coral(10), teal(11)

设置时必须使用rawValue，而非UI位置索引。

### Neon Screen 背景布局（5行4列，索引0-19）
- **第一行（索引0-3）**：neon_1, neon_2, neon_3, neon_4
- **第二行（索引4-7）**：neon_5, neon_6, neon_7, neon_8
- **第三行（索引8-11）**：neon_9, neon_10, neon_11, neon_12
- **第四行（索引12-15）**：neon_13, neon_14, neon_15, neon_16
- **第五行（索引16-19）**：neon_17, neon_18, neon_19, neon_20

## 技术实现

### 边框宽度调整机制（2026-04-03新增）
- **LEDItem.borderWidthAdjustment**: CGFloat? - 边框宽度调整值
- **LightBoardBorderView.borderWidthAdjustment**: CGFloat - 应用到视图
- 计算公式：`max(2, baseBorderWidth + borderWidthAdjustment)`
- 默认cardCover模式的borderWidth = 12pt
- 示例：borderWidthAdjustment = -2 → 最终宽度 = 10pt

### VIP判断逻辑
- VIP字体：dotMatrix, pixel, mat, raster, smooth, video
- VIP边框：Lightboard第二行、第三行；Linear所有样式
- VIP背景：led_5+, idol_5+
- neon背景全部免费

## 代码约定
- 首页Popular标签页卡片配置在 TemplateSquareViewController.swift 的 `createPlaceholderItems` 方法中
- 卡片索引从1开始（neon_1, neon_2...）
- 边框索引从0开始（style1对应索引0）

### 设置页面图标发光效果（2026-04-03新增）
- 图标发光使用 `layer.shadowColor/shadowOffset/shadowOpacity/shadowRadius`
- shadowColor = iconColor.cgColor，shadowRadius = 8
- 所有设置项图标都有自身颜色的发光效果

### 版本按钮布局（2026-04-03新增）
- 版本按钮布局：标题 | 版本号 | 箭头
- 版本号在箭头左边（约束：trailing to arrowImageView.leading, constant: -8）
- 点击版本显示"已经是最新版本"提示（versionMessage本地化）

### DSEGClockView 跳动修复（2026-04-03新增）
- 数码管时钟视图在初始化时设置初始字体大小，避免首次布局时跳动
- 初始字体大小：100pt，在layoutSubviews中根据实际尺寸重新计算
- 应用于 DigitalClockViewController 和 StopwatchViewController
- 新增字体大小变化检测：只有当字体大小变化超过1pt时才更新，避免不必要的跳动

### FlipDigitView 跳动修复（2026-04-03新增）
- 翻页时钟数字视图在初始化时设置较大初始字体（100pt），避免首次布局时跳动
- 在layoutSubviews中根据实际高度计算字体大小（h * 0.66）
- 新增字体大小变化检测：只有当字体大小变化超过1pt时才更新

### CountdownViewController timeLabel 跳动修复（2026-04-03新增）
- 在setupRing中设置初始文本 "00:00"，避免首次布局时因文本为空导致的跳动
- 字体大小固定为88pt，使用 adjustsFontSizeToFitWidth 自动适应

### 时钟模块全屏预览跳动修复（2026-04-03新增）
- 移除 LEDSquareViewController 中的 0.1秒延迟呈现，直接呈现时钟控制器
- 延迟会导致视觉上的跳动，直接呈现更流畅

### 边框Tab底部间距修复（2026-04-03新增）
- 线性边框最后一行添加底部约束：`linearRow3.bottomAnchor.constraint(lessThanOrEqualTo: borderTabView.bottomAnchor, constant: -60)`
- 确保最后一行完全可见并有足够的滚动空间

### HeartGridViewController 爱心居中修复（2026-04-03新增）
- 爱心图案使用实际边界框（boundingBox）计算居中位置
- 新增 `getHeartBoundingBox()` 方法计算爱心的实际范围
- 居中计算基于爱心实际高度和宽度，而非整个网格大小
- 绘制时考虑边界框偏移量：`heartRow = row - centeredHeartStartRow + boundingBox.topRow`

### ILoveUViewController I ❤ U 动画优化（2026-04-03新增）
- 爱心使用实际边界框计算居中位置（同HeartGridViewController）
- 所有格子从圆角矩形改为完美圆形（`UIBezierPath(ovalIn:)`）
- I和U使用手动定义的圆点图案（与背景相同大小），不再使用 DotMatrixTextView
  - I：3列 x 12行，中间一列竖线
  - U：5列 x 12行，两侧竖线 + 底部圆弧
- I在心左侧，U在心右侧，距离心的距离相等
- 字母高度与心高度一致
- 心跳动画：定时器驱动的快速放大缩小效果
  - 节奏：1.15 → 0.95 → 1.1 → 0.98 → 1.0
  - 间隔：0.25秒（较慢速度）
