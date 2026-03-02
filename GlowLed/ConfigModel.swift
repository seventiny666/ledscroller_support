import UIKit

// 配置数据模型
struct LEDConfig: Codable {
    var version: String = "glowled_v1"
    var text: String
    var style: StyleConfig
    var effects: [EffectConfig]
    
    struct StyleConfig: Codable {
        var fontSize: CGFloat
        var color: String
        var glowIntensity: CGFloat
        var animation: AnimationType
        var speed: CGFloat
        var backgroundColor: String
        
        enum AnimationType: String, Codable {
            case none = "none"
            case scrollLeft = "scroll_left"
            case scrollRight = "scroll_right"
            case scrollUp = "scroll_up"
            case scrollDown = "scroll_down"
            case glitch = "glitch"
        }
    }
    
    struct EffectConfig: Codable {
        var type: EffectType
        var density: CGFloat
        
        enum EffectType: String, Codable {
            case cyberHeart = "cyber_heart"
            case fireworks = "fireworks"
            case meteor = "meteor"
            case codeRain = "code_rain"
        }
    }
}

// 预设模板
struct PresetTemplate {
    let name: String
    let config: LEDConfig
    
    static let templates: [PresetTemplate] = [
        PresetTemplate(
            name: "表白 - I LOVE U",
            config: LEDConfig(
                text: "I LOVE U",
                style: LEDConfig.StyleConfig(
                    fontSize: 72,
                    color: "#FF1493",
                    glowIntensity: 0.9,
                    animation: .none,
                    speed: 1.0,
                    backgroundColor: "#000000"
                ),
                effects: [
                    LEDConfig.EffectConfig(type: .cyberHeart, density: 0.6)
                ]
            )
        ),
        PresetTemplate(
            name: "节日 - Happy New Year",
            config: LEDConfig(
                text: "Happy New Year",
                style: LEDConfig.StyleConfig(
                    fontSize: 60,
                    color: "#FFD700",
                    glowIntensity: 0.8,
                    animation: .scrollLeft,
                    speed: 2.0,
                    backgroundColor: "#000000"
                ),
                effects: [
                    LEDConfig.EffectConfig(type: .fireworks, density: 0.5)
                ]
            )
        ),
        PresetTemplate(
            name: "极客 - Code Rain",
            config: LEDConfig(
                text: "CYBER PUNK",
                style: LEDConfig.StyleConfig(
                    fontSize: 48,
                    color: "#00FF00",
                    glowIntensity: 0.7,
                    animation: .glitch,
                    speed: 1.5,
                    backgroundColor: "#000000"
                ),
                effects: [
                    LEDConfig.EffectConfig(type: .codeRain, density: 0.8)
                ]
            )
        ),
        PresetTemplate(
            name: "流星雨",
            config: LEDConfig(
                text: "MAKE A WISH",
                style: LEDConfig.StyleConfig(
                    fontSize: 56,
                    color: "#00BFFF",
                    glowIntensity: 0.85,
                    animation: .scrollUp,
                    speed: 1.8,
                    backgroundColor: "#000000"
                ),
                effects: [
                    LEDConfig.EffectConfig(type: .meteor, density: 0.4)
                ]
            )
        )
    ]
}
