// EditTripView.swift
// SoloTrekker
//
// Created on current date
//

import SwiftUI
import CoreData

/// View for editing an existing trip
struct EditTripView: View {
    // Environment for dismissing the sheet
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var viewContext
    @EnvironmentObject var appViewModel: AppViewModel
    
    // The trip being edited
    let trip: Trip
    
    // Form fields
    @State private var title: String
    @State private var destination: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var notes: String
    @State private var budget: String
    @State private var currency: String
    @State private var selectedColor: String
    
    // Constants
    private let maxTitleLength = 50
    private let maxDestinationLength = 50
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
    
    // Currency options
    let currencyOptions = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CNY"]
    
    // Input validation
    private var isFormValid: Bool {
        !title.isEmpty && !destination.isEmpty && startDate <= endDate
    }
    
    // Initialize with trip data
    init(trip: Trip) {
        self.trip = trip
        
        // Initialize state variables with trip values
        _title = State(initialValue: trip.title ?? "")
        _destination = State(initialValue: trip.destination ?? "")
        _startDate = State(initialValue: trip.startDate ?? Date())
        _endDate = State(initialValue: trip.endDate ?? Date().addingTimeInterval(86400 * 7))
        _notes = State(initialValue: trip.notes ?? "")
        _budget = State(initialValue: String(format: "%.2f", trip.budget))
        _currency = State(initialValue: trip.currency ?? "USD")
        _selectedColor = State(initialValue: trip.colorHex ?? "#4A90E2")
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("Trip Details").font(.headline)
                        
                        Text("Title")
                        TextField("Trip Title", text: $title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.bottom, 10)
                        
                        Text("Destination")
                        TextField("Destination", text: $destination)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.bottom, 10)
                        
                        Text("Start Date")
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .labelsHidden()
                            .padding(.bottom, 10)
                        
                        Text("End Date")
                        DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                            .labelsHidden()
                            .padding(.bottom, 10)
                    }
                    
                    Group {
                        Text("Budget").font(.headline).padding(.top, 10)
                        
                        HStack {
                            TextField("Amount", text: $budget)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                            
                            Picker("", selection: $currency) {
                                ForEach(currencyOptions, id: \.self) { currencyOption in
                                    Text(currencyOption).tag(currencyOption)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 100)
                        }
                        .padding(.bottom, 10)
                    }
                    
                    Group {
                        Text("Trip Color").font(.headline).padding(.top, 10)
                        
                        HStack(spacing: 10) {
                            ForEach(colorOptions, id: \.hex) { color in
                                Button {
                                    selectedColor = color.hex
                                } label: {
                                    Circle()
                                        .fill(appViewModel.color(from: color.hex))
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
                        
                        Text("Add notes about your trip (optional)")
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
                    Button(action: saveChanges) {
                        Text("Save Changes")
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
            .navigationTitle("Edit Trip")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismissView()
                }
            )
            .onChange(of: title) { _, newValue in
                if newValue.count > maxTitleLength {
                    title = String(newValue.prefix(maxTitleLength))
                }
            }
            .onChange(of: destination) { _, newValue in
                if newValue.count > maxDestinationLength {
                    destination = String(newValue.prefix(maxDestinationLength))
                }
            }
            .onChange(of: budget) { _, newValue in
                validateBudget(newValue)
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
    }
    
    /// Validate and sanitize budget input
    private func validateBudget(_ value: String) {
        // Allow only numbers and a single decimal point
        let filtered = value.filter { "0123456789.".contains($0) }
        
        if filtered.filter({ $0 == "." }).count > 1,
           let firstDecimal = filtered.firstIndex(of: ".") {
            var corrected = filtered
            corrected.remove(at: firstDecimal)
            budget = String(corrected.filter { $0 != "." })
        } else if filtered != value {
            budget = filtered
        }
    }
    
    /// Dismiss the view
    private func dismissView() {
        hideKeyboard()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    /// Save changes to the trip
    private func saveChanges() {
        hideKeyboard()
        
        // Update trip properties
        trip.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        trip.destination = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        trip.startDate = startDate
        trip.endDate = endDate
        trip.notes = notes
        trip.colorHex = selectedColor
        trip.currency = currency
        
        // Update budget
        if let budgetValue = Double(budget), budgetValue >= 0 {
            trip.budget = budgetValue
        }
        
        // Save context
        do {
            try viewContext.save()
            dismissView()
        } catch {
            print("Error saving trip changes: \(error as NSError)")
        }
    }
    
    /// Hide the keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// Helper for SwiftUI preview
struct EditTripView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let tripRequest: NSFetchRequest<Trip> = Trip.fetchRequest()
        let trips = try? context.fetch(tripRequest)
        
        return Group {
            if let firstTrip = trips?.first {
                EditTripView(trip: firstTrip)
                    .environment(\.managedObjectContext, context)
                    .environmentObject(AppViewModel())
            } else {
                Text("No preview data available")
            }
        }
    }
} 