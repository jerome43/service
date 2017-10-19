//
//  TabBarController.swift
//  SocialServices
//
//  Created by Jérôme LIONS on 06/04/2017.
//
// To customize the management of the TabBarController
//

import UIKit
import Firebase

@objc(TabBarController)
class TabBarController: UITabBarController {
    
    @IBInspectable var defaultIndex: Int = 0 // create a index of tab displayed by default in the storyboard inspector
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedIndex = defaultIndex // go the tab bar view define in the storyboard inspector
        self.navigationItem.title = "Echange de services"
    }

    // log out when clich on sign-out
  override func didMove(toParentViewController parent: UIViewController?) {
    if parent == nil {
      let firebaseAuth = FIRAuth.auth()
      do {
        try firebaseAuth?.signOut()
      } catch let signOutError as NSError {
        print ("Error signing out: %@", signOutError)
      }
    }
  }
    
}
