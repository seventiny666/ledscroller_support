# 需求文档

## 简介

LED 手机屏幕显示功能允许用户在 iOS 设备上显示各种类型的 LED 效果屏幕，并通过 iCloud 在多个设备间同步用户的自定义配置和预设。该功能将手机屏幕转变为可定制的 LED 显示屏，适用于通知、氛围灯、信息展示等多种场景。

应用采用暗色调（Dark Mode）和霓虹朋克风格（Neon Cyberpunk）的视觉设计，使用霓虹色（粉色、蓝色、紫色、青色等发光色）配合深色背景，营造高端、未来感的用户体验。应用使用 iOS 原生技术栈（Swift + UIKit/SwiftUI）开发，符合 iOS Human Interface Guidelines。

## 术语表

- **LED_Display_System**: LED 屏幕显示系统，负责管理和渲染各种 LED 显示效果
- **Display_Type**: 显示类型，定义 LED 屏幕的视觉效果类型（如纯色、渐变、跑马灯、闪烁、文字滚动、特殊效果等）
- **Display_Configuration**: 显示配置，包含特定显示效果的所有参数（颜色、速度、亮度、文字内容等）
- **Template**: 模板，用户保存的显示配置（替代原 Preset 术语）
- **Template_Card**: 模板卡片，在首页瀑布流中展示的模板预览单元
- **Waterfall_Layout**: 瀑布流布局，首页使用的响应式网格布局方式
- **Template_Category**: 模板分类，用于组织模板的分类系统（预设模板、我的创建）
- **Thumbnail_Preview**: 缩略图预览，模板卡片中显示的动态效果预览
- **iCloud_Sync_Service**: iCloud 同步服务，负责在用户设备间同步模板和配置
- **Brightness_Level**: 亮度级别，屏幕显示的亮度值（0-100%）
- **Animation_Speed**: 动画速度，动态效果的播放速度
- **Color_Value**: 颜色值，RGB 或 HSB 格式的颜色定义
- **Effect_Template**: 特殊效果模板，预定义的复杂视觉效果（如爱心表白、应援灯、烟花等）
- **Particle_System**: 粒子系统，用于生成粒子动画效果（爱心粒子、星星粒子等）
- **Meteor_Shower_Effect**: 流星雨效果，模拟流星划过屏幕的动画背景
- **Code_Rain_Effect**: 代码雨效果，类似黑客帝国的代码流动背景效果
- **Firework_Effect**: 烟花效果，模拟烟花绽放的动画效果
- **Neon_Line_Effect**: 霓虹线条效果，发光线条描绘图案的视觉效果
- **Font_Style**: 字体样式，文字显示的字体类型
- **Text_Effect**: 文字效果，应用于文字的视觉增强效果（如霓虹灯、阴影、描边等）
- **Background_Style**: 背景样式，文字显示的背景视觉效果
- **Scroll_Direction**: 滚动方向，文字或效果的移动方向（上、下、左、右、对角线等）
- **JavaScript_Code_Mode**: JavaScript 代码模式，允许用户通过编程创建自定义显示效果
- **Canvas_API**: Canvas API，提供给用户编程的绘图接口
- **Code_Sandbox**: 代码沙箱，隔离执行用户 JavaScript 代码的安全环境
- **Fullscreen_Playback_Mode**: 全屏播放模式，隐藏所有 UI 元素的沉浸式播放状态
- **UI_Theme**: UI 主题，定义应用的整体视觉风格（暗色调、霓虹朋克风格）
- **Neon_Glow_Effect**: 霓虹发光效果，UI 元素的发光视觉增强
- **Color_Scheme**: 配色方案，定义霓虹朋克风格的颜色组合
- **Creation_Entry**: 创建入口，用户创建新 LED 效果的主要交互入口
- **Visual_Editor**: 可视化编辑器，通过图形界面配置 LED 效果的编辑模式
- **Code_Editor**: 代码编辑器，通过 JavaScript 编程创建 LED 效果的编辑模式
- **Add_LED_Button**: "新增 LED"按钮，首页主要创建入口，用于可视化创建 LED 效果
- **Code_Mode_Button**: "代码模式"按钮，首页次要创建入口，用于通过 JavaScript 编程创建效果
- **Dark_Theme**: 暗色主题，应用的整体深色背景配色方案
- **Neon_Color_Palette**: 霓虹色调色板，包含粉色、蓝色、紫色、青色等发光色的配色集合
- **Cyberpunk_Style**: 赛博朋克风格，高端、未来感的视觉设计风格
- **Glow_Button**: 发光按钮，带有霓虹发光效果的交互按钮
- **iOS_Native_Platform**: iOS 原生平台，使用 Swift 和 UIKit/SwiftUI 开发的 iOS 应用
- **HIG_Compliance**: Human Interface Guidelines 合规性，符合苹果 iOS 设计规范

## 需求

### 需求 1: 平台和技术栈

**用户故事:** 作为开发团队，我们需要使用 iOS 原生技术栈开发应用，以便提供最佳的性能和用户体验。

#### 验收标准

1. THE LED_Display_System SHALL 使用 Swift 编程语言开发
2. THE LED_Display_System SHALL 使用 UIKit 或 SwiftUI 构建用户界面
3. THE LED_Display_System SHALL 在 Xcode 中可编译和运行
4. THE LED_Display_System SHALL 符合 iOS Human Interface Guidelines
5. THE LED_Display_System SHALL 支持 iOS 15.0 及以上版本
6. THE LED_Display_System SHALL 使用原生 iOS 框架（Core Animation、Core Graphics、Metal 等）实现动画和渲染

### 需求 2: UI 设计风格

**用户故事:** 作为用户，我想要使用具有霓虹朋克风格的暗色调界面，以便获得高端、未来感的视觉体验。

#### 验收标准

1. THE LED_Display_System SHALL 使用 Dark_Theme 作为应用的整体配色方案
2. THE LED_Display_System SHALL 使用深色背景（接近黑色，RGB 值低于 30）作为主要背景色
3. THE LED_Display_System SHALL 使用 Neon_Color_Palette 作为强调色和交互元素颜色
4. THE Neon_Color_Palette SHALL 包含霓虹粉色（#FF10F0 或类似色值）
5. THE Neon_Color_Palette SHALL 包含霓虹蓝色（#00D9FF 或类似色值）
6. THE Neon_Color_Palette SHALL 包含霓虹紫色（#B026FF 或类似色值）
7. THE Neon_Color_Palette SHALL 包含霓虹青色（#00FFF0 或类似色值）
8. FOR ALL 交互按钮，THE LED_Display_System SHALL 应用 Neon_Glow_Effect 使其呈现发光效果
9. FOR ALL 文字元素，THE LED_Display_System SHALL 使用浅色或霓虹色以确保在深色背景上的可读性
10. THE LED_Display_System SHALL 使用 Cyberpunk_Style 视觉元素（如发光线条、科技感图标、未来感字体）
11. FOR ALL 卡片和容器元素，THE LED_Display_System SHALL 使用半透明深色背景配合霓虹色边框
12. THE LED_Display_System SHALL 在交互元素上使用霓虹色高光和阴影效果

### 需求 3: 首页创建入口

**用户故事:** 作为用户，我想要在首页看到两个独立的创建入口，以便根据我的技能水平选择合适的创建方式。

#### 验收标准

1. THE LED_Display_System SHALL 在首页顶部显示 Add_LED_Button
2. THE Add_LED_Button SHALL 显示文字"+ 新增 LED"
3. THE Add_LED_Button SHALL 使用 Glow_Button 样式呈现霓虹发光效果
4. THE Add_LED_Button SHALL 作为主要创建入口，视觉上比 Code_Mode_Button 更突出
5. WHEN 用户点击 Add_LED_Button，THE LED_Display_System SHALL 打开 Visual_Editor 界面
6. THE LED_Display_System SHALL 在首页顶部显示 Code_Mode_Button
7. THE Code_Mode_Button SHALL 显示文字"</> 代码模式"
8. THE Code_Mode_Button SHALL 使用 Glow_Button 样式呈现霓虹发光效果
9. THE Code_Mode_Button SHALL 作为次要创建入口，视觉上比 Add_LED_Button 稍弱
10. WHEN 用户点击 Code_Mode_Button，THE LED_Display_System SHALL 打开 Code_Editor 界面
11. THE Add_LED_Button 和 Code_Mode_Button SHALL 分开显示，不合并为单一入口
12. THE LED_Display_System SHALL 将 Add_LED_Button 放置在 Code_Mode_Button 左侧或上方
13. FOR ALL Glow_Button，THE LED_Display_System SHALL 在用户按下时增强发光效果作为视觉反馈

### 需求 4: 首页瀑布流布局

**用户故事:** 作为用户，我想要在首页以瀑布流方式浏览所有模板，以便快速找到并选择我想要的 LED 效果。

#### 验收标准

1. THE LED_Display_System SHALL 在首页使用 Waterfall_Layout 展示所有 Template
2. WHEN 用户打开应用，THE LED_Display_System SHALL 在首页显示所有可用的 Template_Card
3. THE LED_Display_System SHALL 将 Template 分为两个 Template_Category："预设模板"和"我的创建"
4. WHEN 用户滚动首页，THE Waterfall_Layout SHALL 自动调整 Template_Card 位置以优化空间利用
5. FOR ALL Template_Card，THE LED_Display_System SHALL 显示 Thumbnail_Preview
6. THE Thumbnail_Preview SHALL 展示该模板的动态效果预览
7. FOR ALL Template_Card，THE LED_Display_System SHALL 显示模板名称
8. WHEN 用户点击任意 Template_Card，THE LED_Display_System SHALL 立即进入 Fullscreen_Playback_Mode
9. FOR ALL Template_Card，THE LED_Display_System SHALL 使用深色背景配合霓虹色边框
10. FOR ALL Template_Card 标题文字，THE LED_Display_System SHALL 使用霓虹色或浅色以确保可读性

### 需求 5: 模板分类管理

**用户故事:** 作为用户，我想要查看预设模板和我创建的模板，以便区分系统内置效果和我的自定义效果。

#### 验收标准

1. THE LED_Display_System SHALL 在"预设模板" Template_Category 中显示所有系统内置的 Template
2. THE LED_Display_System SHALL 在"我的创建" Template_Category 中显示所有用户创建的 Template
3. WHEN 用户创建新 Template，THE LED_Display_System SHALL 自动将其添加到"我的创建" Template_Category
4. THE LED_Display_System SHALL 在首页按 Template_Category 分组显示 Template_Card
5. FOR ALL Template_Card 在"我的创建"分类中，THE LED_Display_System SHALL 提供删除操作
6. FOR ALL Template_Card 在"我的创建"分类中，THE LED_Display_System SHALL 提供编辑操作
7. FOR ALL Template_Card 在"我的创建"分类中，THE LED_Display_System SHALL 提供重命名操作
8. WHEN 用户删除 Template，THE LED_Display_System SHALL 从首页移除对应的 Template_Card
9. FOR ALL Template_Category 标题，THE LED_Display_System SHALL 使用霓虹色文字配合发光效果

### 需求 6: 全屏播放交互

**用户故事:** 作为用户，我想要以全屏方式播放 LED 效果并通过简单的点击控制退出，以便获得沉浸式的显示体验。

#### 验收标准

1. WHEN 用户点击首页的任意 Template_Card，THE LED_Display_System SHALL 立即进入 Fullscreen_Playback_Mode
2. WHILE 处于 Fullscreen_Playback_Mode，THE LED_Display_System SHALL 隐藏所有 UI 元素（状态栏、导航栏、按钮等）
3. WHILE 处于 Fullscreen_Playback_Mode，THE LED_Display_System SHALL 保持屏幕常亮
4. WHEN 用户在 Fullscreen_Playback_Mode 中点击屏幕，THE LED_Display_System SHALL 显示退出按钮
5. WHEN 退出按钮显示后 3 秒内用户未操作，THE LED_Display_System SHALL 自动隐藏退出按钮
6. WHEN 用户点击退出按钮，THE LED_Display_System SHALL 退出 Fullscreen_Playback_Mode 并返回首页瀑布流
7. WHILE 处于 Fullscreen_Playback_Mode，THE LED_Display_System SHALL 持续播放选中的 Template 效果
8. THE 退出按钮 SHALL 使用 Glow_Button 样式呈现霓虹发光效果

### 需求 7: 显示类型支持

**用户故事:** 作为用户，我想要选择不同类型的 LED 显示效果，以便在不同场景下使用手机屏幕作为 LED 显示器。

#### 验收标准

1. THE LED_Display_System SHALL 支持纯色显示类型
2. THE LED_Display_System SHALL 支持渐变色显示类型
3. THE LED_Display_System SHALL 支持跑马灯显示类型
4. THE LED_Display_System SHALL 支持闪烁显示类型
5. THE LED_Display_System SHALL 支持文字滚动显示类型
6. THE LED_Display_System SHALL 支持呼吸灯显示类型
7. THE LED_Display_System SHALL 支持特殊效果模板显示类型
8. THE LED_Display_System SHALL 支持 JavaScript 代码模式显示类型

### 需求 8: 显示配置管理

**用户故事:** 作为用户，我想要自定义每种显示效果的参数，以便创建符合我需求的个性化 LED 显示。

#### 验收标准

1. WHEN 用户选择纯色显示类型，THE LED_Display_System SHALL 允许用户选择 Color_Value
2. WHEN 用户选择渐变色显示类型，THE LED_Display_System SHALL 允许用户选择至少两个 Color_Value 和 Animation_Speed
3. WHEN 用户选择跑马灯显示类型，THE LED_Display_System SHALL 允许用户选择 Color_Value、方向和 Animation_Speed
4. WHEN 用户选择闪烁显示类型，THE LED_Display_System SHALL 允许用户选择 Color_Value 和闪烁频率
5. WHEN 用户选择呼吸灯显示类型，THE LED_Display_System SHALL 允许用户选择 Color_Value 和呼吸周期
6. FOR ALL Display_Type，THE LED_Display_System SHALL 允许用户调整 Brightness_Level
7. FOR ALL 配置界面，THE LED_Display_System SHALL 使用 Dark_Theme 背景
8. FOR ALL 配置控件（滑块、按钮、选择器），THE LED_Display_System SHALL 使用霓虹色高亮和发光效果
9. FOR ALL 颜色选择器，THE LED_Display_System SHALL 优先展示 Neon_Color_Palette 中的颜色

### 需求 9: 增强的文字显示配置

**用户故事:** 作为用户，我想要自定义文字显示的各种视觉效果，以便创建更具表现力和个性化的文字展示。

#### 验收标准

1. WHEN 用户选择文字滚动显示类型，THE LED_Display_System SHALL 允许用户输入最多 500 个字符的文字内容
2. WHEN 用户配置文字显示，THE LED_Display_System SHALL 提供至少 5 种不同的 Font_Style 供用户选择
3. WHEN 用户配置文字显示，THE LED_Display_System SHALL 允许用户自定义文字 Color_Value
4. WHEN 用户配置文字显示，THE LED_Display_System SHALL 提供霓虹灯 Text_Effect 选项
5. WHEN 用户配置文字显示，THE LED_Display_System SHALL 提供阴影 Text_Effect 选项
6. WHEN 用户配置文字显示，THE LED_Display_System SHALL 提供描边 Text_Effect 选项
7. WHEN 用户配置文字显示，THE LED_Display_System SHALL 提供至少 5 种 Background_Style 供用户选择
8. WHEN 用户配置文字显示，THE LED_Display_System SHALL 允许用户选择 Scroll_Direction（左、右、上、下、左上对角线、右上对角线、左下对角线、右下对角线）
9. WHEN 用户配置文字显示，THE LED_Display_System SHALL 允许用户调整字体大小（范围 12-200 点）
10. WHEN 用户配置文字显示，THE LED_Display_System SHALL 允许用户调整 Animation_Speed

### 需求 10: 增强的特殊效果模板

**用户故事:** 作为用户，我想要使用预定义的特殊效果模板，以便快速创建复杂的视觉效果用于特定场景。

#### 验收标准

1. WHEN 用户选择特殊效果模板显示类型，THE LED_Display_System SHALL 提供爱心表白 Effect_Template
2. WHEN 用户选择爱心表白 Effect_Template，THE LED_Display_System SHALL 使用 Particle_System 显示粉色爱心粒子形成心形图案
3. WHEN 用户选择爱心表白 Effect_Template，THE LED_Display_System SHALL 允许用户输入自定义文字（如"我喜欢你"）叠加在爱心图案上
4. WHEN 用户选择特殊效果模板显示类型，THE LED_Display_System SHALL 提供代码雨 Effect_Template
5. WHEN 用户选择代码雨 Effect_Template，THE LED_Display_System SHALL 显示 Code_Rain_Effect 配合爱心粒子
6. WHEN 用户选择特殊效果模板显示类型，THE LED_Display_System SHALL 提供烟花 Effect_Template
7. WHEN 用户选择烟花 Effect_Template，THE LED_Display_System SHALL 显示 Firework_Effect 配合霓虹线条人物剪影和彩色文字
8. WHEN 用户选择特殊效果模板显示类型，THE LED_Display_System SHALL 提供流星雨 Effect_Template
9. WHEN 用户选择流星雨 Effect_Template，THE LED_Display_System SHALL 显示 Meteor_Shower_Effect 配合爱心粒子和文字
10. WHEN 用户选择特殊效果模板显示类型，THE LED_Display_System SHALL 提供应援灯 Effect_Template
11. WHEN 用户选择应援灯 Effect_Template，THE LED_Display_System SHALL 显示节奏性闪烁和颜色变换效果
12. FOR ALL Effect_Template，THE LED_Display_System SHALL 允许用户自定义主要 Color_Value
13. FOR ALL Effect_Template，THE LED_Display_System SHALL 允许用户调整 Animation_Speed
14. WHERE Effect_Template 支持文字，THE LED_Display_System SHALL 允许用户输入自定义文字内容

### 需求 11: 动画背景效果系统

**用户故事:** 作为用户，我想要使用多种动画背景效果，以便创建更丰富和吸引人的视觉展示。

#### 验收标准

1. THE LED_Display_System SHALL 提供 Particle_System 用于生成粒子动画
2. WHEN 用户选择粒子效果，THE Particle_System SHALL 支持爱心粒子类型
3. WHEN 用户选择粒子效果，THE Particle_System SHALL 支持星星粒子类型
4. WHEN 用户选择粒子效果，THE Particle_System SHALL 允许用户自定义粒子 Color_Value
5. WHEN 用户选择粒子效果，THE Particle_System SHALL 允许用户调整粒子密度
6. THE LED_Display_System SHALL 提供 Meteor_Shower_Effect 背景效果
7. WHEN 用户选择 Meteor_Shower_Effect，THE LED_Display_System SHALL 显示流星从屏幕顶部划向底部的动画
8. THE LED_Display_System SHALL 提供 Code_Rain_Effect 背景效果
9. WHEN 用户选择 Code_Rain_Effect，THE LED_Display_System SHALL 显示随机字符从上到下流动的矩阵风格效果
10. THE LED_Display_System SHALL 提供 Firework_Effect 背景效果
11. WHEN 用户选择 Firework_Effect，THE LED_Display_System SHALL 显示烟花从底部发射并在空中绽放的动画
12. THE LED_Display_System SHALL 提供 Neon_Line_Effect 背景效果
13. WHEN 用户选择 Neon_Line_Effect，THE LED_Display_System SHALL 使用发光线条描绘图案或剪影
14. FOR ALL 动画背景效果，THE LED_Display_System SHALL 允许用户调整效果强度
15. THE LED_Display_System SHALL 允许用户组合多个背景效果同时显示

### 需求 12: 模板缩略图预览

**用户故事:** 作为用户，我想要在首页看到每个模板的动态预览，以便在选择前了解效果。

#### 验收标准

1. FOR ALL Template_Card，THE LED_Display_System SHALL 显示 Thumbnail_Preview
2. THE Thumbnail_Preview SHALL 以降低的帧率（至少 15 帧每秒）播放模板的动画效果
3. THE Thumbnail_Preview SHALL 保持模板的原始宽高比
4. WHILE 用户滚动首页，THE LED_Display_System SHALL 仅渲染可见区域的 Thumbnail_Preview 以优化性能
5. WHEN Template_Card 进入可见区域，THE LED_Display_System SHALL 在 500 毫秒内开始播放 Thumbnail_Preview
6. WHEN Template_Card 离开可见区域，THE LED_Display_System SHALL 暂停该 Thumbnail_Preview 的渲染
7. THE Thumbnail_Preview SHALL 循环播放模板效果

### 需求 13: JavaScript 代码模式

**用户故事:** 作为高级用户或开发者，我想要通过编写 JavaScript 代码创建自定义显示效果，以便实现更复杂和个性化的 LED 显示。

#### 验收标准

1. WHEN 用户选择 JavaScript_Code_Mode，THE LED_Display_System SHALL 提供代码编辑器界面
2. WHEN 用户在代码编辑器中输入 JavaScript 代码，THE LED_Display_System SHALL 提供语法高亮显示
3. THE 代码编辑器 SHALL 使用暗色主题配色方案（深色背景配合霓虹色语法高亮）
4. THE 代码编辑器 SHALL 使用霓虹色高亮显示关键字、函数名和字符串
5. WHEN 用户执行 JavaScript 代码，THE Code_Sandbox SHALL 在隔离环境中执行代码
6. WHEN 用户执行 JavaScript 代码，THE LED_Display_System SHALL 提供 Canvas_API 供代码调用
7. THE Canvas_API SHALL 提供绘制基本图形的方法（矩形、圆形、线条、路径）
8. THE Canvas_API SHALL 提供颜色填充和描边方法
9. THE Canvas_API SHALL 提供文字绘制方法
10. THE Canvas_API SHALL 提供图像变换方法（平移、旋转、缩放）
11. THE Canvas_API SHALL 提供动画帧回调机制
12. IF 用户代码执行时间超过 100 毫秒每帧，THEN THE Code_Sandbox SHALL 显示性能警告
13. IF 用户代码抛出异常，THEN THE Code_Sandbox SHALL 捕获异常并显示错误信息
14. THE Code_Sandbox SHALL 限制代码访问设备敏感 API（网络、文件系统、相机等）
15. THE Code_Sandbox SHALL 限制代码内存使用不超过 50MB
16. WHEN 用户代码尝试访问受限 API，THE Code_Sandbox SHALL 阻止访问并记录警告
17. FOR ALL 代码编辑器工具栏按钮，THE LED_Display_System SHALL 使用 Glow_Button 样式

### 需求 14: 实时预览

**用户故事:** 作为用户，我想要在配置时实时预览显示效果，以便快速调整到满意的效果。

#### 验收标准

1. WHEN 用户修改 Display_Configuration 的任何参数，THE LED_Display_System SHALL 在 500 毫秒内更新预览显示
2. WHILE 用户正在配置，THE LED_Display_System SHALL 持续渲染预览效果
3. WHEN 用户在 JavaScript_Code_Mode 中修改代码，THE LED_Display_System SHALL 提供手动刷新预览按钮
4. WHERE 用户启用自动预览，WHEN 用户停止输入代码 2 秒后，THE LED_Display_System SHALL 自动更新预览

### 需求 15: 模板管理

**用户故事:** 作为用户，我想要保存和管理我的显示配置模板，以便快速切换常用的显示效果。

#### 验收标准

1. WHEN 用户完成 Display_Configuration，THE LED_Display_System SHALL 允许用户将配置保存为 Template
2. WHEN 用户保存 Template，THE LED_Display_System SHALL 要求用户提供模板名称
3. THE LED_Display_System SHALL 允许用户查看所有已保存的 Template 列表
4. WHEN 用户选择一个 Template，THE LED_Display_System SHALL 加载该模板的 Display_Configuration 并进入 Fullscreen_Playback_Mode
5. WHEN 用户在"我的创建"分类中删除 Template，THE LED_Display_System SHALL 从本地存储和 iCloud 中删除该模板
6. WHEN 用户在"我的创建"分类中重命名 Template，THE LED_Display_System SHALL 更新模板名称并同步到 iCloud
7. WHEN 用户在"我的创建"分类中编辑 Template，THE LED_Display_System SHALL 打开配置界面允许修改模板参数
8. WHEN 用户保存编辑后的 Template，THE LED_Display_System SHALL 更新 Thumbnail_Preview

### 需求 16: iCloud 同步

**用户故事:** 作为用户，我想要在我的多个 iOS 设备间同步我的模板，以便在任何设备上都能使用我的自定义配置。

#### 验收标准

1. WHERE 用户已登录 iCloud，THE iCloud_Sync_Service SHALL 自动同步用户的所有 Template
2. WHEN 用户在一个设备上创建新 Template，THE iCloud_Sync_Service SHALL 在 30 秒内将该模板同步到用户的其他设备
3. WHEN 用户在一个设备上修改 Template，THE iCloud_Sync_Service SHALL 在 30 秒内将修改同步到用户的其他设备
4. WHEN 用户在一个设备上删除 Template，THE iCloud_Sync_Service SHALL 在 30 秒内将删除操作同步到用户的其他设备
5. IF 同步冲突发生（同一模板在不同设备上同时修改），THEN THE iCloud_Sync_Service SHALL 保留最后修改时间戳较新的版本
6. WHERE 用户未登录 iCloud，THE LED_Display_System SHALL 仅在本地存储 Template
7. WHEN 用户保存包含 JavaScript 代码的 Template，THE iCloud_Sync_Service SHALL 同步代码内容到其他设备
8. THE iCloud_Sync_Service SHALL 限制单个 Template 大小不超过 1MB（包括代码和配置）

### 需求 17: 数据持久化

**用户故事:** 作为用户，我想要我的模板在应用关闭后仍然保存，以便下次打开应用时继续使用。

#### 验收标准

1. WHEN 用户保存 Template，THE LED_Display_System SHALL 将模板持久化到本地存储
2. WHEN 应用启动，THE LED_Display_System SHALL 加载所有本地存储的 Template
3. FOR ALL Template，THE LED_Display_System SHALL 保证数据完整性（所有配置参数正确保存和恢复）

### 需求 18: 错误处理

**用户故事:** 作为用户，我想要在出现错误时收到清晰的提示，以便了解问题并采取相应措施。

#### 验收标准

1. IF iCloud 同步失败，THEN THE iCloud_Sync_Service SHALL 显示错误提示并提供重试选项
2. IF 本地存储空间不足，THEN THE LED_Display_System SHALL 显示存储空间不足提示
3. IF 加载 Template 失败（数据损坏），THEN THE LED_Display_System SHALL 显示错误提示并跳过该模板
4. IF 用户输入的文字内容超过 500 个字符，THEN THE LED_Display_System SHALL 显示字符限制提示
5. IF 用户 JavaScript 代码包含语法错误，THEN THE Code_Sandbox SHALL 显示具体的语法错误信息和行号
6. IF 用户 JavaScript 代码运行时错误，THEN THE Code_Sandbox SHALL 显示错误堆栈信息
7. IF 用户 JavaScript 代码尝试访问受限 API，THEN THE Code_Sandbox SHALL 显示安全限制提示
8. FOR ALL 错误提示和警告信息，THE LED_Display_System SHALL 使用深色背景配合霓虹红色或霓虹黄色文字
9. FOR ALL 错误对话框，THE LED_Display_System SHALL 使用 Glow_Button 样式显示操作按钮

### 需求 19: 性能要求

**用户故事:** 作为用户，我想要流畅的显示效果和快速的响应，以便获得良好的使用体验。

#### 验收标准

1. THE LED_Display_System SHALL 以至少 30 帧每秒的速率渲染动画效果
2. WHEN 用户切换 Template，THE LED_Display_System SHALL 在 300 毫秒内开始显示新效果
3. WHILE 显示 LED 效果，THE LED_Display_System SHALL 保持 CPU 使用率低于 30%
4. THE LED_Display_System SHALL 在应用启动后 2 秒内完成初始化并准备就绪
5. WHILE 执行 JavaScript_Code_Mode，THE Code_Sandbox SHALL 保持帧率至少 30 帧每秒
6. WHEN 用户代码性能不足导致帧率低于 20 帧每秒，THE LED_Display_System SHALL 显示性能警告
7. WHILE 首页显示多个 Thumbnail_Preview，THE LED_Display_System SHALL 保持整体帧率至少 30 帧每秒
8. THE LED_Display_System SHALL 限制同时渲染的 Thumbnail_Preview 数量不超过 10 个以优化性能

### 需求 20: 辅助功能支持

**用户故事:** 作为有辅助功能需求的用户，我想要应用支持 iOS 辅助功能，以便我能够无障碍地使用该功能。

#### 验收标准

1. THE LED_Display_System SHALL 为所有交互元素提供 VoiceOver 标签
2. THE LED_Display_System SHALL 支持动态字体大小调整
3. THE LED_Display_System SHALL 遵循 iOS 辅助功能对比度要求
4. THE LED_Display_System SHALL 确保霓虹色文字与深色背景的对比度符合 WCAG AA 标准（至少 4.5:1）
5. WHERE 用户启用了减少动画选项，THE LED_Display_System SHALL 降低或禁用动画效果
6. WHERE 用户启用了减少动画选项，THE LED_Display_System SHALL 降低或禁用霓虹发光动画效果
7. WHEN 用户使用 JavaScript_Code_Mode，THE LED_Display_System SHALL 为代码编辑器提供 VoiceOver 支持

### 需求 21: 代码模板和示例

**用户故事:** 作为使用 JavaScript 代码模式的用户，我想要获得代码模板和示例，以便快速上手和学习如何创建自定义效果。

#### 验收标准

1. WHEN 用户首次进入 JavaScript_Code_Mode，THE LED_Display_System SHALL 提供欢迎示例代码
2. THE LED_Display_System SHALL 提供至少 5 个预定义代码模板（基础动画、粒子效果、时钟显示、波形效果、交互响应）
3. WHEN 用户选择代码模板，THE LED_Display_System SHALL 将模板代码加载到编辑器
4. THE LED_Display_System SHALL 为每个代码模板提供说明文档
5. THE LED_Display_System SHALL 提供 Canvas_API 文档供用户查阅
6. FOR ALL 代码模板选择界面，THE LED_Display_System SHALL 使用 Dark_Theme 配色
7. FOR ALL 代码模板卡片，THE LED_Display_System SHALL 使用深色背景配合霓虹色边框
8. FOR ALL 文档界面，THE LED_Display_System SHALL 使用深色背景配合浅色或霓虹色文字
