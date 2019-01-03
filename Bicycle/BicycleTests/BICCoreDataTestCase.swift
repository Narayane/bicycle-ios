//
//  Copyright © 2018 Bicycle (Sébastien BALARD)
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import XCTest
import CoreData
@testable import Bicycle

class BICCoreDataTestCase: XCTestCase {
    
    var context: NSManagedObjectContext?
    var coordinator: NSPersistentStoreCoordinator?
    var store: NSPersistentStore?
    
    override func setUp() {
        super.setUp()
        if context == nil {
            context = setUpInMemoryManagedObjectContext()
            coordinator = context?.persistentStoreCoordinator
            store = coordinator?.persistentStores[0]
            XCTAssertNotNil(store, "no persistent store")
        }
    }
    
    override func tearDown() {
        super.tearDown()
        if context != nil {
            context = nil
            try! coordinator?.remove(store!)
        }
    }
}

extension XCTestCase {
    
    func setUpInMemoryManagedObjectContext() -> NSManagedObjectContext? {
        
        do {
            let model = NSManagedObjectModel.mergedModel(from: nil)!
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
            
            try coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
            
            let context = NSManagedObjectContext(concurrencyType:.privateQueueConcurrencyType)
            context.persistentStoreCoordinator = coordinator
            
            return context
            
        } catch {
            log.e("fail to add in-memory persistent store")
            return nil
        }
    }
}
