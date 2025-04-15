// ExpenseRow.swift
// SoloTrekker
//
// Created on current date
//

import SwiftUI

/// A row component that displays a single expense item
struct ExpenseRow: View {
    // Environment objects
    @EnvironmentObject var appViewModel: AppViewModel
    
    // The expense to display
    let expense: Expense
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Category icon
                Image(systemName: expense.iconName())
                    .font(.system(size: 24))
                    .foregroundColor(.accentColor)
                    .frame(width: 40, height: 40)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Circle())
                
                // Expense details
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.wrappedTitle)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack {
                        // Display category
                        Text(expense.displayCategory())
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Payment status indicator
                        Text(expense.displayPaymentStatus())
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(expense.statusColor().opacity(0.2))
                            .foregroundColor(expense.statusColor())
                            .cornerRadius(4)
                    }
                    
                    // Date and optional notes
                    if let notes = expense.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Text(expense.formattedDate())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Amount
                Text(expense.formattedAmount)
                    .font(.headline)
                    .foregroundColor(expense.isDue ? .red : .primary)
            }
            
            // Show partially paid information if expense is partially paid
            if expense.isPartiallyPaid {
                VStack(alignment: .trailing, spacing: 4) {
                    Divider()
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Text("Paid: \(expense.formattedPaidAmount)")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        
                        Text("Due: \(expense.formattedDueAmount)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
             
                    if expense.dueDate != nil {
                        HStack {
                            Spacer()
                            
                            Image(systemName: "calendar")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text("Due date: \(expense.formattedDueDate)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.leading, 52) // Align with main content, accounting for the icon width
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    // Create a standard expense
    let expense1 = Expense(context: context)
    expense1.title = "Hotel Booking"
    expense1.amount = 149.99
    expense1.currency = "USD"
    expense1.date = Date()
    expense1.category = "accommodation"
    expense1.paymentStatus = "due"
    expense1.notes = "Refundable until 24h before check-in"
    
    // Create a partially paid expense
    let expense2 = Expense(context: context)
    expense2.title = "Flight Tickets"
    expense2.amount = 299.99
    expense2.paidAmount = 99.99
    expense2.currency = "EUR"
    expense2.date = Date()
    expense2.dueDate = Calendar.current.date(byAdding: .day, value: 14, to: Date())
    expense2.category = "transport"
    expense2.paymentStatus = "partial"
    expense2.notes = "Economy class, one checked bag"
    
    return List {
        ExpenseRow(expense: expense1)
            .environmentObject(AppViewModel())
        
        ExpenseRow(expense: expense2)
            .environmentObject(AppViewModel())
    }
} 
