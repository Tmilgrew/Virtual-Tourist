//
//  Location+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Thomas Milgrew on 2/13/18.
//  Copyright © 2018 Thomas Milgrew. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Location)
public class Location: NSManagedObject {
    convenience init(latitude: Double, longitude: Double, context: NSManagedObjectContext){
        
        if let ent = NSEntityDescription.entity(forEntityName: "Location", in: context){
            self.init(entity: ent, insertInto: context)
            self.latitude = latitude
            self.longitude = longitude
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
}
