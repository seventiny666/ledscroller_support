import Foundation

// 代码生成器 - 核心亮点功能
class CodeGenerator {
    
    // 生成伪代码风格的配置代码
    static func generatePseudoCode(from config: LEDConfig) -> String {
        var code = "GlowLed.create {\n"
        code += "    text(\"\(config.text)\")\n"
        code += "    .fontSize(\(Int(config.style.fontSize)))\n"
        code += "    .neonColor(\"\(config.style.color)\")\n"
        code += "    .glow(\(String(format: "%.1f", config.style.glowIntensity)))\n"
        code += "    .background(\"\(config.style.backgroundColor)\")\n"
        
        if config.style.animation != .none {
            code += "    .animate(.\(config.style.animation.rawValue), speed: \(String(format: "%.1f", config.style.speed)))\n"
        }
        
        if !config.effects.isEmpty {
            code += "    \n"
            code += "    effects {\n"
            for effect in config.effects {
                code += "        \(effect.type.rawValue)(density: \(String(format: "%.1f", effect.density)))\n"
            }
            code += "    }\n"
        }
        
        code += "}"
        return code
    }
    
    // 生成 JSON 配置
    static func generateJSON(from config: LEDConfig) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        guard let data = try? encoder.encode(config),
              let jsonString = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return jsonString
    }
    
    // 从 JSON 解析配置
    static func parseJSON(_ jsonString: String) -> LEDConfig? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(LEDConfig.self, from: data)
    }
    
    // 生成 URL Scheme
    static func generateURLScheme(from config: LEDConfig) -> String? {
        guard let jsonData = try? JSONEncoder().encode(config) else { return nil }
        let base64 = jsonData.base64EncodedString()
        return "glowled://import?code=\(base64)"
    }
    
    // 从 URL Scheme 解析
    static func parseURLScheme(_ urlString: String) -> LEDConfig? {
        guard let url = URL(string: urlString),
              url.scheme == "glowled",
              url.host == "import",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let codeParam = components.queryItems?.first(where: { $0.name == "code" })?.value,
              let data = Data(base64Encoded: codeParam) else {
            return nil
        }
        
        return try? JSONDecoder().decode(LEDConfig.self, from: data)
    }
}
