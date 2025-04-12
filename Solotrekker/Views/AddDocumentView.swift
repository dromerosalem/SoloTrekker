// AddDocumentView.swift
// SoloTrekker
//
// Created on current date
//

import SwiftUI
import CoreData
import UIKit
import UniformTypeIdentifiers

/// View for adding a new document to a trip
struct AddDocumentView: View {
    // Environment for dismissing the sheet
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var viewContext
    
    // Trip to add the document to
    let trip: Trip
    
    // Form fields
    @State private var title = ""
    @State private var documentType = "image"
    @State private var selectedImageData: Data? = nil
    @State private var showingImagePicker = false
    
    // Available document types
    let documentTypes = [
        "image": "Image",
        "pdf": "PDF",
        "ticket": "Ticket",
        "reservation": "Reservation",
        "passport": "Passport/Visa",
        "other": "Other"
    ]
    
    // Input validation
    private var isFormValid: Bool {
        !title.isEmpty && selectedImageData != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic document information
                Section(header: Text("Document Details")) {
                    TextField("Title", text: $title)
                    
                    Picker("Document Type", selection: $documentType) {
                        ForEach(documentTypes.keys.sorted(), id: \.self) { key in
                            Text(documentTypes[key] ?? key).tag(key)
                        }
                    }
                }
                
                // Image picker section
                Section(header: Text("Document Image")) {
                    // Document preview
                    if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                        HStack {
                            Spacer()
                            
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(8)
                            
                            Spacer()
                        }
                        .padding(.vertical)
                        
                        Button(action: {
                            // Clear the selected image
                            self.selectedImageData = nil
                        }) {
                            Label("Remove Image", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                    } else {
                        // Image picker button
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            Label("Select Image", systemImage: "photo")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                        }
                        .sheet(isPresented: $showingImagePicker) {
                            ImagePickerView(selectedImageData: $selectedImageData)
                        }
                    }
                }
            }
            .navigationTitle("Add Document")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveDocument()
                }
                .disabled(!isFormValid)
            )
        }
    }
    
    /// Save the new document to CoreData
    private func saveDocument() {
        // Create a new document entity
        let newDocument = TravelDocument(context: viewContext)
        newDocument.id = UUID()
        newDocument.title = title
        newDocument.documentType = documentType
        newDocument.dateAdded = Date()
        newDocument.documentData = selectedImageData
        
        // Generate a filename for reference
        let fileExtension = documentType == "pdf" ? "pdf" : "jpg"
        newDocument.filename = "\(UUID().uuidString).\(fileExtension)"
        
        // Link to trip
        newDocument.trip = trip
        
        // Save the context
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            let nsError = error as NSError
            print("Error saving document: \(nsError)")
        }
    }
}

// MARK: - Image Picker View
struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var selectedImageData: Data?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView
        
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImageData = editedImage.jpegData(compressionQuality: 0.8)
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImageData = originalImage.jpegData(compressionQuality: 0.8)
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Preview
struct AddDocumentView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let tripRequest: NSFetchRequest<Trip> = Trip.fetchRequest()
        let trips = try? context.fetch(tripRequest)
        
        return Group {
            if let firstTrip = trips?.first {
                AddDocumentView(trip: firstTrip)
                    .environment(\.managedObjectContext, context)
            } else {
                Text("No preview data available")
            }
        }
    }
} 