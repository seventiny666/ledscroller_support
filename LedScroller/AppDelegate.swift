import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var orientationLock = UIInterfaceOrientationMask.all
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 列出所有可用的字体，帮助调试
        print("🔤 ========== 可用字体列表 ==========")
        for family in UIFont.familyNames.sorted() {
            if family.contains("Matrix") {
                print("🔤 字体族: \(family)")
                for fontName in UIFont.fontNames(forFamilyName: family) {
                    print("🔤   - \(fontName)")
                }
            }
        }
        print("🔤 ===================================")
        
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return orientationLock
    }
}


// 扩展方便访问
extension AppDelegate {
    static var orientationLock: UIInterfaceOrientationMask {
        get {
            return (UIApplication.shared.delegate as? AppDelegate)?.orientationLock ?? .all
        }
        set {
            (UIApplication.shared.delegate as? AppDelegate)?.orientationLock = newValue
        }
    }
}
