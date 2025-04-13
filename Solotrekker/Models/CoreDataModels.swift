// CoreDataModels.swift
// SoloTrekker
//
// Created on current date
//

import Foundation
import CoreData
import SwiftUI

// MARK: - Trip Model
@objc(Trip)
public class Trip: NSManagedObject, Identifiable {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Trip> {
        return NSFetchRequest<Trip>(entityName: "Trip")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var destination: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var notes: String?
    @NSManaged public var budget: Double
    @NSManaged public var currency: String?
    @NSManaged public var colorHex: String?
    @NSManaged public var destinations: NSSet?
    @NSManaged public var documents: NSSet?
    @NSManaged public var expenses: NSSet?
    @NSManaged public var itineraryItems: NSSet?
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        budget = 0.0
        currency = "USD"
        colorHex = "#4A90E2"
    }
    
    // MARK: - Computed Properties
    
    public var wrappedTitle: String {
        title ?? "Untitled Trip"
    }
    
    public var wrappedDestination: String {
        destination ?? "Unknown Destination"
    }
    
    public var wrappedNotes: String {
        notes ?? ""
    }
    
    public var wrappedCurrency: String {
        currency ?? "USD"
    }
    
    public var wrappedColorHex: String {
        colorHex ?? "#4A90E2"
    }
    
    public var color: Color {
        Color(hex: wrappedColorHex) ?? .blue
    }
    
    public var destinationsArray: [TripDestination] {
        let set = destinations as? Set<TripDestination> ?? []
        return Array(set).sorted { (dest1: TripDestination, dest2: TripDestination) -> Bool in
            return (dest1.startDate ?? Date()) < (dest2.startDate ?? Date())
        }
    }
    
    public var documentsArray: [TravelDocument] {
        let set = documents as? Set<TravelDocument> ?? []
        return Array(set).sorted { (doc1: TravelDocument, doc2: TravelDocument) -> Bool in
            return (doc1.dateAdded ?? Date()) > (doc2.dateAdded ?? Date())
        }
    }
    
    public var expensesArray: [Expense] {
        let set = expenses as? Set<Expense> ?? []
        return Array(set).sorted { (exp1: Expense, exp2: Expense) -> Bool in
            return (exp1.date ?? Date()) > (exp2.date ?? Date())
        }
    }
    
    public var itineraryItemsArray: [ItineraryItem] {
        let set = itineraryItems as? Set<ItineraryItem> ?? []
        return Array(set).sorted { (item1: ItineraryItem, item2: ItineraryItem) -> Bool in
            return (item1.startTime ?? Date()) < (item2.startTime ?? Date())
        }
    }
    
    public var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        let start = startDate.map { formatter.string(from: $0) } ?? "Not set"
        let end = endDate.map { formatter.string(from: $0) } ?? "Not set"
        
        return "\(start) - \(end)"
    }
    
    // MARK: - Helper Methods
    
    /// Calculate total expenses in trip's currency
    public var totalExpenses: Double {
        expensesArray.reduce(0) { (total: Double, expense: Expense) -> Double in
            return total + expense.amount
        }
    }
    
    /// Calculate remaining budget
    public var remainingBudget: Double {
        budget - totalExpenses
    }
}

// MARK: - TripDestination Model
@objc(TripDestination)
public class TripDestination: NSManagedObject, Identifiable {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TripDestination> {
        return NSFetchRequest<TripDestination>(entityName: "TripDestination")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var notes: String?
    @NSManaged public var colorHex: String?
    @NSManaged public var trip: Trip?
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        colorHex = "#4A90E2" // Default color
    }
    
    // MARK: - Computed Properties
    
    public var wrappedName: String {
        name ?? "Unnamed Destination"
    }
    
    public var wrappedNotes: String {
        notes ?? ""
    }
    
    public var wrappedColorHex: String {
        colorHex ?? "#4A90E2"
    }
    
    public var color: Color {
        Color(hex: wrappedColorHex) ?? .blue
    }
    
    public var formattedDateRange: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        let start = startDate.map { formatter.string(from: $0) } ?? "Not set"
        let end = endDate.map { formatter.string(from: $0) } ?? "Not set"
        
        return "\(start) - \(end)"
    }
}

// MARK: - ItineraryItem Model
@objc(ItineraryItem)
public class ItineraryItem: NSManagedObject, Identifiable {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ItineraryItem> {
        return NSFetchRequest<ItineraryItem>(entityName: "ItineraryItem")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var itemDescription: String?
    @NSManaged public var location: String?
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var type: String?
    @NSManaged public var trip: Trip?
    @NSManaged public var destination: TripDestination?
    
    public var wrappedTitle: String { title ?? "Untitled Item" }
    public var wrappedDescription: String { itemDescription ?? "" }
    public var wrappedLocation: String { location ?? "" }
    public var wrappedType: String { type ?? "excursion" }
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
    }
}

// MARK: - Expense Model
@objc(Expense)
public class Expense: NSManagedObject, Identifiable {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Expense> {
        return NSFetchRequest<Expense>(entityName: "Expense")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var amount: Double
    @NSManaged public var category: String?
    @NSManaged public var currency: String?
    @NSManaged public var date: Date?
    @NSManaged public var notes: String?
    @NSManaged public var paymentStatus: String?
    @NSManaged public var title: String?
    @NSManaged public var trip: Trip?
    
    public var wrappedTitle: String { title ?? "Untitled Expense" }
    public var wrappedCategory: String { category ?? "other" }
    public var wrappedCurrency: String { currency ?? "USD" }
    public var wrappedNotes: String { notes ?? "" }
    public var wrappedPaymentStatus: String { paymentStatus ?? "due" }
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
    }
} 