//
//  CoreDataStack.swift
//  Virtual Tourist 2
//
//  Created by Octavio Cedeno on 3/9/17.
//  Copyright © 2017 Cedeno Enterprises, Inc. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack : NSObject
{
    static let sharedInstance = CoreDataStack()
    static let moduleName = "VirtualTouristModel"
    
    struct Constants
    {
        struct EntityNames
        {
            static let PhotoEntityName = "Photo"
            static let PinEntityName = "PinAnnotation"
        }
    }
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator =
        {
            //location of the managed object model persisted on disk
            let modelURL = Bundle.main.url(forResource: moduleName, withExtension: "momd")!
            
            //instantiate the persistent store coordinator
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: NSManagedObjectModel(contentsOf: modelURL)!)
            
            //application documents directory where user files are stored
            let applicationDocumentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
            
            //location on disk of the actual persistent store
            let persistentStoreURL = applicationDocumentsDirectory.appendingPathComponent("\(moduleName).sqlite")
            print(persistentStoreURL)
            
            //add the persistent store to the persistent store coordinator
            do {
                try coordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                   configurationName: nil,
                                                   at: persistentStoreURL,
                                                   options: [NSMigratePersistentStoresAutomaticallyOption: true,
                                                             NSInferMappingModelAutomaticallyOption : true])
            } catch {
                fatalError("Persistent store error! \(error)")
            }
            
            return coordinator
            
    }()
    
    //create managed object context
    lazy var mainContext:NSManagedObjectContext =
        {
            let mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            mainContext.persistentStoreCoordinator = self.persistentStoreCoordinator
            return mainContext
    }()
    
    // Create a persistingContext (private queue) and a child one (main queue)
    // create a context and add connect it to the coordinator
    lazy var persistingContext: NSManagedObjectContext =
    {
        let persistingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        persistingContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        return persistingContext
    }()
    
    lazy var backgroundContext: NSManagedObjectContext =
    {
        let backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        return backgroundContext
    }()
}

extension CoreDataStack
{
    func save() {
        // We call this synchronously, but it's a very fast
        // operation (it doesn't hit the disk). We need to know
        // when it ends so we can call the next save (on the persisting
        // context). This last one might take some time and is done
        // in a background queue
        mainContext.performAndWait() {
            
            if self.mainContext.hasChanges {
                do {
                    try self.mainContext.save()
                } catch {
                    fatalError("Error while saving main context: \(error)")
                }
                
                // now we save in the background
                self.persistingContext.perform() {
                    do {
                        try self.persistingContext.save()
                    } catch {
                        fatalError("Error while saving persisting context: \(error)")
                    }
                }
            }
        }
    }
    
    func autoSave(_ delayInSeconds : Int) {
        
        if delayInSeconds > 0 {
            do {
                try self.mainContext.save()
                print("Autosaving")
            } catch {
                print("Error while autosaving")
            }
            
            let delayInNanoSeconds = UInt64(delayInSeconds) * NSEC_PER_SEC
            let time = DispatchTime.now() + Double(Int64(delayInNanoSeconds)) / Double(NSEC_PER_SEC)
            
            DispatchQueue.main.asyncAfter(deadline: time) {
                self.autoSave(delayInSeconds)
            }
        }
    }
}
