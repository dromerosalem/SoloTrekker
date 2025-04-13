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
        .padding(.vertical, 8)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let expense = Expense(context: context)
    expense.title = "Hotel Booking"
    expense.amount = 149.99
    expense.currency = "USD"
    expense.date = Date()
    expense.category = "accommodation"
    expense.paymentStatus = "due"
    expense.notes = "Refundable until 24h before check-in"
    
    return List {
        ExpenseRow(expense: expense)
            .environmentObject(AppViewModel())
    }
} 