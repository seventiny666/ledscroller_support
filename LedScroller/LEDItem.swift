import UIKit

// LED屏幕数据模型
struct LEDItem: Codable {
    var id: String
    var text: String
    var isTextWrapEnabled: Bool
    var fontSize: CGFloat
    var textColor: String
    var backgroundColor: String
    var backgroundImageName: String? // 背景图片名称（如：neon_1, idol_2, led_3）
    var glowIntensity: CGFloat
    var scrollType: ScrollType
    var speed: CGFloat
    var fontName: String
    var borderStyle: Int? // 跑马灯边框样式索引（0-11对应12种样式，nil表示无边框）
    var lightBoardStyle: Int? // 灯牌边框样式索引（0-7对应8种样式，nil表示无边框）
    var linearBorderStyle: Int? // 线性边框样式索引（0-7对应8种颜色，nil表示无边框）
    var ledBorderImageIndex: Int? // LED边框图片索引（1-8对应line_1到line_8，nil表示无边框）
    var borderWidthAdjustment: CGFloat? // 边框宽度调整值（正数加粗，负数减细，nil表示默认）
    var borderSafeInsetAdjustment: CGFloat? // 安全区距离调整值（正数往外扩，负数往内缩，nil表示默认）
    var isFireworks: Bool // 标识是否为烟花效果
    var isFireworksBloom: Bool // 标识是否为烟花绽放效果（第二种）
    var isFlipClock: Bool // 标识是否为翻页时钟效果
    var isDigitalClock: Bool // 标识是否为数码管数字时钟（纯显示）
    var isStopwatch: Bool // 标识是否为秒表效果（纯显示 + 交互）
    var isCountdown: Bool // 标识是否为倒计时效果（圆环 + 交互）
    var isLoveRain: Bool // 标识是否为爱心流星雨效果
    var isHeartGrid: Bool // 标识是否为爱心格子动画效果
    var isILoveU: Bool // 标识是否为I LOVE U动画效果
    var is520: Bool // 标识是否为520动画效果
    var isDefaultPreset: Bool // 标识是否为预设卡片（HAPPY BIRTHDAY等）
    var isVIPRequired: Bool // 标识是否需要VIP才能使用
    var createdAt: Date
    
    enum ScrollType: String, Codable {
        case none = "静止"
        case scrollLeft = "左滚"
        case scrollRight = "右滚"
        case scrollUp = "上滚"
        case scrollDown = "下滚"
        case blink = "闪烁"
    }

    // Custom Codable so new fields (e.g. isDigitalClock) default to false when decoding older saved data.
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case isTextWrapEnabled
        case fontSize
        case textColor
        case backgroundColor
        case backgroundImageName
        case glowIntensity
        case scrollType
        case speed
        case fontName
        case borderStyle
        case lightBoardStyle
        case linearBorderStyle
        case ledBorderImageIndex
        case borderWidthAdjustment
        case borderSafeInsetAdjustment
        case isFireworks
        case isFireworksBloom
        case isFlipClock
        case isDigitalClock
        case isStopwatch
        case isCountdown
        case isLoveRain
        case isHeartGrid
        case isILoveU
        case is520
        case isDefaultPreset
        case isVIPRequired
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        text = try c.decode(String.self, forKey: .text)
        isTextWrapEnabled = try c.decodeIfPresent(Bool.self, forKey: .isTextWrapEnabled) ?? true
        fontSize = try c.decode(CGFloat.self, forKey: .fontSize)
        textColor = try c.decode(String.self, forKey: .textColor)
        backgroundColor = try c.decode(String.self, forKey: .backgroundColor)
        backgroundImageName = try c.decodeIfPresent(String.self, forKey: .backgroundImageName)
        glowIntensity = try c.decode(CGFloat.self, forKey: .glowIntensity)
        scrollType = try c.decode(ScrollType.self, forKey: .scrollType)
        speed = try c.decode(CGFloat.self, forKey: .speed)
        fontName = try c.decode(String.self, forKey: .fontName)
        borderStyle = try c.decodeIfPresent(Int.self, forKey: .borderStyle)
        lightBoardStyle = try c.decodeIfPresent(Int.self, forKey: .lightBoardStyle)
        linearBorderStyle = try c.decodeIfPresent(Int.self, forKey: .linearBorderStyle)
        ledBorderImageIndex = try c.decodeIfPresent(Int.self, forKey: .ledBorderImageIndex)
        borderWidthAdjustment = try c.decodeIfPresent(CGFloat.self, forKey: .borderWidthAdjustment)
        borderSafeInsetAdjustment = try c.decodeIfPresent(CGFloat.self, forKey: .borderSafeInsetAdjustment)
        isFireworks = try c.decodeIfPresent(Bool.self, forKey: .isFireworks) ?? false
        isFireworksBloom = try c.decodeIfPresent(Bool.self, forKey: .isFireworksBloom) ?? false
        isFlipClock = try c.decodeIfPresent(Bool.self, forKey: .isFlipClock) ?? false
        isDigitalClock = try c.decodeIfPresent(Bool.self, forKey: .isDigitalClock) ?? false
        isStopwatch = try c.decodeIfPresent(Bool.self, forKey: .isStopwatch) ?? false
        isCountdown = try c.decodeIfPresent(Bool.self, forKey: .isCountdown) ?? false
        isLoveRain = try c.decodeIfPresent(Bool.self, forKey: .isLoveRain) ?? false
        isHeartGrid = try c.decodeIfPresent(Bool.self, forKey: .isHeartGrid) ?? false
        isILoveU = try c.decodeIfPresent(Bool.self, forKey: .isILoveU) ?? false
        is520 = try c.decodeIfPresent(Bool.self, forKey: .is520) ?? false
        isDefaultPreset = try c.decodeIfPresent(Bool.self, forKey: .isDefaultPreset) ?? false
        isVIPRequired = try c.decodeIfPresent(Bool.self, forKey: .isVIPRequired) ?? false
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(text, forKey: .text)
        try c.encode(isTextWrapEnabled, forKey: .isTextWrapEnabled)
        try c.encode(fontSize, forKey: .fontSize)
        try c.encode(textColor, forKey: .textColor)
        try c.encode(backgroundColor, forKey: .backgroundColor)
        try c.encodeIfPresent(backgroundImageName, forKey: .backgroundImageName)
        try c.encode(glowIntensity, forKey: .glowIntensity)
        try c.encode(scrollType, forKey: .scrollType)
        try c.encode(speed, forKey: .speed)
        try c.encode(fontName, forKey: .fontName)
        try c.encodeIfPresent(borderStyle, forKey: .borderStyle)
        try c.encodeIfPresent(lightBoardStyle, forKey: .lightBoardStyle)
        try c.encodeIfPresent(linearBorderStyle, forKey: .linearBorderStyle)
        try c.encodeIfPresent(ledBorderImageIndex, forKey: .ledBorderImageIndex)
        try c.encodeIfPresent(borderWidthAdjustment, forKey: .borderWidthAdjustment)
        try c.encodeIfPresent(borderSafeInsetAdjustment, forKey: .borderSafeInsetAdjustment)
        try c.encode(isFireworks, forKey: .isFireworks)
        try c.encode(isFireworksBloom, forKey: .isFireworksBloom)
        try c.encode(isFlipClock, forKey: .isFlipClock)
        try c.encode(isDigitalClock, forKey: .isDigitalClock)
        try c.encode(isStopwatch, forKey: .isStopwatch)
        try c.encode(isCountdown, forKey: .isCountdown)
        try c.encode(isLoveRain, forKey: .isLoveRain)
        try c.encode(isHeartGrid, forKey: .isHeartGrid)
        try c.encode(isILoveU, forKey: .isILoveU)
        try c.encode(is520, forKey: .is520)
        try c.encode(isDefaultPreset, forKey: .isDefaultPreset)
        try c.encode(isVIPRequired, forKey: .isVIPRequired)
        try c.encode(createdAt, forKey: .createdAt)
    }
    
    // Derived VIP gate based on the same rules used by the editor (background + borders).
    // This keeps the home/template VIP badge consistent with what actually requires subscription.
    var requiresVIPByContent: Bool {
        // Check background first - only return true if background requires VIP
        if let name = backgroundImageName {
            if name.hasPrefix("led_"),
               let numberStr = name.split(separator: "_").last,
               let number = Int(numberStr) {
                // led_1-4 免费，led_5+ 需要VIP
                if number >= 5 {
                    return true
                }
            }
            if name.hasPrefix("neon_"),
               let numberStr = name.split(separator: "_").last,
               let number = Int(numberStr) {
                // neon_1-3 不需要VIP（免费背景）
                // neon_4+ 不需要VIP，继续检查其他条件
                if number == 4 {
                    // neon_4 特殊处理：在首页配置中使用了边框，需要VIP
                    // 但如果用户在编辑页选择 neon_4 作为背景，不会自动有边框
                    // 所以这里不返回true，让边框判断决定
                }
            }
            if name.hasPrefix("idol_"),
               let numberStr = name.split(separator: "_").last,
               let number = Int(numberStr) {
                if number >= 5 {
                    return true  // idol_5+ need VIP
                }
                // idol_1-4 don't need VIP, continue checking other conditions
            }
        }

        // Font rules: keep consistent with the editor's font picker VIP badges.
        // In LEDCreateViewController, indices >= 3 are marked VIP.
        // Those correspond to: dotMatrix, pixel, mat, raster, smooth, video.
        // (pingfang/thin/medium are free)
        let vipFontNames: Set<String> = [
            LEDFontRenderer.dotMatrixFontName,
            LEDFontRenderer.pixelFontName,
            LEDFontRenderer.matFontName,
            LEDFontRenderer.rasterFontName,
            LEDFontRenderer.smoothFontName,
            LEDFontRenderer.videoFontName
        ]
        if vipFontNames.contains(fontName) {
            return true
        }

        // Border rules: first 4 marquee borders are free, rest require VIP
        if let style = borderStyle, style >= 4 {
            return true
        }
        
        // LightBoard and Linear borders always require VIP
        if lightBoardStyle != nil || linearBorderStyle != nil {
            return true
        }

        return false
    }

    init(id: String = UUID().uuidString,
         text: String = "", // 默认为空
         isTextWrapEnabled: Bool = true,
         fontSize: CGFloat = 60,
         textColor: String = "#FF00FF",
         backgroundColor: String = "#000000",
         backgroundImageName: String? = nil, // 背景图片名称
         glowIntensity: CGFloat = 2.5, // 默认2.5 (0-5范围)
         scrollType: ScrollType = .none,
         speed: CGFloat = 1.0,
         fontName: String = "PingFangSC-Regular",
         borderStyle: Int? = nil, // 跑马灯边框样式
         lightBoardStyle: Int? = nil, // 灯牌边框样式
         linearBorderStyle: Int? = nil, // 线性边框样式
         ledBorderImageIndex: Int? = nil, // LED边框图片索引
         borderWidthAdjustment: CGFloat? = nil, // 边框宽度调整值
         borderSafeInsetAdjustment: CGFloat? = nil, // 安全区距离调整值
         isFireworks: Bool = false,
         isFireworksBloom: Bool = false,
         isFlipClock: Bool = false,
         isDigitalClock: Bool = false,
         isStopwatch: Bool = false,
         isCountdown: Bool = false,
         isLoveRain: Bool = false,
         isHeartGrid: Bool = false,
         isILoveU: Bool = false,
         is520: Bool = false,
         isDefaultPreset: Bool = false,
         isVIPRequired: Bool = false,
         createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.isTextWrapEnabled = isTextWrapEnabled
        self.fontSize = fontSize
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.backgroundImageName = backgroundImageName
        self.glowIntensity = glowIntensity
        self.scrollType = scrollType
        self.speed = speed
        self.fontName = fontName
        self.borderStyle = borderStyle
        self.lightBoardStyle = lightBoardStyle
        self.linearBorderStyle = linearBorderStyle
        self.ledBorderImageIndex = ledBorderImageIndex
        self.borderWidthAdjustment = borderWidthAdjustment
        self.borderSafeInsetAdjustment = borderSafeInsetAdjustment
        self.isFireworks = isFireworks
        self.isFireworksBloom = isFireworksBloom
        self.isFlipClock = isFlipClock
        self.isDigitalClock = isDigitalClock
        self.isStopwatch = isStopwatch
        self.isCountdown = isCountdown
        self.isLoveRain = isLoveRain
        self.isHeartGrid = isHeartGrid
        self.isILoveU = isILoveU
        self.is520 = is520
        self.isDefaultPreset = isDefaultPreset
        self.isVIPRequired = isVIPRequired
        self.createdAt = createdAt
    }
}

struct LEDFontRenderer {
    static let dotMatrixFontName = "MatrixSansPrint-Regular"
    static let pixelFontName = "MatrixSansScreen-Regular"

    // VIP MatrixSans variants (match bundled TTF + postscript name)
    static let matFontName = "MatrixSans-Regular"
    static let rasterFontName = "MatrixSansRaster-Regular"
    static let smoothFontName = "MatrixSansSmooth-Regular"
    static let videoFontName = "MatrixSansVideo-Regular"

    /// Apply a neon-like glow that tracks the text color.
    /// Intensity is expected to be in 0...20 (slider range).
    static func applyNeonGlow(to layer: CALayer, color: UIColor, intensity: CGFloat, fontSize: CGFloat) {
        // User expectation: the slider controls glow *opacity* (brightness), not the blur radius.
        let t = max(0, min(intensity / 20.0, 1.0))
        if t <= 0 {
            layer.shadowOpacity = 0
            layer.shadowRadius = 0
            return
        }

        layer.masksToBounds = false
        layer.shadowColor = color.cgColor
        layer.shadowOffset = .zero

        // Fixed blur radius (does not change with the slider).
        // Keep it reasonable even for very large font sizes (e.g. 320/520).
        let radius = min(max(4, fontSize * 0.08), 10)
        layer.shadowRadius = radius

        // Opacity controls perceived glow strength. sqrt() makes low values more noticeable.
        layer.shadowOpacity = Float(pow(Double(t), 0.5))
    }

    private static let dotMatrixLower = "MatrixSansPrint-Regular"
    private static let dotMatrixUpper = "MatrixSansPrintSC-Regular"
    private static let pixelLower = "MatrixSansScreen-Regular"
    private static let pixelUpper = "MatrixSansScreenSC-Regular"

    private static let matLower = "MatrixSans-Regular"
    private static let matUpper = "MatrixSansSC-Regular"
    private static let rasterLower = "MatrixSansRaster-Regular"
    private static let rasterUpper = "MatrixSansRasterSC-Regular"
    private static let smoothLower = "MatrixSansSmooth-Regular"
    private static let smoothUpper = "MatrixSansSmoothSC-Regular"
    private static let videoLower = "MatrixSansVideo-Regular"
    private static let videoUpper = "MatrixSansVideoSC-Regular"

    static func isMatrixSans(_ fontName: String) -> Bool {
        // All MatrixSans variants start with this prefix.
        fontName.hasPrefix("MatrixSans")
    }

    static func attributedText(
        _ text: String,
        fontName: String,
        size: CGFloat,
        color: UIColor,
        alignment: NSTextAlignment = .center,
        lineBreakMode: NSLineBreakMode = .byWordWrapping,
        lineSpacing: CGFloat? = nil
    ) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = lineBreakMode
        if let lineSpacing {
            paragraphStyle.lineSpacing = lineSpacing
        }

        if let (lowerName, upperName) = matrixFontNames(for: fontName) {
            print("🔤 尝试加载MatrixSans字体: \(fontName) -> lower=\(lowerName), upper=\(upperName)")
            if let lowerFont = UIFont(name: lowerName, size: size),
               let upperFont = UIFont(name: upperName, size: size) {
                print("🔤 ✅ MatrixSans字体加载成功: \(lowerName)")
                return matrixAttributedText(
                    text,
                    lowerFont: lowerFont,
                    upperFont: upperFont,
                    color: color,
                    paragraphStyle: paragraphStyle
                )
            } else {
                print("🔤 ❌ MatrixSans字体加载失败: lower=\(lowerName), fontName=\(fontName)")
                // 列出可用字体帮助调试
                let familyNames = UIFont.familyNames
                for family in familyNames {
                    if family.contains("Matrix") {
                        print("🔤 可用的Matrix字体族: \(family) -> \(UIFont.fontNames(forFamilyName: family))")
                    }
                }
            }
        }

        let font = UIFont(name: fontName, size: size) ?? .systemFont(ofSize: size, weight: .medium)
        return NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraphStyle,
            ]
        )
    }

    private static func matrixFontNames(for fontName: String) -> (String, String)? {
        if fontName.hasPrefix("MatrixSansPrint") {
            return (dotMatrixLower, dotMatrixUpper)
        }
        if fontName.hasPrefix("MatrixSansScreen") {
            return (pixelLower, pixelUpper)
        }
        if fontName.hasPrefix("MatrixSansRaster") {
            return (rasterLower, rasterUpper)
        }
        if fontName.hasPrefix("MatrixSansSmooth") {
            return (smoothLower, smoothUpper)
        }
        if fontName.hasPrefix("MatrixSansVideo") {
            return (videoLower, videoUpper)
        }
        if fontName.hasPrefix("MatrixSans") {
            // Mat
            return (matLower, matUpper)
        }
        return nil
    }

    private static func matrixAttributedText(
        _ text: String,
        lowerFont: UIFont,
        upperFont: UIFont,
        color: UIColor,
        paragraphStyle: NSParagraphStyle
    ) -> NSAttributedString {
        let attributed = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: (text as NSString).length)
        attributed.addAttributes(
            [
                .foregroundColor: color,
                .paragraphStyle: paragraphStyle,
            ],
            range: fullRange
        )

        var location = 0
        for ch in text {
            let s = String(ch)
            let len = (s as NSString).length
            let range = NSRange(location: location, length: len)
            let font = isLowercaseAsciiLetter(s) ? lowerFont : upperFont
            attributed.addAttribute(.font, value: font, range: range)
            location += len
        }

        return attributed
    }

    private static func isLowercaseAsciiLetter(_ s: String) -> Bool {
        guard let scalar = s.unicodeScalars.first, s.unicodeScalars.count == 1 else {
            return false
        }
        return (97...122).contains(Int(scalar.value))
    }
}

// 数据持久化管理
class LEDDataManager {
    static let shared = LEDDataManager()
    private let userDefaults = UserDefaults.standard
    private let key = "savedLEDItems"
    
    private init() {}
    
    func saveItems(_ items: [LEDItem]) {
        if let encoded = try? JSONEncoder().encode(items) {
            userDefaults.set(encoded, forKey: key)
        }
    }
    
    func loadItems() -> [LEDItem] {
        guard let data = userDefaults.data(forKey: key),
              let savedItems = try? JSONDecoder().decode([LEDItem].self, from: data) else {
            // 如果没有保存的数据，返回默认数据
            return getDefaultItems()
        }
        
        // 合并保存的数据和默认数据
        // 确保默认的特殊效果卡片始终存在
        let defaultItems = getDefaultItems()
        var mergedItems: [LEDItem] = []
        
        // 首先添加所有默认卡片（包括更新的预设卡片）
        for defaultItem in defaultItems {
            mergedItems.append(defaultItem)
        }
        
        // 然后添加用户创建的卡片（排除默认卡片的ID）
        let defaultIds = Set(defaultItems.map { $0.id })
        for savedItem in savedItems {
            if !defaultIds.contains(savedItem.id) {
                mergedItems.append(savedItem)
            }
        }
        
        return mergedItems
    }
    
    private func getDefaultItems() -> [LEDItem] {
        return [
            LEDItem(
                id: "love-rain-special",
                text: "I LOVE U",
                fontSize: 42,
                textColor: "#FF69B4",
                backgroundColor: "#201F1F",
                glowIntensity: 4.0,
                scrollType: .none,
                speed: 1.0,
                isLoveRain: true
            ),
            LEDItem(
                id: "happy-birthday-default",
                text: "HAPPY BIRTHDAY",
                fontSize: 80,
                textColor: "#FFD700", // textColors row 2, first
                backgroundColor: "#201F1F",
                backgroundImageName: "neon_8", // Neon Screen row 2, col 4
                glowIntensity: 3.5,
                scrollType: .none,
                speed: 1.5,
                fontName: LEDFontRenderer.rasterFontName,
                borderStyle: 2, // Marquee Border row 1, col 3
                isDefaultPreset: true
            ),
            LEDItem(
                id: "happy-new-year-default",
                text: "HAPPY NEW YEAR",
                fontSize: 74,
                textColor: "#FFFFFF",
                backgroundColor: "#201F1F",
                backgroundImageName: "idol_6", // Neon Screen row 4, col 2 (idol_6)
                glowIntensity: 3.5,
                scrollType: .none,
                speed: 1.0,
                fontName: LEDFontRenderer.rasterFontName,
                borderStyle: 11, // Marquee Border row 3, last (style12)
                isDefaultPreset: true
            ),
            LEDItem(
                id: "merry-christmas-default",
                text: "Merry\nChristmas!",
                fontSize: 90,
                textColor: "#00FFFF", // textColors row 1, col 7 (cyan)
                backgroundColor: "#000000", // 黑色背景
                backgroundImageName: "neon_18", // Neon Screen row 5, col 2
                glowIntensity: 3.5,
                scrollType: .blink,
                speed: 1.0,
                fontName: LEDFontRenderer.rasterFontName,
                linearBorderStyle: 2, // Linear Border row 2, col 3 (blue)
                isDefaultPreset: true
            ),
            LEDItem(
                id: "marry-me-default",
                text: "Marry Me",
                fontSize: 110,
                textColor: "#FF00FF", // textColors row 1, col 6
                backgroundColor: "#201F1F",
                backgroundImageName: "neon_8", // Neon Screen row 2, col 4
                glowIntensity: 3.5,
                scrollType: .blink,
                speed: 1.0,
                fontName: LEDFontRenderer.pixelFontName,
                linearBorderStyle: 4, // Linear Border row 2, col 2 (purple)
                isDefaultPreset: true
            ),
            LEDItem(
                id: "i-heart-u-default",
                text: "I ❤️ U",
                fontSize: 70,
                textColor: "#FF1493",
                backgroundColor: "#201F1F",
                glowIntensity: 4.5,
                scrollType: .none,
                speed: 1.0,
                isDefaultPreset: true
            ),
            LEDItem(
                id: "i-love-u-default",
                text: "I LOVE U",
                fontSize: 55,
                textColor: "#FF69B4",
                backgroundColor: "#201F1F",
                glowIntensity: 3.5,
                scrollType: .scrollLeft,
                speed: 1.3,
                isDefaultPreset: true
            ),
            LEDItem(
                id: "fireworks-special",
                text: "🎆 烟花",
                fontSize: 50,
                textColor: "#FFD700",
                backgroundColor: "#201F1F",
                glowIntensity: 4.0,
                scrollType: .none,
                speed: 1.0,
                isFireworks: true
            ),
            LEDItem(
                id: "fireworks-bloom-special",
                text: "🎇 烟花绽放",
                fontSize: 45,
                textColor: "#FF69B4",
                backgroundColor: "#201F1F",
                glowIntensity: 4.0,
                scrollType: .none,
                speed: 1.0,
                isFireworks: true,
                isFireworksBloom: true
            ),
            LEDItem(
                id: "flip-clock-special",
                text: "",
                fontSize: 45,
                textColor: "#FFFFFF",
                backgroundColor: "#201F1F",
                glowIntensity: 2.0,
                scrollType: .none,
                speed: 1.0,
                isFlipClock: true
            ),
            LEDItem(
                id: "digital-clock-special",
                text: "",
                fontSize: 45,
                textColor: "#8EFFE6",
                backgroundColor: "#000000",
                glowIntensity: 0,
                scrollType: .none,
                speed: 1.0,
                isDigitalClock: true
            ),
            LEDItem(
                id: "stopwatch-special",
                text: "",
                fontSize: 45,
                textColor: "#FF2A2A",
                backgroundColor: "#000000",
                glowIntensity: 0,
                scrollType: .none,
                speed: 1.0,
                isStopwatch: true
            ),
            LEDItem(
                id: "countdown-special",
                text: "",
                fontSize: 45,
                textColor: "#8EFFE6",
                backgroundColor: "#000000",
                glowIntensity: 0,
                scrollType: .none,
                speed: 1.0,
                isCountdown: true
            )
        ]
    }
}
