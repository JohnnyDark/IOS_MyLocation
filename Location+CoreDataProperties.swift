//
//  Location+CoreDataProperties.swift
//  MyLocation
//
//  Created by Naver on 2020/10/29.
//  Copyright © 2020 Johnny. All rights reserved.
//
//

import Foundation
import CoreData


extension Location {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Location> {
        return NSFetchRequest<Location>(entityName: "Location")
    }

    @NSManaged public var category: String
    @NSManaged public var date: Date
    @NSManaged public var latitude: Double
    @NSManaged public var locationDescription: String
    @NSManaged public var longitude: Double
    @NSManaged public var placemark: CLPlacemark?
    @NSManaged public var photoID: NSNumber?

}

extension Location : Identifiable {

}
