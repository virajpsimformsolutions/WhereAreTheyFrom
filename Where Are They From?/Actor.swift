//
//  Actor.swift
//  Where Are They From?
//
//  Created by Ryan Whitell on 2015-09-23.
//
//

import Foundation
import UIKit
import CoreData

@objc(Actor)

class Actor : NSManagedObject {
    
    struct Keys {
        static let Name = "name"
        static let ImageURL = "profile_path"
        static let Bio = "bio"
        static let ID = "id"
    }
    
    @NSManaged var name: String
    @NSManaged var id: NSNumber
    @NSManaged var imageURL: String?
    @NSManaged var bio: String?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Actor", inManagedObjectContext: context)!
        
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        name = dictionary[Keys.Name] as! String
        id = dictionary[Keys.ID] as! Int
        imageURL = dictionary[Keys.ImageURL] as? String
        bio = dictionary[Keys.Bio] as? String
    }
    
}

