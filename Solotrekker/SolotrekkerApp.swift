// SoloTrekkerApp.swift
// SoloTrekker
//
// Created on current date
//

import SwiftUI
import UIKit

/// Main entry point for the SoloTrekker app
@main
struct SoloTrekkerApp: App {
    // Inject the CoreData persistence controller into the environment
    let persistenceController = PersistenceController.shared
    
    // Define the app's scene
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(AppViewModel())
        }
    }
} 