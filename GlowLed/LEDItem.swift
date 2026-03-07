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
    var isFireworks: Bool // 标识是否为烟花效果
    var isFireworksBloom: Bool // 标识是否为烟花绽放效果（第二种）
    var isFlipClock: Bool // 标识是否为翻页时钟效果
    var isLoveRain: Bool // 标识是否为爱心流星雨效果
    var isHeartGrid: Bool // 标识是否为爱心格子动画效果
    var isDefaultPreset: Bool // 标识是否为预设卡片（HAPPY BIRTHDAY等）
    var createdAt: Date
    
    enum ScrollType: String, Codable {
        case none = "静止"
        case scrollLeft = "左滚"
        case scrollRight = "右滚"
        case scrollUp = "上滚"
        case scrollDown = "下滚"
        case blink = "闪烁"
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
         isFireworks: Bool = false,
         isFireworksBloom: Bool = false,
         isFlipClock: Bool = false,
         isLoveRain: Bool = false,
         isHeartGrid: Bool = false,
         isDefaultPreset: Bool = false,
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
        self.isFireworks = isFireworks
        self.isFireworksBloom = isFireworksBloom
        self.isFlipClock = isFlipClock
        self.isLoveRain = isLoveRain
        self.isHeartGrid = isHeartGrid
        self.isDefaultPreset = isDefaultPreset
        self.createdAt = createdAt
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
                text: "💖 爱心流星雨",
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
            )
        ]
    }
}
