// AddItineraryItemView.swift
// SoloTrekker
//
// Created on current date
//

import SwiftUI
import CoreData

/// View for adding a new itinerary item to a trip
struct AddItineraryItemView: View {
    // Environment for dismissing the sheet
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var viewContext
    @EnvironmentObject var appViewModel: AppViewModel
    
    // Trip and selected date
    let trip: Trip
    let selectedDate: Date
    
    // Form fields
    @State private var title = ""
    @State private var itemDescription = ""
    @State private var location = ""
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var itemType = "excursion"
    @State private var showTimeError = false // Track time validation errors
    
    // Available item types
    let itemTypes = [
        "accommodation": "Accommodation",
        "transport": "Transportation",
        "excursion": "Excursion",
        "food": "Food & Dining",
        "other": "Other"
    ]
    
    // Input validation
    private var isFormValid: Bool {
        return !title.isEmpty && isTimeValid
    }
    
    // Check if end time is after start time
    private var isTimeValid: Bool {
        return endTime > startTime
    }
    
    // Format times for error message
    private var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
    
    private var formattedEndTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: endTime)
    }
    
    // Initialize with trip and date
    init(trip: Trip, selectedDate: Date) {
        self.trip = trip
        self.selectedDate = selectedDate
        
        // Set default start time to 9 AM on the selected date
        let calendar = Calendar.current
        var startComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        startComponents.hour = 9
        startComponents.minute = 0
        
        // Set default end time to 10 AM on the selected date
        var endComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        endComponents.hour = 10
        endComponents.minute = 0
        
        // Initialize state variables
        _startTime = State(initialValue: calendar.date(from: startComponents) ?? selectedDate)
        _endTime = State(initialValue: calendar.date(from: endComponents) ?? selectedDate.addingTimeInterval(3600))
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic item information
                Section(header: Text("Activity Details")) {
                    TextField("Title", text: $title)
                    
                    Picker("Activity Type", selection: $itemType) {
                        ForEach(itemTypes.keys.sorted(), id: \.self) { key in
                            Text(itemTypes[key] ?? key).tag(key)
                        }
                    }
                    
                    TextField("Location", text: $location)
                    
                    TextEditor(text: $itemDescription)
                        .frame(minHeight: 80)
                }
                
                // Time section
                Section(header: Text("Time")) {
                    DatePicker("Start Time", selection: $startTime, displayedComponents: [.hourAndMinute])
                        .onChange(of: startTime) { oldValue, newValue in
                            // If end time is now before start time, update it
                            if endTime <= newValue {
                                // Set end time to 1 hour after new start time
                                endTime = newValue.addingTimeInterval(3600)
                            }
                            validateTimes()
                        }
                    
                    DatePicker("End Time", selection: $endTime, displayedComponents: [.hourAndMinute])
                        .onChange(of: endTime) { oldValue, newValue in
                            validateTimes()
                        }
                    
                    if showTimeError {
                        Text("End time must be after start time")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Activity")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveItem()
                }
                .disabled(!isFormValid)
            )
        }
    }
    
    /// Validate time inputs
    private func validateTimes() {
        showTimeError = !isTimeValid
    }
    
    /// Save the new itinerary item to CoreData
    private func saveItem() {
        // Ensure times are valid before saving
        guard isTimeValid else {
            showTimeError = true
            return
        }
        
        // Create a new itinerary item entity
        let newItem = ItineraryItem(context: viewContext)
        newItem.id = UUID()
        newItem.title = title
        newItem.itemDescription = itemDescription
        newItem.location = location
        
        // Combine selected date with the time components
        let calendar = Calendar.current
        
        // For startTime, use the date from selectedDate but time from startTime
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        var combinedStartComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        combinedStartComponents.hour = startComponents.hour
        combinedStartComponents.minute = startComponents.minute
        newItem.startTime = calendar.date(from: combinedStartComponents)
        
        // For endTime, use the date from selectedDate but time from endTime
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        var combinedEndComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        combinedEndComponents.hour = endComponents.hour
        combinedEndComponents.minute = endComponents.minute
        newItem.endTime = calendar.date(from: combinedEndComponents)
        
        newItem.type = itemType
        newItem.trip = trip
        
        // Save the context
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            let nsError = error as NSError
            print("Error saving itinerary item: \(nsError)")
        }
    }
}

// MARK: - Preview
struct AddItineraryItemView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let tripRequest: NSFetchRequest<Trip> = Trip.fetchRequest()
        let trips = try? context.fetch(tripRequest)
        
        return Group {
            if let firstTrip = trips?.first {
                AddItineraryItemView(trip: firstTrip, selectedDate: Date())
                    .environment(\.managedObjectContext, context)
            } else {
                Text("No preview data available")
            }
        }
    }
} 