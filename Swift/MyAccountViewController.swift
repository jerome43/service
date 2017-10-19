//
//  MyAccountViewController.swift
//  SocialServices
//
//  Created by Jérôme LIONS on 05/04/2017.
//
// ViewController Class used to manage the my-account tab view


import UIKit
import Firebase


@objc(MyAccountViewController)
class MyAccountViewController: UIViewController {
    
    
    // [START define_database_reference]
    var ref: FIRDatabaseReference!
    // [END define_database_reference]
   
    
    let userId = FIRAuth.auth()?.currentUser?.uid // the user who make the request
    var user : User? // the user who make the request
    @IBOutlet var userNameUI: UILabel!
    @IBOutlet var lastNameUI: UITextField!
    @IBOutlet var firstNameUI: UITextField!
    @IBOutlet var locationUI: UITextField!
    @IBOutlet var phoneUI: UITextField!
    @IBOutlet var servicesUI: UITextView!
    @IBOutlet var seedsUI: UILabel!

    
    // MARK: - View Life Cycle
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // [START create_database_reference]
        self.ref = FIRDatabase.database().reference()
        // [END create_database_reference]
        
        readData() // get the values from Firebase
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
       // print("view will disappear")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // get the user info and the user list of services
    func readData() {
       
    self.ref.child("users/\(self.userId!)").observe(FIRDataEventType.value, with: { (snapshot) in
    let user = snapshot.value as? NSDictionary
    self.user = User.init(uid : self.userId!,
                          userName : user?["userName"] as? String ?? "",
                          lastName : user?["lastName"] as? String ?? "",
                          firstName : user?["firstName"] as? String ?? "",
                          location : user?["location"] as? String ?? "",
                          phoneNumber : user?["phoneNumber"] as? String ?? "",
                          seeds : user?["seeds"] as? Int ?? 10
        )
    self.userNameUI.text = self.user!.userName
    self.lastNameUI.text = self.user!.lastName
    self.firstNameUI.text = self.user!.firstName
    self.locationUI.text = self.user!.location
    self.phoneUI.text = self.user!.phoneNumber
    self.seedsUI.text = String(self.user!.seeds ?? 10)

       
    }) { (error) in
    print(error.localizedDescription)
    }
        
        ref?.child("user-services/\(self.userId!)/service").observe(FIRDataEventType.value, with: { (snapshot) in
            var values = [String]()
           let services  = snapshot.value as? [String : AnyObject] ?? [:]
            
            for service in services.values {
                print("service : \(service["service"] as! String)")
                values.append(service["service"] as! String)
            }
            self.servicesUI.text = values.joined(separator: ", ")
            
            }) { (error) in
            print(error.localizedDescription)
        }

    }
    
    // to save user modifs in DB
    @IBAction func didTapModif(_ sender: AnyObject) {
        print("didTapModif")
        
        // Update user object
        self.user!.lastName = self.lastNameUI.text
        self.user!.firstName = self.firstNameUI.text
        self.user!.location = self.locationUI.text
        self.user!.phoneNumber = self.phoneUI.text
        
        // update the DB
        let childUpdates = ["/users/\(self.userId!)/lastName": self.user!.lastName,
                            "/users/\(self.userId!)/firstName": self.user!.firstName,
                            "/users/\(self.userId!)/location": self.user!.location,
                            "/users/\(self.userId!)/phoneNumber": self.user!.phoneNumber]
                            self.ref.updateChildValues(childUpdates as Any as! [AnyHashable : Any])
        
        // alert user it was updated
          self.showMessagePrompt("Vos nouvelles informations ont été enregistrées")
    }

}
