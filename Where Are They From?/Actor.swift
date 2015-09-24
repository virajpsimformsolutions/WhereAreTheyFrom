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
        static let Bio = "biography"
        static let ID = "id"
        static let BirthPlace = "place_of_birth"
        static let Website = "homepage"
        static let Latitude = "latitude"
        static let Longitude = "longitude"
    }
    
    @NSManaged var name: String
    @NSManaged var id: NSNumber
    @NSManaged var imageURL: String?
    @NSManaged var bio: String?
    @NSManaged var website: String?
    @NSManaged var birthplace: String?
    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject?], context: NSManagedObjectContext) {
        
        let entity =  NSEntityDescription.entityForName("Actor", inManagedObjectContext: context)!
        
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        name = dictionary[Keys.Name] as! String
        id = dictionary[Keys.ID] as! Int
        imageURL = dictionary[Keys.ImageURL] as? String
        bio = dictionary[Keys.Bio] as? String
        website = dictionary[Keys.Website] as? String
        birthplace = dictionary[Keys.BirthPlace] as? String
        latitude = dictionary[Keys.Latitude] as? Double
        longitude = dictionary[Keys.Longitude] as? Double
    }
    
    var image: UIImage? {
        get {
            return TheMovieDB.Caches.imageCache.imageWithIdentifier(imageURL)
        }
        
        set {
            TheMovieDB.Caches.imageCache.storeImage(image, withIdentifier: imageURL!)
        }
    }
    
}

