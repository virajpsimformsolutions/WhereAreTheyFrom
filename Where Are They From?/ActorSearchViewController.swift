//
//  ActorSearchViewController.swift
//  Where Are They From?
//
//  Created by Ryan Whitell on 2015-09-22.
//
//

import UIKit
import CoreData

protocol ActorSearchViewControllerDelegate {
    func actorID(actorPicker: ActorSearchViewController, didPickActor id: NSNumber?)
}

class ActorSearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var tableView : UITableView!
    @IBOutlet weak var searchBar : UISearchBar!
    
    var actors = [Actor]()
    var delegate: ActorSearchViewControllerDelegate?
    
    var searchTask: NSURLSessionDataTask?

    var temporaryContext: NSManagedObjectContext!

    override func viewDidLoad() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancel")
        
        let sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext!

        temporaryContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        temporaryContext.persistentStoreCoordinator = sharedContext.persistentStoreCoordinator
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.searchBar.becomeFirstResponder()
    }

    @IBAction func cancel() {
        self.delegate?.actorID(self, didPickActor: nil)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        if let task = searchTask {
            task.cancel()
        }
        
        if searchText == "" {
            actors = [Actor]()
            tableView?.reloadData()
            objc_sync_exit(self)
            return
        }
        
        let resource = TheMovieDB.Resources.SearchPerson
        let parameters = ["query" : searchText]
        
        searchTask = TheMovieDB.sharedInstance().taskForResource(resource, parameters: parameters) { [unowned self] jsonResult, error in
            
            if let error = error {
                return
            }
            
            if let actorDictionaries = jsonResult.valueForKey("results") as? [[String : AnyObject]] {
                self.searchTask = nil

                self.actors = actorDictionaries.map() {
                    Actor(dictionary: $0, context: self.temporaryContext)
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView!.reloadData()
                }
            }
        }
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let CellReuseId = "ActorSearchCell"
        let actor = actors[indexPath.row]
        
        let cell = tableView.dequeueReusableCellWithIdentifier(CellReuseId) as! UITableViewCell
        
        cell.textLabel!.text = actor.name
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actors.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let actor = actors[indexPath.row]
        
        delegate?.actorID(self, didPickActor: actor.id)
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}




