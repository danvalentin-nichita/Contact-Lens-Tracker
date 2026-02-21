//
//  ContactLensTrackerApp.swift
//  ContactLensTracker
//
//  Created by Dan Valentin Nichita on 21/02/26.
//

import SwiftUI
import CoreData

@main
struct ContactLensTrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
