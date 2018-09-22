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

import CoreData
import RxSwift

class BICLocalDataSource {
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "Bicycle")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                log.e("fail to load persistent container: \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                log.e("fail to save coredate context: \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: Contract
    
    func findAllContracts() -> [BICContract] {
        do {
            let results = try persistentContainer.viewContext.fetch(BICContract.fetchRequest()) as [BICContract]
            if results.count > 0 {
                return results
            }
        } catch let error as NSError {
            log.e("fail to find all contracts: \(error.debugDescription)")
        }
        return []
    }
    
    func insertAllContracts(dtos: [BICContractDto]) -> Int {
        do {
            for dto in dtos {
                let _ = BICContract(dto: dto, in: persistentContainer.viewContext)
            }
            try persistentContainer.viewContext.save()
            return dtos.count
        } catch let error as NSError {
            log.e("fail to insert all contracts: \(error.debugDescription)")
        }
        return 0
    }
    
    func deleteAllContracts() -> Int {
        do {
            /*let deleteRequest = NSBatchDeleteRequest(fetchRequest: BICContract.fetchRequest())
            deleteRequest.resultType = .resultTypeCount
            let deleteResult = try persistentContainer.viewContext.execute(deleteRequest) as! NSBatchDeleteResult*/
            if let results = try persistentContainer.viewContext.fetch(BICContract.fetchRequest()) as? [BICContract] {
                for object in results {
                    persistentContainer.viewContext.delete(object)
                }
                try persistentContainer.viewContext.save()
                return results.count
            }
        } catch let error as NSError {
            log.e("fail to delete all contracts: \(error.debugDescription)")
        }
        return 0
    }
}
