//
//  TransactionDetailViewController.swift
//  SocialServices
//
//  Created by Jérôme LIONS on 06/04/2017.
//
// ViewController Class used to manage the detail's view of one transaction
//

import UIKit
import Firebase

@objc(TransactionDetailViewController)
class TransactionDetailViewController: UIViewController, UITextFieldDelegate{

    var transactionKey = ""// defined in MyTransactionsDetailViewnController prepare(for segue)
    let transaction: Transaction = Transaction()
    var ref: FIRDatabaseReference = FIRDatabase.database().reference()
    var transactionRef: FIRDatabaseReference!
    var refHandle : FIRDatabaseHandle?

    @IBOutlet var userFromName : UILabel! // the user who make the request
    @IBOutlet var userToName: UILabel! // the user name requested for service displayed in UI
    @IBOutlet var service: UILabel! // the name of the service displayed in UI
    @IBOutlet var message: UITextView! // the message displayed in the UI
    @IBOutlet var seeds: UILabel! // the estimated value of the service in seeds
    @IBOutlet var status : UILabel! // the status displayed in UI
    @IBOutlet var date : UILabel! // the date displayed in UI
    
    let btnAccept = UIButton(type: UIButtonType.custom) as UIButton
    let btnRefuse = UIButton(type: UIButtonType.custom) as UIButton


  override func viewDidLoad() {
    super.viewDidLoad()
    transactionRef = ref.child("transactions").child(transactionKey)
  }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // [START transaction_value_event_listener]
        refHandle = transactionRef.observe(FIRDataEventType.value, with: { (snapshot) in
            let transactionDict = snapshot.value as? [String : AnyObject] ?? [:]
            // [START_EXCLUDE]
            
            self.transaction.setValuesForKeys(transactionDict)
                 self.ref.child("users/\(self.transaction.fromUser)").observe(FIRDataEventType.value, with: { (snapshot) in
                let postDict = snapshot.value as? [String : AnyObject] ?? [:]
                self.userFromName.text = postDict["userName"] as? String
            })
            
            self.ref.child("users/\(self.transaction.toUser)").observe(FIRDataEventType.value, with: { (snapshot) in
                let postDict = snapshot.value as? [String : AnyObject] ?? [:]
                self.userToName.text = postDict["userName"] as? String
            })
            
            self.ref.child("services/\(self.transaction.service)").observe(FIRDataEventType.value, with: { (snapshot) in
                let postDict = snapshot.value as? [String : AnyObject] ?? [:]
                self.service.text  = postDict["name"] as? String
            })
            
            print("transaction.fromUser\(self.transaction.fromUser)")
            self.message.text = self.transaction.message
            self.status.text = self.transaction.accepted
            self.seeds.text = String(self.transaction.seeds)
            self.date.text = self.transaction.date
            switch self.transaction.accepted {
            case "pending" : self.status.text = "en attente"
            case "true" : self.status.text = "confirmée"
            case "false" : self.status.text = "annulée"
            default : self.status.text = "en attente"
            }
            // [END_EXCLUDE]
            self.displayButtonIfPending() // if transaction status if pending
        })
        // [END post_value_event_listener]
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("view will disappear")
        if let refHandle = refHandle {
            transactionRef.removeObserver(withHandle: refHandle)
        }
        if let uid = FIRAuth.auth()?.currentUser?.uid {
            FIRDatabase.database().reference().child("users").child(uid).removeAllObservers()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func getUid() -> String {
        return (FIRAuth.auth()?.currentUser?.uid)!
    }


  @IBAction func didTapSend(_ sender: UIButton) {
   }
    
    // test if transaction status if pending and if the user is requested (and not the requester)
    // if yes, display button for ask to user if he accept or refuse it
    func displayButtonIfPending() {
        
        print("displayButtonIfPending : \(self.transaction.accepted)")
        if (self.transaction.accepted=="pending" && self.transaction.toUser == self.getUid()) {
            print("pending")
            let h = self.view.frame.size.height
            let w = self.view.frame.size.width
        
            self.btnAccept.backgroundColor = UIColor.green
            self.btnAccept.setTitle("Accepter", for: UIControlState.normal)
            self.btnAccept.frame = CGRect(x: w - 350, y: h - 80, width: 80, height: 30)
            self.btnAccept.addTarget(self, action:#selector(clickMeAccept), for:.touchUpInside)
            self.view.addSubview(self.btnAccept)
            
            self.btnRefuse.backgroundColor = UIColor.red
            self.btnRefuse.setTitle("Refuser", for: UIControlState.normal)
            self.btnRefuse.frame = CGRect(x: w - 150, y: h - 80, width: 80, height: 30)
            self.btnRefuse.addTarget(self, action:#selector(clickMeRefuse), for:.touchUpInside)
            self.view.addSubview(self.btnRefuse)
        }
    }
    
    func clickMeAccept(sender:UIButton!) // see displayButtonIfPending
        {
            print("Button Accept Clicked")
            self.ref.updateChildValues(["/transactions/\(self.transaction.uid)/accepted": "true"]) // update the BD
            self.btnAccept.removeFromSuperview() // remove the button
            self.btnRefuse.removeFromSuperview() // remove the button
            
            // update the number of seeds in user profil
            ref.child("users").child(self.transaction.fromUser).observeSingleEvent(of: .value, with: { (snapshot) in
                // Get user value
                let value = snapshot.value as? NSDictionary
                var seeds = value?["seeds"] as? Int ?? 0
                seeds = seeds - self.transaction.seeds // debit the user
                self.ref.updateChildValues(["/users/\(self.transaction.fromUser)/seeds": seeds]) // update the BD
            }) { (error) in
                print(error.localizedDescription)
            }
            
            ref.child("users").child(self.transaction.toUser).observeSingleEvent(of: .value, with: { (snapshot) in
                // Get user value
                let value = snapshot.value as? NSDictionary
                var seeds = value?["seeds"] as? Int ?? 0
                seeds = seeds + self.transaction.seeds // credit the user
                self.ref.updateChildValues(["/users/\(self.transaction.toUser)/seeds": seeds]) // update the BD
            }) { (error) in
                print(error.localizedDescription)
            }
            
            // alert the user the transaction was updated
            let alertController = UIAlertController(title: NSLocalizedString("Information",comment:""), message: NSLocalizedString("Votre validation de l'échange a été enregistrée !",comment:""), preferredStyle: .alert)
            let defaultAction = UIAlertAction(title:     NSLocalizedString("Ok", comment: ""), style: .default, handler: { (pAlert) in
                self.navigationController?.popViewController(animated: true)
            })
            alertController.addAction(defaultAction)
            self.present(alertController, animated: true, completion: nil)
            
        }
    
    func clickMeRefuse(sender:UIButton!) // see displayButtonIfPending
        {
            print("Button Refuse Clicked")
            self.ref.updateChildValues(["/transactions/\(self.transaction.uid)/accepted": "false"]) // update the BD
            self.btnRefuse.removeFromSuperview() // remove the button
            self.btnAccept.removeFromSuperview() // remove the button
            
            // alert the user the transaction was updated
            let alertController = UIAlertController(title: NSLocalizedString("Information",comment:""), message: NSLocalizedString("Votre refus de l'échange a été enregistrée !",comment:""), preferredStyle: .alert)
            let defaultAction = UIAlertAction(title:     NSLocalizedString("Ok", comment: ""), style: .default, handler: { (pAlert) in
                self.navigationController?.popViewController(animated: true)
            })
            alertController.addAction(defaultAction)
            self.present(alertController, animated: true, completion: nil)
        }
}
