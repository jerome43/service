//
//  MapViewController.swift
//  SocialServices
//
//  Created by Jérôme LIONS on 24/05/2017.

// ViewController Class used to manage the map's view of the users
//


import UIKit
import MapKit
import CoreLocation
import Firebase

@objc(MapViewController)
class MapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
   
    
     var locationManager: CLLocationManager!
    
    var values = [User]()
    
    // [START define_database_reference]
    var ref: FIRDatabaseReference!
    // [END define_database_reference]
    
    /*
    // try to create a customized pin's view but it doesn't work. See it later !
    func mapView(_ mapView: MKMapView,
                 viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        print("func mapView")
        
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.animatesDrop = true
            pinView!.pinColor = .purple
            let btn = UIButton(type: .detailDisclosure)
            pinView!.rightCalloutAccessoryView = btn
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
 */
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // [START create_database_reference]
        ref = FIRDatabase.database().reference()
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
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // to zoom an pan to the user's location
    @IBAction func zoomIn(_ sender: AnyObject) {
        let userLocation = self.mapView.userLocation
        if (self.mapView.userLocation.location != nil) {
            let region = MKCoordinateRegionMakeWithDistance(
        userLocation.location!.coordinate, 2000, 2000)
        self.mapView.setRegion(region, animated: true)
        }
        
    }
    
    // to change between satellite or map rendering
    @IBAction func changeMapType(_ sender: AnyObject) {
        if mapView.mapType == MKMapType.standard {
            mapView.mapType = MKMapType.satellite
        } else {
            mapView.mapType = MKMapType.standard
        }
    }
    
    // get the user value from DB
    func readData() {
        ref?.child("users").observe(FIRDataEventType.value, with: { (snapshot) in
            self.values = []

            let users  = snapshot.value as? [String : AnyObject] ?? [:]
            
            for (_, userValue) in users {
                //print("new user : \(userValue)")
                
                let uid = userValue["uid"] as! String
                let userName = userValue["userName"] as! String
                let lastName = userValue["lastName"] as! String
                let firstName = userValue["firstName"] as! String
                let userLocation = userValue["location"] as! String
                let phoneNumber = userValue["phoneNumber"] as! String
                let seeds = userValue["seeds"] as! Int
                let user = User.init(uid: uid, userName: userName, lastName: lastName, firstName: firstName, location: userLocation, phoneNumber: phoneNumber, seeds: seeds)
                self.values.append(user)
                //print("new user : \(user)")
                
                addPinToMap(pUser: user) // add the pin on the map
                
            }
        }) { (error) in
            print(error.localizedDescription)
        }
        
        
        // to add a pin on the map that represent a user
        func addPinToMap(pUser : User) {
            let location = pUser.location
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(location!) { [weak self] placemarks, error in
                if let placemark = placemarks?.first, let loc = placemark.location {
                    let dropPin = MKPointAnnotation()
                    dropPin.coordinate = loc.coordinate
                    dropPin.title = pUser.userName
                    dropPin.subtitle = pUser.lastName! + " " + pUser.firstName! + " / " + pUser.phoneNumber!
                    self?.mapView.addAnnotation(dropPin)
                }
            }
        }
    }

}
