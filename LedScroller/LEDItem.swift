import UIKit

// LED屏幕数据模型
struct LEDItem: Codable {
    var id: String
    var text: String
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
    
    init(id: String = UUID().uuidString,
         text: String = "", // 默认为空
         fontSize: CGFloat = 60,
         textColor: String = "#FF00FF",
         backgroundColor: String = "#201F1F",
         backgroundImageName: String? = nil, // 背景图片名称
         glowIntensity: CGFloat = 2.5, // 默认2.5 (0-5范围)
         scrollType: ScrollType = .none,
         speed: CGFloat = 1.0,
         fontName: String = "PingFangSC-Regular",
         borderStyle: Int? = nil, // 跑马灯边框样式
         lightBoardStyle: Int? = nil, // 灯牌边框样式
         linearBorderStyle: Int? = nil, // 线性边框样式
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

    private static let dotMatrixLower = "MatrixSansPrint-Regular"
    private static let dotMatrixUpper = "MatrixSansPrintSC-Regular"
    private static let pixelLower = "MatrixSansScreen-Regular"
    private static let pixelUpper = "MatrixSansScreenSC-Regular"

    static func isMatrixSans(_ fontName: String) -> Bool {
        fontName.hasPrefix("MatrixSansPrint") || fontName.hasPrefix("MatrixSansScreen")
    }

    static func attributedText(
        _ text: String,
        fontName: String,
        size: CGFloat,
        color: UIColor,
        alignment: NSTextAlignment = .center,
        lineSpacing: CGFloat? = nil
    ) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = .byWordWrapping
        if let lineSpacing {
            paragraphStyle.lineSpacing = lineSpacing
        }

        if let (lowerName, upperName) = matrixFontNames(for: fontName),
           let lowerFont = UIFont(name: lowerName, size: size),
           let upperFont = UIFont(name: upperName, size: size) {
            return matrixAttributedText(
                text,
                lowerFont: lowerFont,
                upperFont: upperFont,
                color: color,
                paragraphStyle: paragraphStyle
            )
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
                fontSize: 50,
                textColor: "#FF1493",
                backgroundColor: "#201F1F",
                glowIntensity: 3.5,
                scrollType: .scrollLeft,
                speed: 1.5,
                isDefaultPreset: true
            ),
            LEDItem(
                id: "happy-new-year-default",
                text: "HAPPY NEW YEAR",
                fontSize: 48,
                textColor: "#FFD700",
                backgroundColor: "#201F1F",
                glowIntensity: 3.0,
                scrollType: .scrollRight,
                speed: 1.8,
                isDefaultPreset: true
            ),
            LEDItem(
                id: "merry-christmas-default",
                text: "MERRY CHRISTMAS",
                fontSize: 46,
                textColor: "#FF4500",
                backgroundColor: "#201F1F",
                glowIntensity: 2.8,
                scrollType: .scrollLeft,
                speed: 1.2,
                isDefaultPreset: true
            ),
            LEDItem(
                id: "marry-me-default",
                text: "MARRY ME",
                fontSize: 60,
                textColor: "#FF00FF",
                backgroundColor: "#201F1F",
                glowIntensity: 5.0,
                scrollType: .none,
                speed: 1.0,
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
