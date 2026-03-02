# TabBar架构说明

## 功能概述
应用已重构为Tab Bar架构，包含三个主要模块：模版、创作和设置。

## 架构结构

### 1. MainTabBarController（主控制器）
- 管理三个Tab：模版、创作、设置
- 暗色TabBar样式（RGB: 0.05, 0.05, 0.05）
- 粉色选中色，灰色未选中色
- 顶部分隔线
- 自动处理屏幕方向切换

### 2. 模版（TemplateSquareViewController）
- 标题：模版
- 纯黑背景（RGB: 0, 0, 0）
- 包含5个分类：
  1. 霓虹灯看板（4个模版，2行×2列）
  2. 偶像应援（4个模版，2行×2列）
  3. LED屏幕（4个模版，2行×2列）
  4. 数字时钟（1个：翻页时钟）
  5. 其他分类（包含所有已创建的LED卡片，2行×2列）

### 3. 创作（MyCreationsViewController）
- 标题：创作
- 纯黑背景（RGB: 0, 0, 0）
- 第一个是虚线边框的"创建LED"按钮
- 显示用户创建的LED作品（2列布局）
- 支持长按编辑和删除
- 点击作品进入全屏播放

### 4. 设置（SettingsViewController）
- 标题：设置
- 关于我们
- 版本 1.0
- 恢复购买
- 反馈意见
- 评价应用

## 文件清单

### 新增文件
- `MainTabBarController.swift` - 主TabBar控制器
- `TemplateSquareViewController.swift` - 模版页面
- `MyCreationsViewController.swift` - 创作页面
- `SettingsViewController.swift` - 设置页面
- `图片资源说明.md` - 图片资源使用说明

### 修改文件
- `SceneDelegate.swift` - 更新根视图控制器为TabBar
- `GlowLed.xcodeproj/project.pbxproj` - 添加新文件引用（包括MyCreationsViewController）

### 保留文件
- `LEDSquareViewController.swift` - 保留但不再作为主页使用
- 所有其他功能文件保持不变

## 模版卡片样式

### 卡片布局
- 每行2个卡片（改为2列布局）
- 容器圆角：16px
- 图片圆角：12px
- 容器背景：深灰色 (RGB: 0.1, 0.1, 0.1)
- 间距：12px

### 卡片内容
- 顶部：16:9比例的图片（圆角12px）
- 底部：文字标题（居中，白色，13pt medium）
- 内边距：12px

### 占位符
- 无图片时显示深色背景 (RGB: 0.15, 0.15, 0.15)
- 显示模版名称文字

## 创作页面样式

### "创建LED"按钮
- 虚线边框（systemGray3）
- 圆角：16px
- 虚线样式：[6, 4]
- 加号图标（systemGray）
- "创建LED"文字（systemGray，15pt medium）

### 创作卡片
- 容器背景：深灰色 (RGB: 0.1, 0.1, 0.1)
- 容器圆角：16px
- 预览区域圆角：12px
- 2列布局
- 支持长按菜单（编辑、删除）

## 图片资源

### 存放位置
`Assets.xcassets` 文件夹

### 命名规则
- 霓虹灯：`neon_1.png` ~ `neon_4.png`
- 偶像应援：`idol_1.png` ~ `idol_4.png`
- LED屏幕：`led_1.png` ~ `led_4.png`

### 图片规格
- 比例：16:9
- 推荐尺寸：1920x1080 或 1280x720
- 格式：PNG或JPG
- 大小：不超过500KB

## 数据模型扩展

### LEDItem新增属性（通过扩展）
```swift
var isNeonTemplate: Bool      // 是否为霓虹灯模版
var isIdolTemplate: Bool       // 是否为偶像应援模版
var isLEDTemplate: Bool        // 是否为LED屏幕模版
var imageName: String?         // 图片名称
```

### 模版ID规则
- 霓虹灯：`neon-1` ~ `neon-4`
- 偶像应援：`idol-1` ~ `idol-4`
- LED屏幕：`led-1` ~ `led-4`

## 分类逻辑

### 霓虹灯看板
- 显示4个占位模版（2行×2列）
- ID前缀：`neon-`
- 图片：`neon_1.png` ~ `neon_4.png`

### 偶像应援
- 显示4个占位模版（2行×2列）
- ID前缀：`idol-`
- 图片：`idol_1.png` ~ `idol_4.png`

### LED屏幕
- 显示4个占位模版（2行×2列）
- ID前缀：`led-`
- 图片：`led_1.png` ~ `led_4.png`

### 数字时钟
- 只显示翻页时钟
- 过滤条件：`isFlipClock == true`

### 其他分类
- 显示所有用户创建的LED卡片
- 包括：HAPPY BIRTHDAY、爱心流星雨、烟花等
- 过滤条件：非模版、非时钟

## 交互流程

### 启动流程
1. 应用启动 → MainTabBarController
2. 默认显示"模版"Tab
3. 加载所有分类和模版

### 点击模版
1. 用户点击模版卡片
2. 根据类型跳转：
   - 爱心流星雨 → LoveRainViewController（横屏）
   - 翻页时钟 → FlipClockViewController（横屏）
   - 烟花绽放 → FireworksBloomViewController（竖屏）
   - 烟花 → FireworksViewController（竖屏）
   - 其他 → LEDFullScreenViewController（横屏）

### 创作功能
1. 用户切换到"创作"Tab
2. 第一个显示"创建LED"按钮（虚线边框）
3. 点击按钮弹出LEDCreateViewController
4. 创建完成后保存到创作列表
5. 支持长按编辑和删除
6. 点击作品进入全屏播放

### 设置功能
1. 用户点击"设置"Tab
2. 显示设置列表
3. 点击设置项显示对应信息

## 屏幕方向管理

### 竖屏页面
- 模版页面
- 创作页面
- 设置页面
- 烟花效果（两种）

### 横屏页面
- 爱心流星雨
- 翻页时钟
- LED全屏显示

### 自动切换
- 进入页面前设置 `AppDelegate.orientationLock`
- 退出页面后恢复竖屏

## 样式规范

### 颜色方案
- 主背景：纯黑 RGB(0, 0, 0)
- TabBar背景：RGB(0.05, 0.05, 0.05)
- 卡片容器：深灰 RGB(0.1, 0.1, 0.1)
- 占位符：RGB(0.15, 0.15, 0.15)
- 主题色：systemPink
- 文字：白色
- 未选中：systemGray

### 字体
- 分类标题：20pt, bold
- 卡片标题：13pt, medium
- 设置项：16pt, medium
- 创建按钮：15pt, medium

### 圆角
- 卡片容器：16px
- 图片：12px
- 虚线按钮：16px

## 后续优化建议

1. **图片加载**
   - 添加图片缓存
   - 支持网络图片
   - 添加加载动画

2. **模版管理**
   - 支持模版收藏
   - 支持模版搜索
   - 添加模版分享

3. **用户体验**
   - 添加下拉刷新
   - 添加骨架屏
   - 优化加载速度

4. **功能扩展**
   - 支持自定义分类
   - 支持模版编辑
   - 添加模版预览

## 测试检查清单

- [ ] TabBar显示正常（暗色背景）
- [ ] 三个Tab可以切换（模版、创作、设置）
- [ ] 模版页面显示5个分类
- [ ] 每个分类显示正确数量的卡片（2列布局）
- [ ] 占位符颜色显示正常
- [ ] 点击卡片跳转正确页面
- [ ] 创作页面第一个是虚线"创建LED"按钮
- [ ] 点击创建按钮弹出创建页面
- [ ] 创作列表显示用户作品（2列）
- [ ] 长按作品显示编辑/删除菜单
- [ ] 点击作品进入全屏播放
- [ ] 屏幕方向切换正常
- [ ] 设置页面显示正常
- [ ] 所有设置项可以点击
- [ ] MyCreationsViewController已添加到Xcode项目

## 注意事项

1. 图片资源需要手动添加到Assets.xcassets
2. 图片命名必须严格遵循规则
3. 确保所有文件已添加到Xcode项目
4. 测试不同设备的显示效果
5. 检查内存使用情况

## 编译步骤

1. 在Xcode中打开项目
2. 按 Cmd+B 构建项目
3. 选择模拟器或真机
4. 按 Cmd+R 运行应用
5. 测试所有功能

## 问题排查

### TabBar不显示
- 检查SceneDelegate是否正确设置
- 确认MainTabBarController已添加到项目

### 模版不显示
- 检查TemplateSquareViewController是否正确加载
- 确认数据源方法实现正确

### 图片不显示
- 检查图片是否添加到Assets.xcassets
- 确认图片命名是否正确
- 查看占位符是否显示

### 点击无响应
- 检查delegate方法是否实现
- 确认手势识别器没有冲突
- 查看控制台错误信息
