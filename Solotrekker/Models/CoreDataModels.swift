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
    @NSManaged public var dueDate: Date?
    @NSManaged public var notes: String?
    @NSManaged public var paidAmount: Double
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
        paidAmount = 0.0
    }
    
    // MARK: - Additional methods needed for ExpenseRow
    
    /// Returns the formatted amount with currency symbol
    public var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = wrappedCurrency
        
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
    
    /// Returns the amount that is still due to be paid
    public var dueAmount: Double {
        if isPartiallyPaid {
            return amount - paidAmount
        } else if isDue {
            return amount
        } else {
            return 0.0
        }
    }
    
    /// Returns the formatted paid amount with currency symbol
    public var formattedPaidAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = wrappedCurrency
        
        return formatter.string(from: NSNumber(value: paidAmount)) ?? "$\(paidAmount)"
    }
    
    /// Returns the formatted due amount with currency symbol
    public var formattedDueAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = wrappedCurrency
        
        return formatter.string(from: NSNumber(value: dueAmount)) ?? "$\(dueAmount)"
    }
    
    /// Returns a formatted string for the due date
    public var formattedDueDate: String {
        guard let dueDate = dueDate else { return "No due date" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dueDate)
    }
    
    /// Check if the expense is paid
    public var isPaid: Bool {
        wrappedPaymentStatus == "paid"
    }
    
    /// Check if the expense is due
    public var isDue: Bool {
        wrappedPaymentStatus == "due"
    }
    
    /// Check if the expense is partially paid
    public var isPartiallyPaid: Bool {
        wrappedPaymentStatus == "partial"
    }
    
    /// Get an appropriate icon name for the expense category
    public func iconName() -> String {
        switch wrappedCategory {
        case "accommodation":
            return "house.fill"
        case "transport":
            return "airplane"
        case "food":
            return "fork.knife"
        case "activities":
            return "ticket.fill"
        case "shopping":
            return "bag.fill"
        default:
            return "dollarsign.circle.fill"
        }
    }
    
    /// Get an appropriate color for the payment status
    public func statusColor() -> Color {
        switch wrappedPaymentStatus {
        case "paid":
            return .green
        case "due":
            return .red
        case "partial":
            return .orange
        default:
            return .gray
        }
    }
    
    /// Format the date for display
    public func formattedDate() -> String {
        guard let date = date else { return "No date" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        return formatter.string(from: date)
    }
    
    /// Get human-readable category name
    public func displayCategory() -> String {
        switch wrappedCategory {
        case "accommodation":
            return "Accommodation"
        case "transport":
            return "Transportation"
        case "food":
            return "Food & Dining"
        case "activities":
            return "Activities & Tours"
        case "shopping":
            return "Shopping"
        default:
            return "Other"
        }
    }
    
    /// Get human-readable payment status
    public func displayPaymentStatus() -> String {
        switch wrappedPaymentStatus {
        case "paid":
            return "Paid"
        case "due":
            return "Due"
        case "partial":
            return "Partially Paid"
        default:
            return "Unknown"
        }
    }
}

// MARK: - TravelDocument Model
@objc(TravelDocument)
public class TravelDocument: NSManagedObject, Identifiable {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TravelDocument> {
        let request = NSFetchRequest<TravelDocument>(entityName: "TravelDocument")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TravelDocument.dateAdded, ascending: false)]
        return request
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var documentData: Data?
    @NSManaged public var documentType: String?
    @NSManaged public var filename: String?
    @NSManaged public var dateAdded: Date?
    @NSManaged public var title: String?
    @NSManaged public var notes: String?
    @NSManaged public var trip: Trip?
    
    // MARK: - Computed Properties
    public var wrappedTitle: String { title ?? "Untitled Document" }
    public var wrappedDocumentType: String { documentType ?? "Other" }
    public var wrappedNotes: String { notes ?? "" }
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        dateAdded = Date()
    }
    
    /// Returns the document title with a default value if nil
    public var wrappedFilename: String {
        filename ?? "unknown.pdf"
    }
    
    /// Extracts and returns the file extension from the filename
    public var fileExtension: String {
        let filename = wrappedFilename
        return filename.contains(".") ? filename.components(separatedBy: ".").last?.lowercased() ?? "pdf" : "pdf"
    }
    
    /// Returns the appropriate icon name based on the file extension
    public var iconName: String {
        switch fileExtension {
        case "pdf":
            return "doc.text"
        case "jpg", "jpeg", "png", "heic":
            return "photo"
        case "doc", "docx":
            return "doc.text"
        case "xls", "xlsx":
            return "chart.bar.doc.horizontal"
        case "ppt", "pptx":
            return "chart.bar.doc.horizontal"
        default:
            return "doc"
        }
    }
    
    /// Returns a formatted date string
    public var formattedDate: String {
        guard let date = dateAdded else { return "Unknown date" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    /// Returns the appropriate color based on document type
    public func documentTypeColor() -> Color {
        switch wrappedDocumentType.lowercased() {
        case "passport":
            return Color.blue
        case "visa":
            return Color.green
        case "insurance":
            return Color.red
        case "booking":
            return Color.orange
        case "ticket":
            return Color.purple
        case "receipt":
            return Color.yellow
        case "medical":
            return Color.pink
        default:
            return Color.gray
        }
    }
    
    /// Checks if the document has stored binary data
    public var hasStoredData: Bool {
        return documentData != nil && (documentData?.count ?? 0) > 0
    }
    
    /// Returns the document size in a human-readable format
    public var documentSize: String {
        guard let data = documentData, data.count > 0 else {
            return "No data"
        }
        
        let bytes = Double(data.count)
        let kb = bytes / 1024
        let mb = kb / 1024
        
        if mb >= 1.0 {
            return String(format: "%.2f MB", mb)
        } else {
            return String(format: "%.0f KB", kb)
        }
    }
} 