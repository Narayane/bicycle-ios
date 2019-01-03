//
//  BICContract+CoreDataProperties.swift
//  
//
//  Created by Sébastien BALARD on 03/01/2019.
//
//

import Foundation
import CoreData


extension BICContract {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BICContract> {
        return NSFetchRequest<BICContract>(entityName: "BICContract")
    }

    @NSManaged public var countryCode: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var name: String?
    @NSManaged public var radius: Int64
    @NSManaged public var stationCount: Int64
    @NSManaged public var url: String?

}
