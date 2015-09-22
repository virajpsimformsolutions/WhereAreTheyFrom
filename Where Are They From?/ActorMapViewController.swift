//
//  ActorMapViewController.swift
//  Where Are They From?
//
//  Created by Ryan Whitell on 2015-09-22.
//
//

import UIKit

class ActorMapViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem = self.editButtonItem()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "addMovieStar")

    }
    
    func addMovieStar() {
        let controller = self.storyboard!.instantiateViewControllerWithIdentifier("ActorSearchViewController") as! ActorSearchViewController
        
        self.presentViewController(controller, animated: true, completion: nil)
    }


}
