//
//  AppDelegate.swift
//  SocialServices
//
//  Created by Jérôme LIONS on 05/04/2017.
//
// Generic delegate class of the app
// We only use it to configure the firebase app
//

import UIKit
import Firebase


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
    
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
    // [START initialize_firebase]
    FIRApp.configure()
     // [END initialize_firebase]
    
    // allow to persist data on disk for offline use
    FIRDatabase.database().persistenceEnabled = true
   
    return true
    }
}
