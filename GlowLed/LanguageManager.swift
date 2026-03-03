import Foundation
import UIKit

// 语言管理器
class LanguageManager {
    static let shared = LanguageManager()
    
    // 支持的语言
    enum Language: String, CaseIterable {
        case english = "en"
        case spanish = "es"
        case german = "de"
        case french = "fr"
        case simplifiedChinese = "zh-Hans"
        case traditionalChinese = "zh-Hant"
        case japanese = "ja"
        case korean = "ko"
        case portuguese = "pt"
        case italian = "it"
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .spanish: return "Español"
            case .german: return "Deutsch"
            case .french: return "Français"
            case .simplifiedChinese: return "简体中文"
            case .traditionalChinese: return "繁體中文"
            case .japanese: return "日本語"
            case .korean: return "한국어"
            case .portuguese: return "Português"
            case .italian: return "Italiano"
            }
        }
    }
    
    private let userDefaultsKey = "AppLanguage"
    private var bundle: Bundle?
    
    var currentLanguage: Language {
        get {
            if let languageCode = UserDefaults.standard.string(forKey: userDefaultsKey),
               let language = Language(rawValue: languageCode) {
                print("🔍 LanguageManager: Loading saved language: \(language.displayName) (\(languageCode))")
                return language
            }
            // 默认使用系统语言
            let systemLang = detectSystemLanguage()
            print("🔍 LanguageManager: Using system language: \(systemLang.displayName)")
            return systemLang
        }
        set {
            print("🔍 LanguageManager: Setting language to: \(newValue.displayName) (\(newValue.rawValue))")
            UserDefaults.standard.set(newValue.rawValue, forKey: userDefaultsKey)
            UserDefaults.standard.synchronize()
            
            // 更新bundle
            if let path = Bundle.main.path(forResource: newValue.rawValue, ofType: "lproj") {
                bundle = Bundle(path: path)
                print("🔍 LanguageManager: Bundle updated successfully for \(newValue.rawValue)")
            } else {
                bundle = Bundle.main
                print("⚠️ LanguageManager: Could not find bundle for \(newValue.rawValue), using main bundle")
            }
            
            // 验证设置是否保存
            if let saved = UserDefaults.standard.string(forKey: userDefaultsKey) {
                print("🔍 LanguageManager: Verified saved language: \(saved)")
            }
        }
    }
    
    private init() {
        // 初始化时设置bundle
        let language = currentLanguage
        if let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj") {
            bundle = Bundle(path: path)
        } else {
            bundle = Bundle.main
        }
    }
    
    // 检测系统语言
    private func detectSystemLanguage() -> Language {
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        
        if preferredLanguage.hasPrefix("zh-Hans") {
            return .simplifiedChinese
        } else if preferredLanguage.hasPrefix("zh-Hant") || preferredLanguage.hasPrefix("zh-HK") || preferredLanguage.hasPrefix("zh-TW") {
            return .traditionalChinese
        } else if preferredLanguage.hasPrefix("es") {
            return .spanish
        } else if preferredLanguage.hasPrefix("de") {
            return .german
        } else if preferredLanguage.hasPrefix("fr") {
            return .french
        } else if preferredLanguage.hasPrefix("ja") {
            return .japanese
        } else if preferredLanguage.hasPrefix("ko") {
            return .korean
        } else if preferredLanguage.hasPrefix("pt") {
            return .portuguese
        } else if preferredLanguage.hasPrefix("it") {
            return .italian
        }
        
        return .english
    }
    
    // 获取本地化字符串
    func localizedString(forKey key: String) -> String {
        let result = bundle?.localizedString(forKey: key, value: nil, table: nil) ?? key
        // 只在关键字符串时打印，避免日志过多
        if ["home", "creations", "settings"].contains(key) {
            print("🔍 LanguageManager: '\(key)' -> '\(result)' (bundle: \(bundle != nil ? "custom" : "main"))")
        }
        return result
    }
}

// String扩展，方便使用
extension String {
    var localized: String {
        return LanguageManager.shared.localizedString(forKey: self)
    }
}
