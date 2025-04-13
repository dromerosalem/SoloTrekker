// AddDestinationView.swift
// SoloTrekker
//
// Created on current date
//

import SwiftUI
import CoreData

/// View for adding a new destination to a trip
struct AddDestinationView: View {
    // Environment
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var viewContext
    @EnvironmentObject var appViewModel: AppViewModel
    
    // Trip to add destination to
    let trip: Trip
    
    // Form state
    @State private var name = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var notes = ""
    @State private var selectedColor = "#4A90E2"  // Default blue color
    
    // Constants
    private let maxNameLength = 50
    private let maxNotesLength = 500
    
    // Color options
    let colorOptions = [
        (hex: "#4A90E2", name: "Blue"),
        (hex: "#50E3C2", name: "Teal"),
        (hex: "#FF9500", name: "Orange"),
        (hex: "#FF3B30", name: "Red"),
        (hex: "#5856D6", name: "Purple"),
        (hex: "#34C759", name: "Green"),
        (hex: "#FF2D55", name: "Pink"),
        (hex: "#FFCC00", name: "Yellow")
    ]
    
    // Input validation
    private var isFormValid: Bool {
        !name.isEmpty && startDate <= endDate
    }
    
    // Break down complex expression
    private var tripStartDate: Date {
        return trip.startDate ?? Date()
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("Destination Details").font(.headline)
                    
                    Text("Name")
                    TextField("Destination Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.bottom, 10)
                    
                    Text("Start Date")
                    DatePicker("", selection: $startDate, in: tripStartDate..., displayedComponents: .date)
                        .labelsHidden()
                        .padding(.bottom, 10)
                    
                    Text("End Date")
                    DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                        .labelsHidden()
                        .padding(.bottom, 10)
                }
                
                Group {
                    Text("Color").font(.headline).padding(.top, 10)
                    
                    HStack(spacing: 10) {
                        ForEach(colorOptions, id: \.hex) { color in
                            Button {
                                selectedColor = color.hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: color.hex) ?? .blue)
                                    .frame(width: 35, height: 35)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color.hex ? Color.white : Color.clear, lineWidth: 2)
                                            .padding(3)
                                    )
                                    .background(
                                        Circle()
                                            .fill(selectedColor == color.hex ? Color.gray.opacity(0.3) : Color.clear)
                                            .frame(width: 41, height: 41)
                                    )
                            }
                        }
                    }
                    .padding(.bottom, 10)
                }
                
                Group {
                    Text("Notes").font(.headline).padding(.top, 10)
                    
                    Text("Add notes about this destination (optional)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                        )
                        .padding(.bottom, 10)
                }
                
                // Save button
                Button(action: saveDestination) {
                    Text("Add Destination")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.teal : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!isFormValid)
                .padding(.top, 10)
            }
            .padding()
        }
        .navigationTitle("Add Destination")
        .navigationBarItems(
            leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
        )
        .onChange(of: name) { _, newValue in
            if newValue.count > maxNameLength {
                name = String(newValue.prefix(maxNameLength))
            }
        }
        .onChange(of: notes) { _, newValue in
            if newValue.count > maxNotesLength {
                notes = String(newValue.prefix(maxNotesLength))
            }
        }
        // Add tap gesture to dismiss keyboard
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    /// Save the new destination
    private func saveDestination() {
        hideKeyboard()
        
        // Create new destination
        let destination = TripDestination(context: viewContext)
        destination.id = UUID()
        destination.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        destination.startDate = startDate
        destination.endDate = endDate
        destination.notes = notes
        destination.colorHex = selectedColor
        destination.trip = trip
        
        // Save context
        do {
            try viewContext.save()
            
            // Update the selected view/tab to go to calendar after adding destination
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                appViewModel.selectedTab = 1  // Calendar tab
                NotificationCenter.default.post(name: Notification.Name("DestinationAdded"), object: nil)
            }
            
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving destination: \(error)")
        }
    }
    
    /// Hide the keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

/// Preview provider
struct AddDestinationView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let request: NSFetchRequest<Trip> = Trip.fetchRequest()
        let trips = try? context.fetch(request)
        
        return NavigationView {
            if let firstTrip = trips?.first {
                AddDestinationView(trip: firstTrip)
                    .environment(\.managedObjectContext, context)
                    .environmentObject(AppViewModel())
            } else {
                Text("No preview data available")
            }
        }
    }
} 