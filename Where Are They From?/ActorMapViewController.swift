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
    
    var task: NSURLSessionDataTask?
    var actors = [Actor?]()
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.stopAnimating()
     //   activityIndicator.hidden = true
        
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "searchActors")
        
        actors = fetchAllActors()
    }
    
    func fetchAllActors() -> [Actor] {
        
        let error: NSErrorPointer = nil
        let fetchRequest = NSFetchRequest(entityName: "Actor")
        let results = sharedContext.executeFetchRequest(fetchRequest, error: error)
        
        if error != nil {
            println("Error in fectchAllActors(): \(error)")
        }
        
        return results as! [Actor]
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    func searchActors() {
        let controller = self.storyboard!.instantiateViewControllerWithIdentifier("ActorSearchViewController") as! ActorSearchViewController
        
        controller.delegate = self
        
        self.presentViewController(controller, animated: true, completion: nil)
    }
    
    func actorID(actorPicker: ActorSearchViewController, didPickActor id: NSNumber?) {
        
        activityIndicator.startAnimating()
        
        let resource = TheMovieDB.Resources.Person
        let parameters = ["id" : id!]
        
        task = TheMovieDB.sharedInstance().taskForResource(resource, parameters: parameters) { [unowned self] jsonResult, error in
            
            if let error = error {
                println("Error searching for actors: \(error.localizedDescription)")
                return
            } else {
                
                let dictionary: [String : AnyObject?] = [
                    Actor.Keys.Bio : jsonResult["biography"],
                    Actor.Keys.BirthPlace : jsonResult["place_of_birth"],
                    Actor.Keys.ID : jsonResult["id"],
                    Actor.Keys.ImageURL : jsonResult["profile_path"],
                    Actor.Keys.Name : jsonResult["name"],
                    Actor.Keys.Website : jsonResult["homepage"]]
                
                self.postAndPersistActor(dictionary)
                
            }
        }
        
    }
    
    func postAndPersistActor(dictionary: [String : AnyObject?]) {
        let geoLocation = CLGeocoder()
        var coordinate = CLLocationCoordinate2D()
        
        if isConnectedToNetwork(){
            geoLocation.geocodeAddressString(dictionary["place_of_birth"] as! String) { placeMark, error in
                if error != nil {
                    self.activityIndicator.stopAnimating()
                    self.alert("Trouble locating hometown.")
                    return
                } else {
                    let location = placeMark[0] as! CLPlacemark
                    coordinate = location.location.coordinate
                    self.goToRegion(coordinate)
                }
            }} else { alert("Not connected to network!") }
    }
    
    func goToRegion(center: CLLocationCoordinate2D) {

        let span = MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: true)
        
        let skeletonPin = MKPointAnnotation()
        skeletonPin.coordinate = center
        
        mapView.addAnnotation(skeletonPin)
        activityIndicator.stopAnimating()
        
    }
    
    /*------- MKMapViewDelegate Functionality -------*/
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinColor = .Red
            pinView!.animatesDrop = true
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    /*------- 2 -------*/
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView) {
//        let controller = storyboard!.instantiateViewControllerWithIdentifier("CollectionViewController") as! CollectionViewController
//        
//        let lat = view.annotation.coordinate.latitude as Double
//        let long = view.annotation.coordinate.longitude as Double
//        
//        for pin in pins {
//            if pin.latitude == lat && pin.longitude == long {
//                controller.pin  = pin
//                self.navigationController!.pushViewController(controller, animated: true)
//            }
//        }
    }
    
    /*------- 3 -------*/
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
//        saveMapRegion()
    }
    
    func alert(message: String) {
        let alertController = UIAlertController(title: "There was an error in handling your request:", message: message, preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "OK", style: .Cancel) { (action) in }
        alertController.addAction(cancelAction)
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

    
}
