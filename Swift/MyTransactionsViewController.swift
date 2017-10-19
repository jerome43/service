//
//  MyTransactionsViewController.swift
//  SocialServices
//
//  Created by Jérôme LIONS on 06/04/2017.
//
//// ViewController Class used to manage the my-transactions tab view
//

import UIKit
import Firebase
//import FirebaseDatabaseUI

@objc(MyTransactionsViewController)
class MyTransactionsViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // [START define_database_reference]
    var ref: FIRDatabaseReference!
    // [END define_database_reference]
    
   
   var values = [Transaction]()
   var transactionsUid = [Int : String]() // pour associer indexpath des cell avec uid des transactions
    var transactionStatusSearch = "pending" // valeur par défaut du statut pout l'affichage
    var pickerData = ["En attente de confirmation", "Confirmées", "Refusée", "Toutes"] // les différentes valeur du Picker view
    
    @IBOutlet var userWith : UILabel! // the user with which the transaction is make
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // [START create_database_reference]
        ref = FIRDatabase.database().reference()
        // [END create_database_reference]

       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print("view will appear")
        super.viewWillAppear(animated)
         readData() // get the values from Firebase
         //   self.tableView.reloadData()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
          print("view will disappear")
        super.viewWillDisappear(animated)
        self.ref.child("user-transactions/\(self.getUid())").removeAllObservers()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    // MARK: - Table View
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return values.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "Cell_Transactions", for: indexPath)
        cell.tag = indexPath.row
        
        let transaction = self.values[indexPath.row]
        print("table view transaction : \(transaction)")
        
        // display differents color according to the status
        switch transaction.accepted {
        case "pending":
            cell.backgroundColor = UIColor.orange
        case "true":
              cell.backgroundColor = UIColor.green
        case "false":
              cell.backgroundColor = UIColor.red
        default:
              cell.backgroundColor = UIColor.orange
        }
        cell.detailTextLabel?.text = transaction.accepted

        
        // get the name of the service concerned by the transaction and display as main text
        self.ref.child("services/\(transaction.service)").observe(FIRDataEventType.value, with: { (snapshot) in
            let postDict = snapshot.value as? [String : AnyObject] ?? [:]
             cell.textLabel?.text = postDict["name"] as? String
        })
        
        // display the user with wich the stransaction is made
        if (transaction.fromUser == self.getUid()) {
            self.ref.child("users/\(transaction.toUser)").observe(FIRDataEventType.value, with: { (snapshot) in
                let postDict = snapshot.value as? [String : AnyObject] ?? [:]
                cell.detailTextLabel?.text = postDict["userName"] as? String
            })
        }
        else {
            self.ref.child("users/\(transaction.fromUser)").observe(FIRDataEventType.value, with: { (snapshot) in
                let postDict = snapshot.value as? [String : AnyObject] ?? [:]
                cell.detailTextLabel?.text = postDict["userName"] as? String
            })
        }
        
        
        self.transactionsUid[Int(indexPath.row)] = transaction.uid
        return cell
    }
    
    // MARK PICKER VIEW
    
    // The number of columns of data
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    // Catpure the picker view selection
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch row {
        case 0:
            self.transactionStatusSearch = "pending"
            self.ref.child("user-transactions/\(self.getUid())").removeAllObservers()
            readData()
        case 1:
            self.transactionStatusSearch = "true"
            self.ref.child("user-transactions/\(self.getUid())").removeAllObservers()
            readData()
        case 2:
            self.transactionStatusSearch = "false"
            self.ref.child("user-transactions/\(self.getUid())").removeAllObservers()
            readData()
        default:
            self.transactionStatusSearch = "all"
            self.ref.child("user-transactions/\(self.getUid())").removeAllObservers()
            readData()
        }
    }
    
    
    // MARK FIREBASE CONNECTIONS
    
    func getUid() -> String {
        return (FIRAuth.auth()?.currentUser?.uid)!
    }
    
 
    func readData() {
        
        //ref?.child("services").observeSingleEvent(of: .value, with: { (snapshot) in // for read one time only
        self.ref.child("user-transactions/\(self.getUid())").observe(FIRDataEventType.value, with: { (snapshot) in
            
            // Get user transactions uid
              print("readData transactions uid \(self.getUid())")
            if (snapshot.value != nil) {
                self.values.removeAll()
                self.transactionsUid.removeAll()
                let transactions  = snapshot.value as? [String : AnyObject] ?? [:]
                   print("transactions : \(transactions)")
                for transactionUid in transactions.values {
                    print("transaction Uid: \(transactionUid)")
                    let tuid : String? = transactionUid["transactionUid"] as? String ?? ""
                    print("transaction Uid: \(tuid ?? "")")
                          self.ref.child("transactions/\(tuid ?? "")").observe(FIRDataEventType.value, with: { (snapshot) in
                            let transaction  = snapshot.value as? [String : AnyObject] ?? [:]
                             print("transaction : \(transaction)")
                            
                            let uid, fromUser, toUser, service, message, accepted, date : String
                            let seeds : Int
                            uid = transaction["uid"] as! String
                            fromUser = transaction["fromUser"] as! String
                            toUser = transaction["toUser"] as! String
                            service = transaction["service"] as! String
                            seeds = transaction["seeds"] as! Int
                            message = transaction["message"] as! String
                            accepted = transaction["accepted"] as! String
                            date = transaction["date"] as! String
                            let newTransaction = Transaction(uid: uid, fromUser: fromUser, toUser: toUser, service : service, seeds: seeds, message : message, accepted : accepted, date : date)
                            if (self.transactionStatusSearch == "all" || self.transactionStatusSearch == accepted) {
                                 // self.values.append(newTransaction)
                                self.values.insert(newTransaction, at : 0) // pour les mettre en premier dans le tableau et inverser l'ordre renvoyer par firebase (plus aniennes au plus récentes), permet d'avoir les derniers échanges en premier dans la liste
                            }
                          
                            print("new transaction\(newTransaction)")
                            self.tableView.reloadData()
                    })
                          { (error) in
                            print(error.localizedDescription)
                    }
                }
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // transfert des données que vers la vue ServiceDetail
        if segue.identifier == "showDetailTransaction" {
            guard let cell: UITableViewCell = sender as? UITableViewCell else { print("nothing1");return }
            print("prepare for segue value :")
             guard let detail: TransactionDetailViewController = segue.destination as? TransactionDetailViewController else {
                print("nothing2)")
                return
            }
            detail.transactionKey = self.transactionsUid[cell.tag]!
        }
    }
  
}
