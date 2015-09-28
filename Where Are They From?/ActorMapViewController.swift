//
//  ActorMapViewController.swift
//  Where Are They From?
//
//  Created by Ryan Whitell on 2015-09-22.
//
//

import UIKit
import CoreData
import MapKit
import Foundation
import SystemConfiguration

class ActorMapViewController: UIViewController, ActorSearchViewControllerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var task: NSURLSessionDataTask?
    var actors = [Actor]()
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    /*------- Setup -------*/
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.stopAnimating()
        
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "searchActors")
        self.navigationItem.title = "Where Are They From?"
        
        actors = fetchAllActors()
        appendActors()
        restoreMapRegion(false)
    }
    
    /*------- Main Functionality -------*/
    func postAndPersistActor(dictionary: [String : AnyObject?]) {
        
        let newActor = Actor(dictionary: dictionary, context: sharedContext)
        self.actors.append(newActor)
        CoreDataStackManager.sharedInstance().saveContext()
        
        let coordinates = CLLocationCoordinate2DMake(newActor.latitude as! Double, newActor.longitude as! Double)
        
        let span = MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
        let region = MKCoordinateRegion(center: coordinates, span: span)
        mapView.setRegion(region, animated: true)
        
        var annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        annotation.title = newActor.name
        annotation.subtitle = newActor.birthplace
        
        mapView.addAnnotation(annotation)
        activityIndicator.stopAnimating()
    }
    
    /*------- ActorSearchViewControllerDelegate Function -------*/
    func actorID(actorPicker: ActorSearchViewController, didPickActor id: NSNumber?) {
        
        activityIndicator.startAnimating()
        
        let resource = TheMovieDB.Resources.Person
        let parameters = ["id" : id!]
        
        // Search for actor by ID number to obtain data
        task = TheMovieDB.sharedInstance().taskForResource(resource, parameters: parameters) { [unowned self] jsonResult, error in
            
            var coordinate = CLLocationCoordinate2D()
            
            if let error = error {
                dispatch_async(dispatch_get_main_queue()) {
                    self.alert("Error locating actor in database:\n \(error.localizedDescription)")
                }
                return
            } else {
                if self.isConnectedToNetwork() {
                    
                    let geoLocation = CLGeocoder()
                    
                    if var birthplace = jsonResult["place_of_birth"] as? String {
                        
                        if birthplace.rangeOfString(" - ") != nil {
                            birthplace = birthplace.stringByReplacingOccurrencesOfString(" - ", withString: ", ")
                        }
                        
                    geoLocation.geocodeAddressString(birthplace) { placeMark, error in
                        if error != nil {
                            dispatch_async(dispatch_get_main_queue()) {
                                self.activityIndicator.stopAnimating()
                                self.alert("Trouble locating hometown :s")
                            }
                            return
                        } else {
                            let location = placeMark[0] as! CLPlacemark
                            coordinate = location.location.coordinate
                            
                            // In case the actor has the same hometown as a previosuly picked actor - add small offset
                            for location in self.actors {
                                if (location.latitude == coordinate.latitude as Double) && (location.longitude == coordinate.longitude as Double) {
                                    coordinate.longitude = coordinate.longitude + 0.015
                                }
                            }
                            
                            dispatch_async(dispatch_get_main_queue()) {
                                
                                let dictionary: [String : AnyObject?] = [
                                    Actor.Keys.Bio : jsonResult["biography"],
                                    Actor.Keys.BirthPlace : jsonResult["place_of_birth"],
                                    Actor.Keys.ID : jsonResult["id"],
                                    Actor.Keys.ImageURL : jsonResult["profile_path"],
                                    Actor.Keys.Name : jsonResult["name"],
                                    Actor.Keys.Website : jsonResult["homepage"],
                                    Actor.Keys.Latitude : coordinate.latitude,
                                    Actor.Keys.Longitude : coordinate.longitude
                                ]
                                
                                self.postAndPersistActor(dictionary)
                            }
                        }
                    }
                    } else {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.alert("Trouble locating hometown :s")
                        }
                    }
                
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.alert("Not connected to the network!")
                    }
                }
                
            }
        }
        
    }
    
    /*------- MKMapViewDelegate Functionality -------*/
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinColor = .Green
            pinView!.pinColor = .Red
            pinView!.canShowCallout = true
            pinView!.rightCalloutAccessoryView = UIButton.buttonWithType(.DetailDisclosure) as! UIButton
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        if (self.editing) {
            
            let lat = view.annotation.coordinate.latitude as Double
            let long = view.annotation.coordinate.longitude as Double
            
            var actorToDelete: Actor?
            var index = 0
            var count = 0
            
            for actor in actors {
                if actor.latitude == lat && actor.longitude == long {
                    actorToDelete = actor
                    index = count
                }
                count++
            }
            
            actors.removeAtIndex(index)
            sharedContext.deleteObject(actorToDelete!)
            CoreDataStackManager.sharedInstance().saveContext()
            
            self.mapView.removeAnnotation(view.annotation)
        }
    }
    
    func mapView(mapView: MKMapView!, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if control == annotationView.rightCalloutAccessoryView {
            
            let controller = storyboard!.instantiateViewControllerWithIdentifier("ActorDetailViewController") as! ActorDetailViewController
            
            let lat = annotationView.annotation.coordinate.latitude as Double
            let long = annotationView.annotation.coordinate.longitude as Double
            
            for actor in actors {
                if actor.latitude == lat && actor.longitude == long {
                    controller.actor = actor
                    self.navigationController!.pushViewController(controller, animated: true)
                }
            }
        }
    }
    
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
    /*------- Error Handeling -------*/
    func alert(message: String) {
        let alertController = UIAlertController(title: "There was an error in handling your request:", message: message, preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "OK", style: .Cancel) { (action) in }
        alertController.addAction(cancelAction)
        self.activityIndicator.stopAnimating()
        presentViewController(alertController, animated: true){}
    }

    func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0)).takeRetainedValue()
        }
        
        var flags: SCNetworkReachabilityFlags = 0
        if SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) == 0 {
            return false
        }
        
        let isReachable = (flags & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        
        return isReachable && !needsConnection
    }
    
    /*------- NSKeyedArchiver Persistent Map Region Functionality -------*/
    func restoreMapRegion(animated: Bool) {
        
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            
            mapView.setRegion(savedRegion, animated: animated)
        }
    }
    
    func saveMapRegion() {
        
        let dictionary = [
            "latitude" : mapView.region.center.latitude,
            "longitude" : mapView.region.center.longitude,
            "latitudeDelta" : mapView.region.span.latitudeDelta,
            "longitudeDelta" : mapView.region.span.longitudeDelta
        ]
        
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }
    
    /*------- Helper Functions -------*/
    func fetchAllActors() -> [Actor] {
        
        let error: NSErrorPointer = nil
        let fetchRequest = NSFetchRequest(entityName: "Actor")
        let results = sharedContext.executeFetchRequest(fetchRequest, error: error)
        
        if error != nil {
            println("Error in fectchAllActors(): \(error)")
        }
        
        return results as! [Actor]
    }
    
    func appendActors() {
        
        for actor in actors {
            let coordinates = CLLocationCoordinate2DMake(actor.latitude as! Double, actor.longitude as! Double)
            var annotation = MKPointAnnotation()
            annotation.coordinate = coordinates
            annotation.title = actor.name
            annotation.subtitle = actor.birthplace
            mapView.addAnnotation(annotation)
        }
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(!self.editing, animated: true)
        if (self.editing){
            let alertController = UIAlertController(title: "Tap on a pin to delete it", message: "", preferredStyle: .Alert)
            let cancelAction = UIAlertAction(title: "OK", style: .Cancel) { (action) in }
            alertController.addAction(cancelAction)
            presentViewController(alertController, animated: true){}
        }
    }
    
    func searchActors() {
        let controller = self.storyboard!.instantiateViewControllerWithIdentifier("ActorSearchViewController") as! ActorSearchViewController
        
        controller.delegate = self
        
        self.presentViewController(controller, animated: true, completion: nil)
    }
}
