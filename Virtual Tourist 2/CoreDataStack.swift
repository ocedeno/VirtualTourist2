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
    
    //save managed context if changes exist
    func saveMainContext()
    {
        handleManagedObjectContextOperations{ () -> Void in
            if self.managedObjectContext.hasChanges
            {
                do
                {
                    try self.managedObjectContext.save()
                } catch
                {
                    let saveError = error as NSError
                    print("There was an error saving main managed object context! \(saveError)")
                }
            }
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
    lazy var managedObjectContext:NSManagedObjectContext =
    {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        return managedObjectContext
    }()
    
}

