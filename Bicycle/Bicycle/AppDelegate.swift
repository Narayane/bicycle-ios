//
//  Copyright © 2017 Bicycle (Sébastien BALARD)
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit
import Dip
import Reachability

let log = SBLog.self

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    // DI
    let diContainer = DependencyContainer { container in
        unowned let container = container
        
        #if DEBUG
        Dip.logLevel = .Verbose
        #endif
        
        container.configure()
        try! container.bootstrap() // lock container
        DependencyContainer.uiContainers = [container]
    }
    
    let reachability = Reachability()!
    
    private var _hasConnectivity: Bool = true
    var hasConnectivity: Bool {
        return _hasConnectivity
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let hexaPrimaryDarkColor = Bundle.main.object(forInfoDictionaryKey: "BICPrimaryDarkColor") as? String
        styleStatusBar(hexaBackgroundColor: hexaPrimaryDarkColor)
        
        log.set(level: Bundle.main.object(forInfoDictionaryKey: "SBLogLevel")! as! String)
        SBCrashReport.start()
        
        reachability.whenReachable = { reachability in
            log.i("has connectivity: true")
            self._hasConnectivity = true
            /*if reachability.connection == .wifi {
                print("Reachable via WiFi")
            } else {
                print("Reachable via Cellular")
            }*/
        }
        reachability.whenUnreachable = { _ in
            log.i("has connectivity: false")
            self._hasConnectivity = false
        }
        
        do {
            log.v("watch connectivity")
            try reachability.startNotifier()
        } catch {
            log.e("unable to watch connectivity")
        }
        
        window = UIWindow(frame: UIScreen.main.bounds)
        if let window = window {
            /*let viewController = BICHomeViewController()
            let navigationController = UINavigationController(rootViewController: viewController)
            let primaryColor = UIColor(hex: (Bundle.main.object(forInfoDictionaryKey: "BICPrimaryColor") as? String)!)
            navigationController.styleNavigationBar(barTintColor: primaryColor, tintColor: UIColor.white)
            window.rootViewController = navigationController*/
            window.rootViewController = BICSplashViewController()
            window.backgroundColor = UIColor.white
            window.makeKeyAndVisible()
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        reachability.stopNotifier()
        let localDataSource = try! diContainer.resolve() as BICLocalDataSource
        localDataSource.saveContext()
    }
}

