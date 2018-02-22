//
//  Location+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Thomas Milgrew on 2/13/18.
//  Copyright © 2018 Thomas Milgrew. All rights reserved.
//
//

import Foundation
import CoreData


extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var locationToPhoto: NSSet?

}

// MARK: Generated accessors for locationToPhoto
extension Location {

    @objc(addLocationToPhotoObject:)
    @NSManaged public func addToLocationToPhoto(_ value: Photo)

    @objc(removeLocationToPhotoObject:)
    @NSManaged public func removeFromLocationToPhoto(_ value: Photo)

    @objc(addLocationToPhoto:)
    @NSManaged public func addToLocationToPhoto(_ values: NSSet)

    @objc(removeLocationToPhoto:)
    @NSManaged public func removeFromLocationToPhoto(_ values: NSSet)

}
