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
    @State private var selectedExpense: Expense? = nil
    
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
        // Convert the FetchedResults to an Array to make it easier to work with
        let expensesArray = Array(expenses)
        
        // Apply filtering
        let filtered = expensesArray.filter { expense in
            let matchesSearch = matchesSearchCriteria(expense)
            let matchesFilter = matchesFilterOption(expense)
            return matchesSearch && matchesFilter
        }
        
        // Apply sorting
        return sortedExpenses(filtered)
    }
    
    // Simplified search matching
    private func matchesSearchCriteria(_ expense: Expense) -> Bool {
        // If search is empty, always match
        guard !searchText.isEmpty else { return true }
        
        // Get non-nil versions of optional strings with defaults
        let title = expense.title ?? ""
        let notes = expense.notes ?? ""
        let category = expense.category ?? ""
        
        // Check if any field contains the search text
        return title.localizedCaseInsensitiveContains(searchText) ||
               notes.localizedCaseInsensitiveContains(searchText) ||
               category.localizedCaseInsensitiveContains(searchText)
    }
    
    // Helper method to check if an expense matches the selected filter option
    private func matchesFilterOption(_ expense: Expense) -> Bool {
        switch filterOption {
        case "paid":
            return expense.paymentStatus == "paid"
        case "due":
            return expense.paymentStatus == "due"
        case "partial":
            return expense.paymentStatus == "partial"
        default:
            return true
        }
    }
    
    // Helper to sort expenses based on the current sort option
    private func sortedExpenses(_ expenses: [Expense]) -> [Expense] {
        var result = expenses
        
        switch sortOption {
        case "date-asc":
            result.sort { ($0.date ?? Date()) < ($1.date ?? Date()) }
        case "date-desc":
            result.sort { ($0.date ?? Date()) > ($1.date ?? Date()) }
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
            buildSummaryCards()
            
            // Search and filter controls
            buildSearchAndFilterControls()
            
            if expenses.isEmpty {
                buildEmptyStateView()
            } else {
                buildExpensesList()
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedExpense) { expense in
            EditExpenseView(expense: expense)
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(appViewModel)
        }
        .onChange(of: selectedExpense) { oldValue, newValue in
            // When selected expense is set to nil (sheet dismissed), refresh view
            if newValue == nil && oldValue != nil {
                // Force a refresh to ensure changes are reflected
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.refreshView()
                }
            }
        }
        .onAppear {
            // Register for expense data change notifications
            NotificationCenter.default.addObserver(
                forName: .expenseDataChanged,
                object: nil,
                queue: .main
            ) { _ in
                // Force an immediate refresh when expense data changes
                self.refreshView()
            }
        }
        .onDisappear {
            // Remove notification observer
            NotificationCenter.default.removeObserver(
                self,
                name: .expenseDataChanged,
                object: nil
            )
        }
    }
    
    // Helper method to refresh the view
    private func refreshView() {
        print("Refreshing ExpensesView...")
        
        // Create a UUID to track this specific refresh operation
        let refreshID = UUID()
        
        // Force context to process all changes
        viewContext.refreshAllObjects()
        
        // Schedule a series of state changes to force a thorough UI refresh
        DispatchQueue.main.async {
            print("Step 1: Initial refresh (\(refreshID))")
            
            // Save the original search text value
            let originalSearch = self.searchText
            
            // Toggle filter option instead of search text to avoid UI flicker
            let originalFilter = self.filterOption
            self.filterOption = "temp_filter_value"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                print("Step 2: Restore filter (\(refreshID))")
                self.filterOption = originalFilter
                
                // Change sort option to force another refresh
                let originalSort = self.sortOption
                self.sortOption = "temp_sort_value"
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    print("Step 3: Restore sort (\(refreshID))")
                    self.sortOption = originalSort
                    
                    // Ensure search text is restored to its original value 
                    self.searchText = originalSearch
                    
                    // Create one last state change
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        print("Step 4: Final refresh (\(refreshID))")
                        
                        // This line doesn't actually do anything but forces one last update
                        let _ = self.filteredExpenses.count
                    }
                }
            }
        }
    }
    
    // MARK: - View Builders
    
    @ViewBuilder
    private func buildSummaryCards() -> some View {
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
    }
    
    @ViewBuilder
    private func buildSearchAndFilterControls() -> some View {
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
    }
    
    @ViewBuilder
    private func buildEmptyStateView() -> some View {
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
    }
    
    @ViewBuilder
    private func buildExpensesList() -> some View {
        List {
            ForEach(filteredExpenses) { expense in
                ExpenseRow(expense: expense)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedExpense = expense
                    }
                    .id("expense-\(expense.id?.uuidString ?? "")-\(expense.amount)-\(expense.paymentStatus ?? "")-\(expense.title ?? "")-\(expense.category ?? "")-\(expense.date?.timeIntervalSince1970 ?? 0)-\(expense.currency ?? "")")
                    .contextMenu {
                        Button {
                            toggleExpenseStatus(expense)
                        } label: {
                            Label(
                                expense.paymentStatus == "paid" ? "Mark as Unpaid" : "Mark as Paid",
                                systemImage: expense.paymentStatus == "paid" ? "xmark.circle" : "checkmark.circle"
                            )
                        }
                        
                        Button {
                            selectedExpense = expense
                        } label: {
                            Label("Edit", systemImage: "pencil")
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
            
            // Post notification to refresh UI
            NotificationCenter.default.post(name: .expenseDataChanged, object: nil)
            
            // Also manually trigger a refresh
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.refreshView()
            }
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

/// View for editing an existing expense
struct EditExpenseView: View {
    // Environment for dismissing the sheet
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var viewContext
    @EnvironmentObject var appViewModel: AppViewModel
    
    // The expense to edit
    @ObservedObject var expense: Expense
    
    // Form fields
    @State private var title: String
    @State private var amount: String
    @State private var date: Date
    @State private var notes: String
    @State private var category: String
    @State private var paymentStatus: String
    @State private var currency: String
    
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
    
    // Initialize with existing expense values
    init(expense: Expense) {
        self.expense = expense
        
        // Initialize state variables with existing expense values
        _title = State(initialValue: expense.title ?? "")
        _amount = State(initialValue: String(format: "%.2f", expense.amount))
        _date = State(initialValue: expense.date ?? Date())
        _notes = State(initialValue: expense.notes ?? "")
        _category = State(initialValue: expense.category ?? "other")
        _paymentStatus = State(initialValue: expense.paymentStatus ?? "due")
        _currency = State(initialValue: expense.currency ?? "USD")
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
                }
                
                // Notes section
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Expense")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    updateExpense()
                }
                .disabled(title.isEmpty || Double(amount) == nil)
            )
        }
    }
    
    /// Save changes to the expense
    private func updateExpense() {
        // Keep track of original values to detect changes
        let originalTitle = expense.title
        let originalAmount = expense.amount
        let originalDate = expense.date
        let originalCategory = expense.category
        let originalStatus = expense.paymentStatus
        let originalCurrency = expense.currency
        
        // Update expense entity with form values
        expense.title = title
        
        // Convert amount string to double
        if let amountValue = Double(amount) {
            expense.amount = amountValue
        }
        
        expense.date = date
        expense.notes = notes
        expense.category = category
        expense.paymentStatus = paymentStatus
        expense.currency = currency
        
        // Save the context
        do {
            try viewContext.save()
            
            // Log changes for debugging
            print("Updated expense: \(title)")
            if originalTitle != title { print("Title changed: \(originalTitle ?? "") -> \(title)") }
            if originalAmount != expense.amount { print("Amount changed: \(originalAmount) -> \(expense.amount)") }
            if originalDate != expense.date { print("Date changed") }
            if originalCategory != expense.category { print("Category changed: \(originalCategory ?? "") -> \(expense.category ?? "")") }
            if originalStatus != expense.paymentStatus { print("Status changed: \(originalStatus ?? "") -> \(expense.paymentStatus ?? "")") }
            if originalCurrency != expense.currency { print("Currency changed: \(originalCurrency ?? "") -> \(expense.currency ?? "")") }
            
            // Post a notification to force refresh of expense views
            NotificationCenter.default.post(name: .expenseDataChanged, object: nil)
            
            // Ensure the view dismisses after saving changes
            DispatchQueue.main.async {
                self.presentationMode.wrappedValue.dismiss()
                
                // Force a more aggressive refresh by posting multiple notifications
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(name: .expenseDataChanged, object: nil)
                    
                    // Add one more notification for good measure
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        NotificationCenter.default.post(name: .expenseDataChanged, object: nil)
                    }
                }
            }
        } catch {
            let nsError = error as NSError
            print("Error updating expense: \(nsError)")
        }
    }
}

// Add a notification name for expense data changes
extension Notification.Name {
    static let expenseDataChanged = Notification.Name("expenseDataChanged")
} 