//
//  AddServiceController.swift
//  SocialServices
//
//  Created by Jérôme LIONS on 05/04/2017.
// ViewController Class used to manage the add-service view
//

import UIKit
import Firebase

@objc(AddServiceViewController)
//class AddServiceViewController: UITableViewController, UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating  {
class AddServiceViewController: UITableViewController, UISearchBarDelegate, UISearchResultsUpdating  {
    
       let btnCreateService = UIButton(type: UIButtonType.custom) as UIButton
    
    
    // [START define_database_reference]
    var ref: FIRDatabaseReference!
    // [END define_database_reference]
    
  
    var values = [Service]()
    var filteredValues = [Service]()
    let searchController = UISearchController(searchResultsController: nil)
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // [START create_database_reference]
        ref = FIRDatabase.database().reference()
        // [END create_database_reference]
        
        readData() // get the values from Firebase
        
        // Use the current view controller to update the search results.
        self.searchController.searchResultsUpdater = self
        
        // Install the search bar as the table header.
        self.tableView.tableHeaderView = self.searchController.searchBar;
        
        // It is usually good to set the presentation context.
        self.searchController.searchBar.delegate = self
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.hidesNavigationBarDuringPresentation = false
        self.definesPresentationContext = true
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = "Recherche de services"
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
     //   print("view will disappear")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table View
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredValues.count
        }
        return values.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.tag = indexPath.row
        
        let service: Service
        if searchController.isActive && searchController.searchBar.text != "" {
            service = filteredValues[indexPath.row]
        } else {
            service = values[indexPath.row]
        }
        
        cell.textLabel?.text = service.name
        cell.detailTextLabel?.text = service.descript
        
        return cell
    }
    
    // listen for select cell
    override  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("didSelectRowAt")
        let service: Service
        if searchController.isActive && searchController.searchBar.text != "" {
            service = filteredValues[indexPath.row]
        } else {
            service = values[indexPath.row]
        }
        
        let userID = self.getUid()
        
        // Get user name and location values
        self.ref.child("users").child(userID).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            let userName = value?["userName"] as? String ?? ""
            let userLocation = value?["location"] as? String ?? ""
            
            
            // ask the user if he wants to save the skill in him profile
            let refreshAlert = UIAlertController(title: service.name, message: "Voulez-vous ajouter ce service à vos compétences ?", preferredStyle: UIAlertControllerStyle.alert)
            
            refreshAlert.addAction(UIAlertAction(title: "Oui", style: .default, handler: { (action: UIAlertAction!) in
                print("oui")
                // update DB new services of the user
                let childUpdates = ["/user-services/\(userID)/user": userName,
                            "/user-services/\(userID)/service/\(service.uid)/service": service.name,
                            "/service-users/\(service.uid)/user/\(userID)/user": userName,
                            "/service-users/\(service.uid)/user/\(userID)/location": userLocation,
                            "/service-users/\(service.uid)/service": service.name] as [String : Any]
                self.ref.updateChildValues(childUpdates)
                self.showMessagePrompt("Le service a été ajouté.")
                
            }))
            
            refreshAlert.addAction(UIAlertAction(title: "Non", style: .cancel, handler: { (action: UIAlertAction!) in
                print("non")
            }))
            
            self.present(refreshAlert, animated: true, completion: nil)
            
        })
    
    }
    
    func getUid() -> String {
        return (FIRAuth.auth()?.currentUser?.uid)!
    }
    
    func getQuery() -> FIRDatabaseQuery {
        let allServices = (ref?.child("services").queryLimited(toFirst: 100))!
        return allServices
    }
    
    // get the services from DB
    func readData() {
        ref?.child("services").observe(FIRDataEventType.value, with: { (snapshot) in
            self.values = [Service]()
            self.filteredValues = [Service]()
            if (snapshot.value != nil) {
                let services  = snapshot.value as? [String : AnyObject] ?? [:]
                
                for service in services.values {
                    print("service\(service)")
                    let name, uid, author, descript : String
                    name = service["name"] as! String
                    uid = service["uid"] as! String
                    author = service["author"] as! String
                    descript = service["descript"] as! String
                    let newService = Service(author: author, uid: uid, name: name, descript: descript)
                    self.values.append(newService)
                    print("new service\(newService)")
                }
                self.tableView.reloadData()
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    

    // MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        
        // Update the filtered array based on the search text.
        
        let searchResults = self.values
        print("search Result : \(searchResults)")
        
        // Strip out all the leading and trailing spaces.
        let whitespaceCharacterSet = CharacterSet.whitespaces
        let strippedString = searchController.searchBar.text!.trimmingCharacters(in: whitespaceCharacterSet)
        let searchItems = strippedString.components(separatedBy: " ") as [String]
        
        // Build all the "AND" expressions for each value in the searchString.
        let andMatchPredicates: [NSPredicate] = searchItems.map { searchString in
            
            var searchItemsPredicate = [NSPredicate]()
            
            // Below we use NSExpression represent expressions in our predicates.
            // NSPredicate is made up of smaller, atomic parts: two NSExpressions (a left-hand value and a right-hand value).
            
            // Name field matching.
            let titleExpression = NSExpression(forKeyPath: "name")
            let searchStringExpression = NSExpression(forConstantValue: searchString)
            let titleSearchComparisonPredicate = NSComparisonPredicate(leftExpression: titleExpression, rightExpression: searchStringExpression, modifier: .direct, type: .contains, options: .caseInsensitive)
            searchItemsPredicate.append(titleSearchComparisonPredicate)
            
            
            // Descript field matching.
            let descriptExpression = NSExpression(forKeyPath: "descript")
            let descriptSearchComparisonPredicate = NSComparisonPredicate(leftExpression: descriptExpression, rightExpression: searchStringExpression, modifier: .direct, type: .contains, options: .caseInsensitive)
            searchItemsPredicate.append(descriptSearchComparisonPredicate)
            
            // Add this OR predicate to our master AND predicate.
            let orMatchPredicate = NSCompoundPredicate(orPredicateWithSubpredicates:searchItemsPredicate)
            
            return orMatchPredicate
        }
        
        // Match up the fields of the Product object.
        
        let finalCompoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: andMatchPredicates)
        
        let filteredResults = searchResults.filter { finalCompoundPredicate.evaluate(with: $0) }
        print("filtered Result : \(filteredResults)")
        self.filteredValues = filteredResults
        self.tableView.reloadData()
        
        // if the name of the service searched is 3 letters min and not in the list, ask for create it
        if (searchController.searchBar.text != ""  && (searchController.searchBar.text?.characters.count)! >= 3 && filteredResults == []) {
          //  askForCreateService()
            displayCreateServiceButton()
        }
        else {
            hideCreateServiceButton()
        }
    }
    
    func displayCreateServiceButton() {
        print("displayCreateServiceButton")

            self.btnCreateService.backgroundColor = UIColor.orange
            self.btnCreateService.setTitle("Créer service", for: UIControlState.normal)
            self.btnCreateService.frame = CGRect(x: 0, y: 556, width: 375, height: 47)
            self.btnCreateService.addTarget(self, action:#selector(askForCreateService), for:.touchUpInside)
            self.view.addSubview(self.btnCreateService)
        
    }
    
    func hideCreateServiceButton() {
        self.btnCreateService.removeFromSuperview()
    }
    
    // if the service doesn't exists, ask for create it
    func askForCreateService() {
        print("askForCreateService")
        // ask the user if he wants to save the skill in him profile
        let refreshAlert = UIAlertController(title: searchController.searchBar.text, message: "Ce service n'existe pas, voulez-vous le créer et l'ajouter à vos compétences ?", preferredStyle: UIAlertControllerStyle.alert)
        
        let serviceNameToCreate = self.searchController.searchBar.text
        
        self.searchController.searchBar.text = "" // reset the searchedBar text
        
        refreshAlert.addAction(UIAlertAction(title: "Oui", style: .default, handler: { (action: UIAlertAction!) in
            print("oui")
            // go to AddNewService view
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let addNewServiceViewController = storyboard.instantiateViewController(withIdentifier: "add_new_service") as! AddNewServiceViewController
            addNewServiceViewController.serviceNameToCreate = serviceNameToCreate! // pass the name of the new service to create
            self.navigationController?.pushViewController(addNewServiceViewController, animated: true)
            
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Non", style: .cancel, handler: { (action: UIAlertAction!) in
            print("non")
        }))
        
        self.present(refreshAlert, animated: true, completion: nil)
    }
}
