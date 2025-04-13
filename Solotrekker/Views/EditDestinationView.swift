// EditDestinationView.swift
// SoloTrekker
//
// Created on current date
//

import SwiftUI
import CoreData

/// View for editing an existing destination in a trip
struct EditDestinationView: View {
    // MARK: - Environment
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties
    
    /// The destination being edited
    @ObservedObject var destination: TripDestination
    
    /// Temporary state for form fields
    @State private var name: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var notes: String
    @State private var color: Color
    
    /// Alert state
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // MARK: - Initialization
    
    init(destination: TripDestination) {
        self.destination = destination
        
        // Initialize state with current values
        _name = State(initialValue: destination.name ?? "")
        _startDate = State(initialValue: destination.startDate ?? Date())
        _endDate = State(initialValue: destination.endDate ?? Date())
        _notes = State(initialValue: destination.notes ?? "")
        _color = State(initialValue: Color(hex: destination.wrappedColorHex) ?? .blue)
    }
    
    // MARK: - Body
    
    var body: some View {
        Form {
            // Basic Information
            Section(header: Text("Basic Information")) {
                TextField("Destination Name", text: $name)
                
                DatePicker("Start Date",
                         selection: $startDate,
                         displayedComponents: [.date])
                
                DatePicker("End Date",
                         selection: $endDate,
                         in: startDate...,
                         displayedComponents: [.date])
            }
            
            // Color Selection
            Section(header: Text("Color")) {
                ColorPicker("Destination Color", selection: $color)
            }
            
            // Notes
            Section(header: Text("Notes")) {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
            }
        }
        .navigationTitle("Edit Destination")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveDestination()
                }
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Methods
    
    /// Saves the edited destination
    private func saveDestination() {
        // Validate dates
        guard endDate >= startDate else {
            alertMessage = "End date must be after start date"
            showingAlert = true
            return
        }
        
        // Validate name
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Destination name is required"
            showingAlert = true
            return
        }
        
        // Update destination
        destination.name = name
        destination.startDate = startDate
        destination.endDate = endDate
        destination.notes = notes
        destination.colorHex = color.toHex()
        
        // Save context
        do {
            try viewContext.save()
            dismiss()
        } catch {
            alertMessage = "Failed to save destination: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

// Preview provider
struct EditDestinationView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let request: NSFetchRequest<TripDestination> = TripDestination.fetchRequest()
        let destinations = try? context.fetch(request)
        
        return NavigationView {
            if let firstDestination = destinations?.first {
                EditDestinationView(destination: firstDestination)
                    .environment(\.managedObjectContext, context)
            } else {
                Text("No preview data available")
            }
        }
    }
} 