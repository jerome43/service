//
//  ServiceListViewController.swift
//  SocialServices
//
//  Created by Jérôme LIONS on 06/04/2017.
//
//// ViewController Class used to manage the search service list view

import UIKit
import Firebase
//import FirebaseDatabaseUI

@objc(ServiceListViewController)
//class ServiceListViewController: UIViewController, UITableViewDelegate, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
class ServiceListViewController: UITableViewController, UISearchBarDelegate, UISearchResultsUpdating {

    // [START define_database_reference]
    var ref: FIRDatabaseReference!
    // [END define_database_reference]
    
    //var dataSource: FirebaseTableViewDataSource?
    var values = [Service]()
    var filteredValues = [Service]()
    let searchController = UISearchController(searchResultsController: nil)
    var servicesUid = [Int : String]() // pour associer indexpath des cell avec uid du service
    
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
       // self.tableView.register(UINib(nibName: "ServiceTableViewCell", bundle: nil), forCellReuseIdentifier: "service")
        //let cell = self.tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ServiceTableViewCell
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.tag = indexPath.row
       
        let service: Service
        if searchController.isActive && searchController.searchBar.text != "" {
            service = filteredValues[indexPath.row]
        } else {
            service = values[indexPath.row]
        }
        
       // cell.serviceName.text = service.name
       // cell.serviceDescript.text = service.descript
        
        cell.textLabel?.text = service.name
        cell.detailTextLabel?.text = service.descript
        
        // pour assoicier l'index à l'uid
        let uid = String(service.uid) ?? ""
        let index = Int(indexPath.row)
        print("index : \(index) uid : \(uid)")
        servicesUid[index] = uid
   
        return cell
    }
    
    func getUid() -> String {
        return (FIRAuth.auth()?.currentUser?.uid)!
    }
    /*
    func getQuery() -> FIRDatabaseQuery {
        let allServices = (ref?.child("services").queryLimited(toFirst: 100))!
        return allServices
    }
 */
    
    func readData() {
         //ref?.child("services").observeSingleEvent(of: .value, with: { (snapshot) in // for read one time only
        ref?.child("services").observe(FIRDataEventType.value, with: { (snapshot) in
            
    // Get user value
            self.values = [Service]()
            self.filteredValues = [Service]()
           // var services = [String: NSDictionary]()
            if (snapshot.value != nil) {
                // services  = snapshot.value as? NSDictionary as! [String : NSDictionary]
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
            
            /*
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .none
            numberFormatter.formatterBehavior = .default
            let targetNumber = numberFormatter.number(from: searchString)
            
            // `searchString` may fail to convert to a number.
            if targetNumber != nil {
                // Use `targetNumberExpression` in both the following predicates.
                let targetNumberExpression = NSExpression(forConstantValue: targetNumber!)
                let yearIntroducedExpression = NSExpression(forKeyPath: "descript")
                let yearIntroducedPredicate = NSComparisonPredicate(leftExpression: yearIntroducedExpression, rightExpression: targetNumberExpression, modifier: .direct, type: .equalTo, options: .caseInsensitive)
                searchItemsPredicate.append(yearIntroducedPredicate)
                
            }
            */
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
        if segue.identifier == "showDetailService" {
         print("prepare for segue value :")
     //   guard let path: IndexPath = sender as? IndexPath else { print("nothing1");return }
         guard let cell: UITableViewCell = sender as? UITableViewCell else { print("nothing1");return }
            guard let detailService: ServiceDetailTableViewController = segue.destination as? ServiceDetailTableViewController else {
                print("nothing2)");return
            }
            //detailService.name = cell.textLabel?.text
         //   let index = cell.tag
            detailService.uidService = servicesUid[cell.tag]
            print("prepare for segue value : \(detailService.uidService!)")
        }
    }
    
}
 
