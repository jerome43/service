//
//  ServiceDetailTableViewController.swift
//  SocialServices
//
//  Created by Jérôme LIONS on 06/04/2017.
//
// ViewController Class used to manage the detail's of a service
//

import UIKit
import Firebase


@objc(ServiceDetailTableViewController)
class ServiceDetailTableViewController: UITableViewController, UISearchBarDelegate, UISearchResultsUpdating {
    
    // [START define_database_reference]
    var ref: FIRDatabaseReference!
    // [END define_database_reference]
    
    var uidService: String?
    var values = [Any]()
    var filteredValues = [Any]()
    let searchController = UISearchController(searchResultsController: nil)
    var usersUid = [Int : String]() // pour associer indexpath des cell avec uid du service
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
           print("service uid : \(uidService ?? "")")
        
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
        var user = [String:String]()
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredValues[indexPath.row] as! [String : String]
        } else {
            user = values[indexPath.row] as! [String : String]
        }
        
        cell.textLabel?.text = user["userName"]
        cell.detailTextLabel?.text = user["userLocation"]
        
        // pour assoicier l'index à l'uid
        let uid = user["userId"]
        let index = Int(indexPath.row)
        print("index : \(index) uid : \(uid!)")
        usersUid[index] = uid
        
        return cell
    }
    
    
    func readData() {
        ref?.child("service-users/\(uidService!)/user").observe(FIRDataEventType.value, with: { (snapshot) in
            var userInfos = [String: String]()
            self.values = []
            self.filteredValues = []
            // Get user value
            var users = [String: NSDictionary]()
            users  = snapshot.value as? NSDictionary as! [String : NSDictionary]
            
            for (userKey, userValue) in users {
               
                let userName = userValue["user"] as! String
                let userLocation = userValue["location"] as! String
                let userUid = userKey
                 print("Read data 2 : user \(userName) : \(userUid) - location \(userLocation)")
                userInfos["userName"] = userName
                userInfos["userId"] = userUid
                userInfos["userLocation"] = userLocation
                self.values.append(userInfos)
                print("new user\(userInfos)")
            
            }
            self.tableView.reloadData()
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
            let userExpression = NSExpression(forKeyPath: "userName")
            let searchStringExpression = NSExpression(forConstantValue: searchString)
            let userSearchComparisonPredicate = NSComparisonPredicate(leftExpression: userExpression, rightExpression: searchStringExpression, modifier: .direct, type: .contains, options: .caseInsensitive)
            searchItemsPredicate.append(userSearchComparisonPredicate)
            
            // Location field matching.
            let locationExpression = NSExpression(forKeyPath: "userLocation")
            let locationSearchComparisonPredicate = NSComparisonPredicate(leftExpression: locationExpression, rightExpression: searchStringExpression, modifier: .direct, type: .contains, options: .caseInsensitive)
            searchItemsPredicate.append(locationSearchComparisonPredicate)
            
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
        
    }
    
    // transition vers la vue DetailService
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // transfert des données que vers la vue ServiceDetail
        if segue.identifier == "showUserRequest" {
            print("prepare for segue value :")
            //   guard let path: IndexPath = sender as? IndexPath else { print("nothing1");return }
            guard let cell: UITableViewCell = sender as? UITableViewCell else { print("nothing1");return }
            guard let userRequest: UserRequestViewController = segue.destination as? UserRequestViewController else {
                print("nothing2)");return
            }
            userRequest.userRequestedId=usersUid[cell.tag]
            userRequest.uidService=uidService;
            //print("prepare for segue value : \(detailService.name ?? "")")
        }
    }
}
