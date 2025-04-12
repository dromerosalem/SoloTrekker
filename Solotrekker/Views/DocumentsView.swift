// DocumentsView.swift
// SoloTrekker
//
// Created on current date
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers
import UIKit
import PhotosUI

// Add this extension for compatibility with DocumentPicker
extension View {
    func showDocumentPicker(isPresented: Binding<Bool>) -> some View {
        self // In a real app, this would show a document picker
    }
}

/// View for displaying and managing travel documents
struct DocumentsView: View {
    // Trip to display documents for
    let trip: Trip
    
    // Access to managed object context and app view model
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appViewModel: AppViewModel
    
    // Fetch documents from CoreData
    @FetchRequest private var documents: FetchedResults<TravelDocument>
    
    // UI state
    @State private var selectedDocument: TravelDocument? = nil
    @State private var showingDocumentPicker = false
    @State private var showingCamera = false
    @State private var showingDocumentDetail = false
    @State private var showCameraActionSheet = false
    
    // Document type options
    let documentTypes = [
        "image": "Image",
        "pdf": "PDF",
        "ticket": "Ticket",
        "reservation": "Reservation",
        "passport": "Passport/Visa",
        "other": "Other"
    ]
    
    // Initialize with trip and fetch request
    init(trip: Trip) {
        self.trip = trip
        
        // Create a predicate to filter documents by trip
        let predicate = NSPredicate(format: "trip == %@", trip)
        
        // Create a fetch request with sorting
        _documents = FetchRequest<TravelDocument>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \TravelDocument.dateAdded, ascending: false)
            ],
            predicate: predicate,
            animation: .default
        )
    }
    
    var body: some View {
        VStack {
            if documents.isEmpty {
                // Empty state
                VStack(spacing: 20) {
                    Image(systemName: "doc.circle")
                        .font(.system(size: 80))
                        .foregroundColor(.teal)
                    
                    Text("No Documents Yet")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Add your travel documents like tickets, reservations, and passports.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Button(action: {
                        showCameraActionSheet = true
                    }) {
                        Text("Add Your First Document")
                            .fontWeight(.semibold)
                            .padding()
                            .background(Color.teal)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top)
                }
                .padding()
            } else {
                // Document grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 20) {
                        ForEach(documents) { document in
                            DocumentCard(document: document)
                                .onTapGesture {
                                    selectedDocument = document
                                    showingDocumentDetail = true
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        deleteDocument(document)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        // Sheets and modals
        .sheet(isPresented: $appViewModel.isAddingDocument) {
            AddDocumentView(trip: trip)
        }
        .sheet(isPresented: $showingDocumentDetail) {
            if let document = selectedDocument {
                DocumentDetailView(document: document)
            }
        }
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPickerView(trip: trip)
        }
        .sheet(isPresented: $showingCamera) {
            Text("Camera functionality would go here")
                .padding()
        }
        .navigationBarItems(
            trailing: Button(action: {
                showCameraActionSheet = true
            }) {
                Image(systemName: "plus")
            }
        )
        .actionSheet(isPresented: $showCameraActionSheet) {
            ActionSheet(
                title: Text("Add Document"),
                buttons: [
                    .default(Text("Take Photo")) {
                        showingCamera = true
                    },
                    .default(Text("Choose Existing")) {
                        showingDocumentPicker = true
                    },
                    .cancel()
                ]
            )
        }
    }
    
    /// Delete a document
    /// - Parameter document: The document to delete
    private func deleteDocument(_ document: TravelDocument) {
        withAnimation {
            viewContext.delete(document)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error deleting document: \(nsError)")
            }
        }
    }
}

/// Card view for a document
struct DocumentCard: View {
    let document: TravelDocument
    
    var body: some View {
        VStack {
            // Document thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .aspectRatio(3/4, contentMode: .fit)
                
                if let data = document.documentData, let uiImage = UIImage(data: data) {
                    // Image thumbnail
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    // Default icon
                    Image(systemName: documentIcon)
                        .font(.system(size: 40))
                        .foregroundColor(.teal)
                }
            }
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            
            // Document title
            Text(document.title ?? "Document")
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
            
            // Document type and date
            HStack {
                Text(documentType.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let date = document.dateAdded {
                    Text(dateFormatter.string(from: date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 150)
    }
    
    // Get icon based on document type
    private var documentIcon: String {
        switch document.documentType {
        case "pdf":
            return "doc.text.fill"
        case "ticket":
            return "ticket.fill"
        case "reservation":
            return "building.2.fill"
        case "passport":
            return "person.crop.square.fill"
        default:
            return "photo.fill"
        }
    }
    
    // Get document type display name
    private var documentType: String {
        switch document.documentType {
        case "pdf":
            return "PDF"
        case "ticket":
            return "Ticket"
        case "reservation":
            return "Reservation"
        case "passport":
            return "ID/Passport"
        case "image":
            return "Image"
        default:
            return "Document"
        }
    }
    
    // Date formatter for document date
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}

/// Document detail view
struct DocumentDetailView: View {
    // Document to display
    let document: TravelDocument
    
    // Environment for dismissing
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                if let data = document.documentData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                } else {
                    Text("No document data available")
                }
            }
            .navigationTitle(document.title ?? "Document")
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

/// Document picker view
struct DocumentPickerView: View {
    // Trip to add documents to
    let trip: Trip
    
    // Environment for context and dismissal
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Text("Document Picker Would Go Here")
            .font(.headline)
            .padding()
            .onAppear {
                // In a real implementation, this would show a document picker
                // For now, we'll just dismiss after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
    }
}

// MARK: - Preview
struct DocumentsView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let tripRequest: NSFetchRequest<Trip> = Trip.fetchRequest()
        let trips = try? context.fetch(tripRequest)
        
        return Group {
            if let firstTrip = trips?.first {
                DocumentsView(trip: firstTrip)
                    .environment(\.managedObjectContext, context)
                    .environmentObject(AppViewModel())
            } else {
                Text("No preview data available")
            }
        }
    }
} 