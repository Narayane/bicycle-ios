//
//  BICContract+CoreDataClass.swift
//  Bicycle
//
//  Created by Sébastien BALARD on 17/09/2018.
//  Copyright © 2018 Sébastien BALARD. All rights reserved.
//
//

import Foundation
import CoreData
import MapKit

public class BICContract: NSManagedObject {
    
    static func ==(lhs: BICContract, rhs: BICContract) -> Bool {
        return lhs.center == rhs.center
    }
    
    convenience init(dto: BICContractDto, in context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entity(forEntityName: "BICContract", in: context)!
        self.init(entity: entity, insertInto: context)
        
        self.name = dto.name
        self.latitude = dto.latitude
        self.longitude = dto.longitude
        self.radius = dto.latitude
        self.url = dto.url
        self.stationCount = Int32(dto.stationCount)
        self.countryCode = dto.countryCode
    }
    
    var center: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        }
    }
    
    var region: MKCoordinateRegion {
        get {
            return MKCoordinateRegion.init(center: center, latitudinalMeters: radius * 2, longitudinalMeters: radius * 2)
        }
    }
}
