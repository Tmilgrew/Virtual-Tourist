//
//  Photo+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Thomas Milgrew on 2/13/18.
//  Copyright © 2018 Thomas Milgrew. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Photo)
public class Photo: NSManagedObject {
    
    convenience init(photo: String, title: String, context: NSManagedObjectContext){
        
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context){
            self.init(entity: ent, insertInto: context)
            self.imageData = photo
            self.photoID = title
        } else {
            fatalError("Could not find Entity name!")
        }
    }
    
}
