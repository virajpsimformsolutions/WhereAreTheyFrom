//
//  ActorMapViewController.swift
//  Where Are They From?
//
//  Created by Ryan Whitell on 2015-09-22.
//
//

import UIKit
import CoreData

class ActorMapViewController: UIViewController, ActorSearchViewControllerDelegate {
    
    var task: NSURLSessionDataTask?
    var actors = [Actor?]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
                
                print(dictionary)
                
            }
        }
        
    }
    
    
}
