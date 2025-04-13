import Foundation
import CoreData

extension TravelDocument {
    // MARK: - Fetch Request
    
    /// Fetches all travel documents sorted by date added (most recent first)
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TravelDocument> {
        let request = NSFetchRequest<TravelDocument>(entityName: "TravelDocument")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TravelDocument.dateAdded, ascending: false)]
        return request
    }
    
    // MARK: - Properties
    
    /// Unique identifier for the document
    @NSManaged public var id: UUID?
    
    /// The binary data of the document
    @NSManaged public var documentData: Data?
    
    /// The type of document (e.g., passport, visa, insurance, etc.)
    @NSManaged public var documentType: String?
    
    /// The filename of the document
    @NSManaged public var filename: String?
    
    /// The date when the document was added
    @NSManaged public var dateAdded: Date?
    
    /// The title or name of the document
    @NSManaged public var title: String?
    
    /// Optional notes about the document
    @NSManaged public var notes: String?
    
    /// The trip this document belongs to (optional)
    @NSManaged public var trip: Trip?
    
    // MARK: - Validation
    
    /// Validates the document data before saving
    public func validate() throws {
        // Ensure required fields are not empty
        guard let title = title, !title.isEmpty else {
            throw ValidationError.missingTitle
        }
        
        guard let documentType = documentType, !documentType.isEmpty else {
            throw ValidationError.missingDocumentType
        }
        
        guard let filename = filename, !filename.isEmpty else {
            throw ValidationError.missingFilename
        }
        
        guard documentData != nil else {
            throw ValidationError.missingDocumentData
        }
    }
}

// MARK: - Validation Error

extension TravelDocument {
    enum ValidationError: LocalizedError {
        case missingTitle
        case missingDocumentType
        case missingFilename
        case missingDocumentData
        
        var errorDescription: String? {
            switch self {
            case .missingTitle:
                return "Document title is required"
            case .missingDocumentType:
                return "Document type is required"
            case .missingFilename:
                return "Filename is required"
            case .missingDocumentData:
                return "Document data is required"
            }
        }
    }
} 