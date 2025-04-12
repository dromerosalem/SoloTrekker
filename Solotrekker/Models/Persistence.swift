// Persistence.swift
// SoloTrekker
//
// Created on current date
//

import CoreData

/// Manages the CoreData persistent store for the app
struct PersistenceController {
    // Shared singleton instance
    static let shared = PersistenceController()
    
    // For SwiftUI previews - contains sample data
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        // Create sample trips
        let trip1 = Trip(context: context)
        trip1.id = UUID()
        trip1.title = "Japan Adventure"
        trip1.startDate = Date().addingTimeInterval(-86400 * 5) // 5 days ago
        trip1.endDate = Date().addingTimeInterval(86400 * 10)   // 10 days from now
        trip1.destination = "Tokyo, Japan"
        trip1.notes = "First solo trip to Japan, focusing on food and culture"
        trip1.budget = 2500
        trip1.currency = "USD"
        trip1.colorHex = "#4A90E2"
        
        let trip2 = Trip(context: context)
        trip2.id = UUID()
        trip2.title = "Costa Rica Eco-Tour"
        trip2.startDate = Date().addingTimeInterval(86400 * 30)  // 30 days from now
        trip2.endDate = Date().addingTimeInterval(86400 * 37)    // 37 days from now
        trip2.destination = "San José, Costa Rica"
        trip2.notes = "Jungle adventures and beach relaxation"
        trip2.budget = 1800
        trip2.currency = "USD"
        trip2.colorHex = "#50E3C2"
        
        // Create itinerary items for trip1
        let item1 = ItineraryItem(context: context)
        item1.id = UUID()
        item1.title = "Check-in: Hotel Sakura"
        item1.itemDescription = "Reservation #JPN28745"
        item1.startTime = Date().addingTimeInterval(86400 * 1 + 14 * 3600) // Tomorrow at 2pm
        item1.endTime = Date().addingTimeInterval(86400 * 1 + 15 * 3600)   // Tomorrow at 3pm
        item1.location = "1-2-3 Shibuya, Tokyo"
        item1.type = "accommodation"
        item1.trip = trip1
        
        let item2 = ItineraryItem(context: context)
        item2.id = UUID()
        item2.title = "Tokyo Tower Visit"
        item2.itemDescription = "Tourist attraction with great views"
        item2.startTime = Date().addingTimeInterval(86400 * 2 + 10 * 3600) // Day after tomorrow at 10am
        item2.endTime = Date().addingTimeInterval(86400 * 2 + 13 * 3600)   // Day after tomorrow at 1pm
        item2.location = "Tokyo Tower, Minato City"
        item2.type = "excursion"
        item2.trip = trip1
        
        // Create an expense for trip1
        let expense1 = Expense(context: context)
        expense1.id = UUID()
        expense1.title = "Hotel Deposit"
        expense1.amount = 200
        expense1.currency = "USD"
        expense1.date = Date().addingTimeInterval(-86400 * 10) // 10 days ago
        expense1.paymentStatus = "paid"
        expense1.category = "accommodation"
        expense1.trip = trip1
        
        let expense2 = Expense(context: context)
        expense2.id = UUID()
        expense2.title = "Flight JL089"
        expense2.amount = 850
        expense2.currency = "USD"
        expense2.date = Date().addingTimeInterval(-86400 * 30) // 30 days ago
        expense2.paymentStatus = "paid"
        expense2.category = "transport"
        expense2.trip = trip1
        
        // Save the context
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Failed to create preview data: \(nsError)")
        }
        
        return controller
    }()
    
    // The persistent container for the app
    let container: NSPersistentContainer
    
    /// Initialize the persistence controller
    /// - Parameter inMemory: Whether to use in-memory storage (for previews)
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SoloTrekker")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                // This would typically show an error to the user
                fatalError("Failed to load Core Data: \(error), \(error.userInfo)")
            }
        }
        
        // Enable automatic merging of changes
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Enable undo manager for better editing support
        container.viewContext.undoManager = UndoManager()
    }
} 