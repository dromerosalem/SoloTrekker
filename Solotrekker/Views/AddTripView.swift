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
    @State private var startDate = Calendar.current.startOfDay(for: Date())
    @State private var endDate = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400 * 7))
    @State private var notes = ""
    @State private var budget: String = ""
    @State private var currency = "USD"
    @State private var selectedColor = "#4A90E2" // Default blue
    
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
                    Button(action: saveAndContinue) {
                        Text("Save Trip")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.blue : Color.gray)
                            .cornerRadius(10)
                    }
                    .disabled(!isFormValid)
                    .padding(.top, 10)
                }
                .padding()
            }
            .navigationTitle("New Trip")
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
    
    /// Save trip and navigate to it
    private func saveAndContinue() {
        hideKeyboard()
        
        let newTrip = Trip(context: viewContext)
        newTrip.id = UUID()
        newTrip.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        newTrip.destination = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        newTrip.startDate = startDate
        newTrip.endDate = endDate
        newTrip.notes = notes
        newTrip.colorHex = selectedColor
        newTrip.currency = currency
        
        // Set budget
        if let budgetValue = Double(budget), budgetValue >= 0 {
            newTrip.budget = budgetValue
        } else {
            newTrip.budget = 0
        }
        
        // Save context
        do {
            try viewContext.save()
            
            dismissView()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                appViewModel.selectedTrip = newTrip
                appViewModel.selectedDate = startDate
                appViewModel.selectedTab = 1
            }
        } catch {
            print("Error saving trip: \(error as NSError)")
        }
    }
    
    /// Hide the keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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