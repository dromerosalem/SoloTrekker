// ExpensesView.swift
// SoloTrekker
//
// Created on current date
//

import SwiftUI
import CoreData

/// View for displaying and managing trip expenses
struct ExpensesView: View {
    // Trip to display expenses for
    let trip: Trip
    
    // Access to managed object context and app view model
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appViewModel: AppViewModel
    
    // Fetch expenses from CoreData
    @FetchRequest private var expenses: FetchedResults<Expense>
    
    // State for filtering and sorting
    @State private var searchText = ""
    @State private var sortOption = "date-desc"
    @State private var filterOption = "all"
    
    // Initialize with trip and fetch request
    init(trip: Trip) {
        self.trip = trip
        
        // Create a predicate to filter expenses by trip
        let predicate = NSPredicate(format: "trip == %@", trip)
        
        // Create a fetch request with sorting
        _expenses = FetchRequest<Expense>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Expense.date, ascending: false)
            ],
            predicate: predicate,
            animation: .default
        )
    }
    
    // Computed properties for totals
    private var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    private var paidExpenses: Double {
        expenses.filter { $0.paymentStatus == "paid" }.reduce(0) { $0 + $1.amount }
    }
    
    private var dueExpenses: Double {
        expenses.filter { $0.paymentStatus == "due" }.reduce(0) { $0 + $1.amount }
    }
    
    private var partiallyPaidExpenses: Double {
        expenses.filter { $0.paymentStatus == "partial" }.reduce(0) { $0 + $1.amount }
    }
    
    // Computed property for filtered and sorted expenses
    private var filteredExpenses: [Expense] {
        // Filter by search text and status
        var result = expenses.filter { expense in
            let matchesSearch = searchText.isEmpty || 
                (expense.title?.localizedCaseInsensitiveContains(searchText) == true) ||
                (expense.notes?.localizedCaseInsensitiveContains(searchText) == true) ||
                (expense.category?.localizedCaseInsensitiveContains(searchText) == true)
            
            let matchesFilter: Bool
            switch filterOption {
            case "paid":
                matchesFilter = expense.paymentStatus == "paid"
            case "due":
                matchesFilter = expense.paymentStatus == "due"
            case "partial":
                matchesFilter = expense.paymentStatus == "partial"
            default:
                matchesFilter = true
            }
            
            return matchesSearch && matchesFilter
        }
        
        // Sort the result
        switch sortOption {
        case "date-asc":
            result.sort { $0.date ?? Date() < $1.date ?? Date() }
        case "date-desc":
            result.sort { $0.date ?? Date() > $1.date ?? Date() }
        case "amount-asc":
            result.sort { $0.amount < $1.amount }
        case "amount-desc":
            result.sort { $0.amount > $1.amount }
        case "title-asc":
            result.sort { ($0.title ?? "") < ($1.title ?? "") }
        default:
            break // Already sorted by date in fetch request
        }
        
        return result
    }
    
    // Category pie chart data
    private var expensesByCategory: [String: Double] {
        var result: [String: Double] = [:]
        
        for expense in expenses {
            let category = expense.category ?? "Uncategorized"
            result[category, default: 0] += expense.amount
        }
        
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Summary cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Total budget card
                    SummaryCard(
                        title: "Budget",
                        value: appViewModel.formatCurrency(trip.budget, currencyCode: trip.currency ?? "USD"),
                        icon: "dollarsign.circle.fill",
                        color: .blue
                    )
                    
                    // Total expenses card
                    SummaryCard(
                        title: "Total Expenses",
                        value: appViewModel.formatCurrency(totalExpenses, currencyCode: trip.currency ?? "USD"),
                        icon: "creditcard.fill",
                        color: totalExpenses > trip.budget ? .red : .green
                    )
                    
                    // Paid expenses card
                    SummaryCard(
                        title: "Paid",
                        value: appViewModel.formatCurrency(paidExpenses, currencyCode: trip.currency ?? "USD"),
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                    
                    // Due expenses card
                    SummaryCard(
                        title: "Due",
                        value: appViewModel.formatCurrency(dueExpenses, currencyCode: trip.currency ?? "USD"),
                        icon: "exclamationmark.circle.fill",
                        color: .orange
                    )
                }
                .padding()
            }
            
            // Search and filter controls
            VStack(spacing: 8) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search expenses...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Filter and sort controls
                HStack {
                    // Filter by status
                    Picker("Filter", selection: $filterOption) {
                        Text("All").tag("all")
                        Text("Paid").tag("paid")
                        Text("Due").tag("due")
                        Text("Partial").tag("partial")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Spacer()
                    
                    // Sort menu
                    Menu {
                        Button("Date (Newest)", action: { sortOption = "date-desc" })
                        Button("Date (Oldest)", action: { sortOption = "date-asc" })
                        Button("Amount (Highest)", action: { sortOption = "amount-desc" })
                        Button("Amount (Lowest)", action: { sortOption = "amount-asc" })
                        Button("Title (A-Z)", action: { sortOption = "title-asc" })
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
            .padding(.horizontal)
            
            if expenses.isEmpty {
                // Empty state
                VStack(spacing: 20) {
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 80))
                        .foregroundColor(.teal)
                    
                    Text("No Expenses Yet")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Tap the + button to add your first expense for this trip")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Button(action: {
                        appViewModel.isAddingExpense = true
                    }) {
                        Text("Add Your First Expense")
                            .fontWeight(.semibold)
                            .padding()
                            .background(Color.teal)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Expense list
                List {
                    ForEach(filteredExpenses) { expense in
                        ExpenseRow(expense: expense)
                            .contextMenu {
                                Button {
                                    toggleExpenseStatus(expense)
                                } label: {
                                    Label(
                                        expense.paymentStatus == "paid" ? "Mark as Unpaid" : "Mark as Paid",
                                        systemImage: expense.paymentStatus == "paid" ? "xmark.circle" : "checkmark.circle"
                                    )
                                }
                                
                                Button(role: .destructive) {
                                    deleteExpense(expense)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    .onDelete(perform: deleteExpenses)
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    /// Delete an expense
    /// - Parameter expense: The expense to delete
    private func deleteExpense(_ expense: Expense) {
        withAnimation {
            viewContext.delete(expense)
            saveContext()
        }
    }
    
    /// Delete expenses at the specified offsets
    /// - Parameter offsets: IndexSet of the expenses to delete
    private func deleteExpenses(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredExpenses[$0] }.forEach(viewContext.delete)
            saveContext()
        }
    }
    
    /// Toggle the payment status of an expense
    /// - Parameter expense: The expense to update
    private func toggleExpenseStatus(_ expense: Expense) {
        withAnimation {
            if expense.paymentStatus == "paid" {
                expense.paymentStatus = "due"
            } else {
                expense.paymentStatus = "paid"
            }
            saveContext()
        }
    }
    
    /// Save the context and handle errors
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Error saving context: \(nsError)")
        }
    }
}

/// Card view for expense summary
struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding()
        .frame(width: 150, height: 100)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

/// Row displaying a single expense
struct ExpenseRow: View {
    let expense: Expense
    @EnvironmentObject var appViewModel: AppViewModel
    
    // Get icon based on expense category
    private var categoryIcon: String {
        switch expense.category {
        case "accommodation":
            return "bed.double.fill"
        case "transport":
            return "airplane"
        case "food":
            return "fork.knife"
        case "activities":
            return "figure.hiking"
        case "shopping":
            return "bag.fill"
        default:
            return "creditcard.fill"
        }
    }
    
    // Get color based on payment status
    private var statusColor: Color {
        switch expense.paymentStatus {
        case "paid":
            return .green
        case "due":
            return .orange
        case "partial":
            return .blue
        default:
            return .gray
        }
    }
    
    // Format date
    private var formattedDate: String {
        guard let date = expense.date else { return "No date" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // Category icon
            Image(systemName: categoryIcon)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Color.teal)
                .cornerRadius(8)
            
            // Expense details
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title ?? "Untitled")
                    .font(.headline)
                
                HStack {
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let category = expense.category, !category.isEmpty {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(category.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let notes = expense.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Amount and status
            VStack(alignment: .trailing, spacing: 4) {
                Text(appViewModel.formatCurrency(expense.amount, currencyCode: expense.currency ?? "USD"))
                    .font(.headline)
                
                Text(expense.paymentStatus?.capitalized ?? "Due")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview
struct ExpensesView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let tripRequest: NSFetchRequest<Trip> = Trip.fetchRequest()
        let trips = try? context.fetch(tripRequest)
        
        return Group {
            if let firstTrip = trips?.first {
                ExpensesView(trip: firstTrip)
                    .environment(\.managedObjectContext, context)
                    .environmentObject(AppViewModel())
            } else {
                Text("No preview data available")
            }
        }
    }
} 