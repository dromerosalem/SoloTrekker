import Foundation
import CoreData
import SwiftUI

// Custom class for TravelDocument entity that provides additional functionality and type safety
@objc(TravelDocument)
public class TravelDocument: NSManagedObject, Identifiable {
    // MARK: - Computed Properties
    
    /// Returns a non-optional title with a default value if nil
    public var wrappedTitle: String {
        title ?? "Untitled Document"
    }
    
    /// Returns a non-optional document type with a default value if nil
    public var wrappedDocumentType: String {
        documentType ?? "Other"
    }
    
    /// Returns a non-optional filename with a default value if nil
    public var wrappedFilename: String {
        filename ?? "unknown_file"
    }
    
    /// Returns the file extension from the filename
    public var fileExtension: String {
        (wrappedFilename as NSString).pathExtension.lowercased()
    }
    
    /// Returns the icon name based on the document type and file extension
    public var iconName: String {
        switch wrappedDocumentType.lowercased() {
        case "passport":
            return "passport.fill"
        case "visa":
            return "doc.text.fill"
        case "insurance":
            return "cross.case.fill"
        case "ticket":
            return "ticket.fill"
        case "reservation":
            return "building.2.fill"
        case "vaccination":
            return "heart.text.square.fill"
        default:
            // Return icon based on file extension
            switch fileExtension {
            case "pdf":
                return "doc.fill"
            case "jpg", "jpeg", "png", "heic":
                return "photo.fill"
            default:
                return "doc.fill"
            }
        }
    }
    
    /// Returns a formatted date string for the dateAdded property
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dateAdded ?? Date())
    }
    
    // MARK: - Helper Methods
    
    /// Returns the color associated with the document type
    public func documentTypeColor() -> Color {
        switch wrappedDocumentType.lowercased() {
        case "passport":
            return Color.blue
        case "visa":
            return Color.red
        case "insurance":
            return Color.green
        case "ticket":
            return Color.orange
        case "reservation":
            return Color.purple
        case "vaccination":
            return Color.teal
        default:
            return Color.gray
        }
    }
    
    /// Returns true if the document has binary data stored
    public var hasStoredData: Bool {
        documentData != nil
    }
    
    /// Returns the size of the stored document data in a human-readable format
    public var documentSize: String {
        guard let data = documentData else { return "0 KB" }
        
        let bytes = Double(data.count)
        let units = ["B", "KB", "MB", "GB"]
        var size = bytes
        var unitIndex = 0
        
        while size > 1024 && unitIndex < units.count - 1 {
            size /= 1024
            unitIndex += 1
        }
        
        return String(format: "%.1f %@", size, units[unitIndex])
    }
    
    // MARK: - Core Data
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        dateAdded = Date() // Set current date when created
        id = UUID() // Set unique identifier when created
    }
} 