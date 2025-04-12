// AddTripView.swift
// SoloTrekker
//
// Created on current date
//

import SwiftUI
import CoreData

/// View for creating a new trip
struct AddTripView: View {
    // Environment for dismissing the sheet
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var viewContext
    @EnvironmentObject var appViewModel: AppViewModel
    
    // Form fields
    @State private var title = ""
    @State private var destination = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 7) // Default to 7 days
    @State private var notes = ""
    @State private var budget: String = ""
    @State private var currency = "USD"
    @State private var selectedColor = "#4A90E2" // Default blue
    
    // Available color options
    let colorOptions = [
        "#4A90E2", // Blue
        "#50E3C2", // Teal
        "#FF9500", // Orange
        "#FF3B30", // Red
        "#5856D6", // Purple
        "#34C759", // Green
        "#FF2D55", // Pink
        "#FFCC00"  // Yellow
    ]
    
    // Currency options
    let currencyOptions = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CNY"]
    
    // Input validation
    private var isFormValid: Bool {
        !title.isEmpty && 
        !destination.isEmpty && 
        startDate <= endDate
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic trip information
                Section(header: Text("Trip Details")) {
                    TextField("Trip Title", text: $title)
                    TextField("Destination", text: $destination)
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
                
                // Budget section
                Section(header: Text("Budget")) {
                    HStack {
                        TextField("Budget Amount", text: $budget)
                            .keyboardType(.decimalPad)
                        
                        Picker("Currency", selection: $currency) {
                            ForEach(currencyOptions, id: \.self) { currency in
                                Text(currency).tag(currency)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 100)
                    }
                }
                
                // Color section
                Section(header: Text("Trip Color")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 10) {
                        ForEach(colorOptions, id: \.self) { colorHex in
                            Circle()
                                .fill(appViewModel.color(from: colorHex))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: colorHex == selectedColor ? 2 : 0)
                                        .padding(2)
                                )
                                .onTapGesture {
                                    selectedColor = colorHex
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Notes section
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("New Trip")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveTrip()
                }
                .disabled(!isFormValid)
            )
        }
    }
    
    /// Save the new trip to CoreData
    private func saveTrip() {
        // Create a new trip entity
        let newTrip = Trip(context: viewContext)
        newTrip.id = UUID()
        newTrip.title = title
        newTrip.destination = destination
        newTrip.startDate = startDate
        newTrip.endDate = endDate
        newTrip.notes = notes
        newTrip.colorHex = selectedColor
        newTrip.currency = currency
        
        // Convert budget string to double if possible
        if let budgetValue = Double(budget) {
            newTrip.budget = budgetValue
        }
        
        // Save the context
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
            
            // Automatically navigate to the new trip
            appViewModel.selectedTrip = newTrip
            appViewModel.selectedTab = 1
        } catch {
            let nsError = error as NSError
            print("Error saving trip: \(nsError)")
        }
    }
}

// MARK: - Preview
struct AddTripView_Previews: PreviewProvider {
    static var previews: some View {
        AddTripView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AppViewModel())
    }
} 