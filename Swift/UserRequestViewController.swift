//
//  UserRequestViewController.swift
//  SocialServices
//
//  Created by Jérôme LIONS on 06/04/2017.
//
// ViewController Class used to manage a new transaction request's view
//

import UIKit
import Firebase
import MessageUI

@objc(UserRequestViewController)
class UserRequestViewController: UIViewController, UITextViewDelegate, MFMailComposeViewControllerDelegate {
    
    // [START define_database_reference]
    var ref: FIRDatabaseReference!
    // [END define_database_reference]
    
    let userId = FIRAuth.auth()?.currentUser?.uid // the user who make the request
    var userName : String? // the user who make the request
    
    var userRequestedId: String? // the user requested Id for service, defined in ServiceDetailViewnController prepare(for segue)
    var userRequestedName : String? // the user requested for service,
    @IBOutlet var userRequestedUILabel: UILabel! // the user name requested for service displayed in UI
    
    var uidService : String? // the service requested id, defined in ServiceDetailViewnController prepare(for segue)
   // var service : Service? // the service requested
    @IBOutlet var serviceUILabel: UILabel! // the name of the service displayed in UI
    @IBOutlet var message: UITextView! // the message to send
    @IBOutlet var seeds: UITextField! // the estimated value of the service in seeds
    
    private let placeholder = "Décrivez le plus précisément possible votre besoin et indiquez les dates ou jours qui conviendraient pour leur réalisation."
    
    @IBAction func didTapSend(_ sender: AnyObject) {
        
        // test if the user request a service to himself
        // if not, ok, let's save the transact
        if (self.userId != self.userRequestedId) {
            // verify message and seeds are setted
            if (self.seeds.text != nil && self.seeds.text != "" &&  self.message.text != nil && self.message.text != nil) {
                 let currentDateTime = Date()
                let transaction = Transaction.init(uid: "", fromUser: self.userId!, toUser: self.userRequestedId!, service : self.uidService!, seeds: Int(self.seeds.text!)!, message :  self.message.text, accepted : "pending", date : String(describing: currentDateTime))
        addNewTransaction(transaction: transaction) // save in DB
        sendEmail() // sending Email notification to userRequested
                
            }
            else {
                let alertController = UIAlertController(title: NSLocalizedString("Oups",comment:""), message: NSLocalizedString("veuillez bien renseigner votre message et / ou la valeur en graine !",comment:""), preferredStyle: .alert)
                let defaultAction = UIAlertAction(title:     NSLocalizedString("Ok", comment: ""), style: .default, handler: { (pAlert) in
                    //Do whatever you wants here
                })
                alertController.addAction(defaultAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
        // if true, a alert is displayed and the transact is not saved
        else {
            let alertController = UIAlertController(title: NSLocalizedString("Oups",comment:""), message: NSLocalizedString("vous ne pouvez pas demander un service à vous même !",comment:""), preferredStyle: .alert)
            let defaultAction = UIAlertAction(title:     NSLocalizedString("Ok", comment: ""), style: .default, handler: { (pAlert) in
                //Do whatever you wants here
            })
            alertController.addAction(defaultAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
       // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("user requested uid : \(userRequestedId ?? "")")
        print("uidService : \(uidService ?? "")")
        
        // [START create_database_reference]
        ref = FIRDatabase.database().reference()
        // [END create_database_reference]
        readData() // get the values from Firebase
        self.message.delegate = self
         self.message.text = self.placeholder
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("view will disappear")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    func readData() {
      
        ref?.child("services/\(self.uidService!)").observe(FIRDataEventType.value, with: { (snapshot) in
            let service = snapshot.value as? NSDictionary
            self.serviceUILabel.text = service?["name"] as? String ?? ""// mise à jour label
        }) { (error) in
            print(error.localizedDescription)
        }
        
        ref?.child("users/\(self.userRequestedId!)").observe(FIRDataEventType.value, with: { (snapshot) in
            let user = snapshot.value as? NSDictionary
            let userName = user?["userName"] as? String ?? ""
            self.userRequestedUILabel.text = userName // mise à jour label
            self.userRequestedName? = userName
            
        }) { (error) in
            print(error.localizedDescription)
        }
       }
    
    
    func addNewTransaction(transaction : Transaction) {
        // Create new service at /user-services/$userid/$serviceid and at
        // /services/$serviceid simultaneously
        // [START write_fan_out]
        let keyTransaction = ref.child("transactions").childByAutoId().key
        transaction.uid=keyTransaction
        let childUpdates = ["/transactions/\(keyTransaction)/fromUser": transaction.fromUser,
                            "/transactions/\(keyTransaction)/toUser": transaction.toUser,
                            "/transactions/\(keyTransaction)/service": transaction.service,
                            "/transactions/\(keyTransaction)/seeds": transaction.seeds,
                            "/transactions/\(keyTransaction)/message": transaction.message,
                            "/transactions/\(keyTransaction)/accepted": transaction.accepted,
                            "/transactions/\(keyTransaction)/date": transaction.date,
                            "/transactions/\(keyTransaction)/uid": transaction.uid,
                            "/user-transactions/\(transaction.toUser)/\(keyTransaction)/transactionUid" : keyTransaction,
                            "/user-transactions/\(transaction.fromUser)/\(keyTransaction)/transactionUid" : keyTransaction] as [String : Any]

        ref.updateChildValues(childUpdates)
        // [END write_fan_out]
        
        let alertController = UIAlertController(title: NSLocalizedString("Information",comment:""), message: NSLocalizedString("L'échange a été proposé !",comment:""), preferredStyle: .alert)
        let defaultAction = UIAlertAction(title:     NSLocalizedString("Ok", comment: ""), style: .default, handler: { (pAlert) in
            // return to search view
           // let storyboard = UIStoryboard(name: "Main", bundle: nil)
          //  let viewController = storyboard.instantiateViewController(withIdentifier: "tab_bar_control") as! TabBarController
            //  self.navigationController?.pushViewController(viewController, animated: true)
          //  self.navigationController?.popToViewController(viewController, animated: true)
            
            // self.navigationController?.popViewController(animated: true)
            self.performSegue(withIdentifier: "showExchanges", sender: nil)
           
           /*
            for vc in (self.navigationController?.viewControllers ?? []) {
                if vc is ServiceListViewController {
                    _ = self.navigationController?.popToViewController(vc, animated: true)
                    break
                }
            }
            */
            
        })
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func sendEmail() {
        if !MFMailComposeViewController.canSendMail() {
            print("Mail services are not available")
            return
        }
        
        let composeVC = MFMailComposeViewController()
        composeVC.mailComposeDelegate = self
        
        // Configure the fields of the interface.
        composeVC.setToRecipients(["jerome.lions@ovh.fr"])
        composeVC.setSubject("Demande d'aide")
        composeVC.setMessageBody("Vous avez une demande de service, rendez-vous sur votre compte", isHTML: false)
        
        // Present the view controller modally.
        self.present(composeVC, animated: true, completion: nil)

        
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult, error: Error?) {
            
            // Dismiss the mail compose view controller.
            controller.dismiss(animated: true, completion: nil)
        }
    


    
    // to manage a placeholder in textView, overide method from UiTextViewDelegate
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        self.message.textColor = UIColor.black
        if(self.message.text == self.placeholder) {
            self.message.text = ""
        }
        
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if(self.message.text == "") {
            self.message.text = self.placeholder
            self.message.textColor = UIColor.blue
        }
    }

}
