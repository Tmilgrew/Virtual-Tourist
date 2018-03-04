//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Thomas Milgrew on 3/1/18.
//  Copyright © 2018 Thomas Milgrew. All rights reserved.
//
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var imageData: NSData?
    @NSManaged public var photoID: String?
    @NSManaged public var imageUrl: String?
    @NSManaged public var photoToLocation: Location?

}
