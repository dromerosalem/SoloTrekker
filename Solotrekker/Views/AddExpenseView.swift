// AddExpenseView.swift
// SoloTrekker
//
// Created on current date
//

import SwiftUI
import CoreData

/// View for adding a new expense to a trip
struct AddExpenseView: View {
    // Environment for dismissing the sheet
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var viewContext
    @EnvironmentObject var appViewModel: AppViewModel
    
    // Trip to add the expense to
    let trip: Trip
    
    // Form fields
    @State private var title = ""
    @State private var amount = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var category = "other"
    @State private var paymentStatus = "due"
    @State private var currency: String
    @State private var paidAmount = ""
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
    
    // Available expense categories
    let categories = [
        "accommodation": "Accommodation",
        "transport": "Transportation",
        "food": "Food & Dining",
        "activities": "Activities & Tours",
        "shopping": "Shopping",
        "other": "Other"
    ]
    
    // Payment status options
    let paymentStatusOptions = [
        "paid": "Paid",
        "due": "Due",
        "partial": "Partially Paid"
    ]
    
    // Input validation
    private var isFormValid: Bool {
        if !title.isEmpty && Double(amount) != nil {
            // Additional validation for partially paid expenses
            if paymentStatus == "partial" {
                if let paidValue = Double(paidAmount), let totalValue = Double(amount) {
                    return paidValue < totalValue && paidValue > 0
                } else {
                    return false
                }
            }
            return true
        }
        return false
    }
    
    // Returns true if the expense is partially paid
    private var isPartiallyPaid: Bool {
        paymentStatus == "partial"
    }
    
    // Computed property for the amount that is still due
    private var dueAmount: Double {
        let totalAmount = Double(amount) ?? 0
        let paid = Double(paidAmount) ?? 0
        return max(0, totalAmount - paid)
    }
    
    // Formatted representation of the due amount
    private var formattedDueAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        
        return formatter.string(from: NSNumber(value: dueAmount)) ?? "$\(dueAmount)"
    }
    
    // Initialize with trip and currency
    init(trip: Trip) {
        self.trip = trip
        _currency = State(initialValue: trip.currency ?? "USD")
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Basic expense information
                Section(header: Text("Expense Details")) {
                    TextField("Title", text: $title)
                    
                    HStack {
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                            .onChange(of: amount) { oldValue, newValue in
                                // When amount changes, update paid amount to be half of total by default
                                if isPartiallyPaid && paidAmount.isEmpty {
                                    if let totalValue = Double(newValue) {
                                        paidAmount = String(format: "%.2f", totalValue / 2)
                                    }
                                }
                            }
                        
                        Picker("Currency", selection: $currency) {
                            ForEach(appViewModel.currencyOptions, id: \.self) { currency in
                                Text(currency).tag(currency)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 100)
                    }
                    
                    DatePicker("Date", selection: $date, displayedComponents: [.date])
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories.keys.sorted(), id: \.self) { key in
                            Text(categories[key] ?? key).tag(key)
                        }
                    }
                    
                    Picker("Payment Status", selection: $paymentStatus) {
                        ForEach(paymentStatusOptions.keys.sorted(), id: \.self) { key in
                            Text(paymentStatusOptions[key] ?? key).tag(key)
                        }
                    }
                    .onChange(of: paymentStatus) { oldValue, newValue in
                        // Set initial paid amount to half of total when switching to partially paid
                        if newValue == "partial" && oldValue != "partial" {
                            if let totalValue = Double(amount) {
                                paidAmount = String(format: "%.2f", totalValue / 2)
                            }
                        }
                    }
                }
                
                // Partially paid details - only show if payment status is "partial"
                if isPartiallyPaid {
                    Section(header: Text("Partially Paid Details")) {
                        HStack {
                            TextField("Amount Paid", text: $paidAmount)
                                .keyboardType(.decimalPad)
                            
                            Text(currency)
                                .foregroundColor(.secondary)
                        }
                        
                        if !isFormValid && !paidAmount.isEmpty {
                            Text("Paid amount must be less than total and greater than zero")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        HStack {
                            Text("Amount Due: ")
                            Spacer()
                            Text(formattedDueAmount)
                                .foregroundColor(.orange)
                        }
                        
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date])
                    }
                }
                
                // Notes section
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveExpense()
                }
                .disabled(!isFormValid)
            )
        }
    }
    
    /// Save the new expense to CoreData
    private func saveExpense() {
        // Create a new expense entity
        let newExpense = Expense(context: viewContext)
        newExpense.id = UUID()
        newExpense.title = title
        
        // Convert amount string to double
        if let amountValue = Double(amount) {
            newExpense.amount = amountValue
        }
        
        newExpense.date = date
        newExpense.notes = notes
        newExpense.category = category
        newExpense.paymentStatus = paymentStatus
        newExpense.currency = currency
        newExpense.trip = trip
        
        // Handle partially paid status
        if paymentStatus == "partial" {
            if let paidValue = Double(paidAmount) {
                newExpense.paidAmount = paidValue
            }
            newExpense.dueDate = dueDate
        } else if paymentStatus == "paid" {
            // If marked as fully paid, set paid amount to total
            newExpense.paidAmount = newExpense.amount
            newExpense.dueDate = nil
        } else {
            // If marked as due, clear paid amount
            newExpense.paidAmount = 0
            newExpense.dueDate = nil
        }
        
        // Save the context
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            let nsError = error as NSError
            print("Error saving expense: \(nsError)")
        }
    }
}

extension AppViewModel {
    // Currency options
    var currencyOptions: [String] {
        ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "CNY"]
    }
}

// MARK: - Preview
struct AddExpenseView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let tripRequest: NSFetchRequest<Trip> = Trip.fetchRequest()
        let trips = try? context.fetch(tripRequest)
        
        return Group {
            if let firstTrip = trips?.first {
                AddExpenseView(trip: firstTrip)
                    .environment(\.managedObjectContext, context)
                    .environmentObject(AppViewModel())
            } else {
                Text("No preview data available")
            }
        }
    }
} 