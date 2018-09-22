//
//  BICContract+CoreDataProperties.swift
//  Bicycle
//
//  Created by Sébastien BALARD on 17/09/2018.
//  Copyright © 2018 Sébastien BALARD. All rights reserved.
//
//

import Foundation
import CoreData


extension BICContract {
    
    class func fetchRequest() -> NSFetchRequest<BICContract> {
        return NSFetchRequest<BICContract>(entityName: "BICContract")
    }

    @NSManaged public var countryCode: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var name: String?
    @NSManaged public var radius: Double
    @NSManaged public var stationCount: Int32
    @NSManaged public var url: String?

}
