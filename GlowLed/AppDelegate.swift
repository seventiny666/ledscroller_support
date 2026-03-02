import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var orientationLock = UIInterfaceOrientationMask.all
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
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
