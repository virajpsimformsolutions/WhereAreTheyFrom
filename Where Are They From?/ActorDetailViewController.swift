//
//  ActorDetailViewController.swift
//  Where Are They From?
//
//  Created by Ryan Whitell on 2015-09-24.
//
//

import UIKit

class ActorDetailViewController: UIViewController {
    
    var actor: Actor?
    
    @IBOutlet weak var bio: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        bio.adjustsFontSizeToFitWidth = true
        bio.minimumScaleFactor = 0.1
        bio.numberOfLines = 0
        bio.text = actor!.bio
        
        self.navigationItem.title = actor!.name
    }

}
