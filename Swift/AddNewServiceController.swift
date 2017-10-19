//
//  AddNewServiceController.swift
//  SocialServices
//
//  Created by Jérôme LIONS on 05/04/2017.
// ViewController Class used to manage the add-new-service view
//

import UIKit
import Firebase

@objc(AddNewServiceViewController)
class AddNewServiceViewController: UIViewController, UITextFieldDelegate {
    
    var ref: FIRDatabaseReference!
    var serviceNameToCreate : String = "" // passed by the addServiceViewController
    @IBOutlet weak var descriptTextView: UITextView!
    @IBOutlet weak var nameTextField: UITextField!
    
    // UIView lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // [START create_database_reference]
        self.ref = FIRDatabase.database().reference()
        // [END create_database_reference]
        nameTextField.text = serviceNameToCreate
    }
    
    
    @IBAction func didTapAdd(_ sender: AnyObject) {
        // [START single_value_read]
        let userID = FIRAuth.auth()?.currentUser?.uid
        ref.child("users").child(userID!).observeSingleEvent(of: .value, with: { (snapshot) in // dans les fonctions anonymes (qui renvoie le snapshot ici), "in" sert à déclarer le début du body (au lieu de {body}
            // Get user value
            let value = snapshot.value as? NSDictionary
            let userName = value?["userName"] as? String ?? "" // ?? permet d'affecter une valeur par défaut si la variable est nil
            let userLocation = value?["location"] as? String ?? ""
            //let user = User.init(userName: userName)
            
            // [START_EXCLUDE]
            // Write new service
            // todo vérifier si le service existe déjà
            self.addNewService(withUserID: userID!, userName: userName, userLocation: userLocation, name: self.nameTextField.text!, descript: self.descriptTextView.text)
            // Finish this Activity, back to the stream
            // [END_EXCLUDE]
        }) { (error) in
            print(error.localizedDescription)
        }
        // [END single_value_read]
    }
    
    func addNewService(withUserID userID: String, userName: String, userLocation: String, name: String, descript: String) {
        // Create new service at /user-services/$userid/$serviceid and at
        // /services/$serviceid simultaneously
        // [START write_fan_out]
        let keyService = ref.child("services").childByAutoId().key
        let service = ["uid": keyService,
                       "author": userName,
                       "name": name,
                       "descript": descript]
        
        let childUpdates = ["/services/\(keyService)": service,
                            "/user-services/\(userID)/user": userName,
                            "/user-services/\(userID)/service/\(keyService)/service": name,
                            "/service-users/\(keyService)/user/\(userID)/user": userName,
                            "/service-users/\(keyService)/user/\(userID)/location": userLocation,
                            "/service-users/\(keyService)/service": name] as [String : Any]
        ref.updateChildValues(childUpdates)
        // [END write_fan_out]
        
         //self.showMessagePrompt("Le service a été créé et ajouté à votre profil")
        
        // go to MyAccount view
           _ = self.navigationController?.popViewController(animated: true)
       // let storyboard = UIStoryboard(name: "Main", bundle: nil)
       // let myAccountViewController = storyboard.instantiateViewController(withIdentifier: "my_account") as! MyAccountViewController
       // self.navigationController?.pushViewController(myAccountViewController, animated: true)
      //  self.navigationController?.show(myAccountViewController as UIViewController, sender: myAccountViewController)

    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
