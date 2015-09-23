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
    func actorPicker(actorPicker: ActorSearchViewController, didPickActor actor: Actor?)
}

class ActorSearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var tableView : UITableView!
    @IBOutlet weak var searchBar : UISearchBar!
    
    // The data for the table
    var actors = [Actor]()
    
    // The delegate will typically be a view controller, waiting for the Actor Picker
    // to return an actor
    var delegate: ActorSearchViewControllerDelegate?
    
    // The most recent data download task. We keep a reference to it so that it can
    // be canceled every time the search text changes
    var searchTask: NSURLSessionDataTask?
    
    // Temporary Context?
    //
    // This view controller may temporarily download quite a few actors while the user
    // is typing in text.
    //
    // If the user types "ll" for example, that would find "LL Cool J", "Bill Murray", and
    // many others. We don't want to add all of those actors to the main context. So we will
    // put them in this temporary context instead.
    var temporaryContext: NSManagedObjectContext!
    
    // MARK: - life Cycle
    override func viewDidLoad() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancel")
        
        let sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext!
        
        // Set the temporary context
        temporaryContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType)
        temporaryContext.persistentStoreCoordinator = sharedContext.persistentStoreCoordinator
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.searchBar.becomeFirstResponder()
    }
    
    
    // MARK: - Actions
    
    @IBAction func cancel() {
        self.delegate?.actorPicker(self, didPickActor: nil)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // MARK: - Search Bar Delegate
    
    // Each time the search text changes we want to cancel any current download and start a new one
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        // Cancel the last task
        if let task = searchTask {
            task.cancel()
        }
        
        // If the text is empty we are done
        if searchText == "" {
            actors = [Actor]()
            tableView?.reloadData()
            objc_sync_exit(self)
            return
        }
        
        // Start a new one download
        let resource = TheMovieDB.Resources.SearchPerson
        let parameters = ["query" : searchText]
        
        searchTask = TheMovieDB.sharedInstance().taskForResource(resource, parameters: parameters) { [unowned self] jsonResult, error in
            
            // Handle the error case
            if let error = error {
                println("Error searching for actors: \(error.localizedDescription)")
                return
            }
            
            // Get a Swift dictionary from the JSON data
            if let actorDictionaries = jsonResult.valueForKey("results") as? [[String : AnyObject]] {
                self.searchTask = nil
                
                // Create an array of Person instances from the JSON dictionaries
                self.actors = actorDictionaries.map() {
                    Actor(dictionary: $0, context: self.temporaryContext)
                }
                
                // Reload the table on the main thread
                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView!.reloadData()
                }
            }
        }
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // MARK: - Table View Delegate and Data Source
    
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
        println("TV")
        
        let actor = actors[indexPath.row]
        
        println(actor)
        
        // Alert the delegate
        delegate?.actorPicker(self, didPickActor: actor)
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}