//
//  GCDBlackBox.swift
//  VirtualTourist
//
//  Created by Marquis Dennis on 2/23/16.
//  Copyright © 2016 Marquis Dennis. All rights reserved.
//

import Foundation


//Found on GitHub for assisting with placing events in the correct queue.
func performUIUpdatesOnMain(_ updates:@escaping () -> Void ) {
    DispatchQueue.main.async { () -> Void in
        updates()
    }
}

func performDownloadsAndUpdateInBackground(_ updates:@escaping () -> Void) {
    DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async { () -> Void in
        updates()
    }
}

func handleBackgroundFileOperations(_ updates:@escaping () -> Void) {
    DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).async { () -> Void in
        updates()
    }
}

func handleManagedObjectContextOperations(_ updates:@escaping () -> Void ) {
    DispatchQueue.main.async { () -> Void in
        updates()
    }
}

func background(_ updates:@escaping () -> Void ){
    CoreDataStack.sharedInstance.backgroundContext.perform {
        updates()
    }
}
