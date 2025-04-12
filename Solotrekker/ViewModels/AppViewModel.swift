// AppViewModel.swift
// SoloTrekker
//
// Created on current date
//

import Foundation
import SwiftUI
import CoreData

/// Main view model for the app, handling application state and user preferences
class AppViewModel: ObservableObject {
    // App state properties
    @Published var selectedTab: Int = 0
    @Published var selectedTrip: Trip? = nil
    @Published var selectedDate: Date? = nil
    @Published var isAddingTrip: Bool = false
    @Published var isAddingItineraryItem: Bool = false
    @Published var isAddingExpense: Bool = false
    @Published var isAddingDocument: Bool = false
    @Published var documentPickerIsPresented: Bool = false
    
    // User preferences
    @Published var currency: String = UserDefaults.standard.string(forKey: "preferredCurrency") ?? "USD"
    @Published var colorScheme: ColorScheme = UserDefaults.standard.bool(forKey: "useDarkMode") ? .dark : .light
    
    // MARK: - App Navigation Methods
    
    /// Navigate to a specific trip
    /// - Parameter trip: The trip to navigate to
    func navigateToTrip(_ trip: Trip) {
        selectedTrip = trip
        selectedTab = 1 // Navigate to trip detail tab
    }
    
    /// Navigate to a specific date within a trip
    /// - Parameters:
    ///   - trip: The trip to navigate to
    ///   - date: The date to select
    func navigateToDate(in trip: Trip, date: Date) {
        selectedTrip = trip
        selectedDate = date
        selectedTab = 2 // Navigate to calendar tab
    }
    
    /// Reset navigation state
    func resetNavigation() {
        selectedTrip = nil
        selectedDate = nil
        selectedTab = 0 // Navigate to home tab
    }
    
    // MARK: - User Preferences
    
    /// Save the preferred currency
    /// - Parameter newCurrency: Currency code (e.g., "USD")
    func setPreferredCurrency(_ newCurrency: String) {
        currency = newCurrency
        UserDefaults.standard.set(newCurrency, forKey: "preferredCurrency")
    }
    
    /// Toggle between light and dark mode
    func toggleColorScheme() {
        colorScheme = colorScheme == .light ? .dark : .light
        UserDefaults.standard.set(colorScheme == .dark, forKey: "useDarkMode")
    }
    
    // MARK: - Helper Methods
    
    /// Get a color from a hex string
    /// - Parameter hex: Hex color code (e.g., "#FF0000")
    /// - Returns: SwiftUI Color
    func color(from hex: String?) -> Color {
        guard let hex = hex else { return .blue }
        
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return .blue
        }
        
        let red = Double((rgb & 0xFF0000) >> 16) / 255.0
        let green = Double((rgb & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgb & 0x0000FF) / 255.0
        
        return Color(red: red, green: green, blue: blue)
    }
    
    /// Format a currency amount
    /// - Parameters:
    ///   - amount: The amount to format
    ///   - currencyCode: Currency code (e.g., "USD")
    /// - Returns: Formatted string
    func formatCurrency(_ amount: Double, currencyCode: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
    
    /// Format a date
    /// - Parameters:
    ///   - date: The date to format
    ///   - style: Date format style
    /// - Returns: Formatted string
    func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        
        return formatter.string(from: date)
    }
    
    /// Get the day of the month from a date
    /// - Parameter date: The date
    /// - Returns: Day number as string
    func dayOfMonth(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        
        return formatter.string(from: date)
    }
    
    /// Get the month and year from a date
    /// - Parameter date: The date
    /// - Returns: "Month Year" string
    func monthAndYear(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        return formatter.string(from: date)
    }
    
    /// Check if a date is within a trip's range
    /// - Parameters:
    ///   - date: The date to check
    ///   - trip: The trip
    /// - Returns: True if the date is within the trip
    func isDateInTrip(_ date: Date, trip: Trip) -> Bool {
        guard let startDate = trip.startDate,
              let endDate = trip.endDate else {
            return false
        }
        
        let calendar = Calendar.current
        let dateOnly = calendar.startOfDay(for: date)
        let startOnly = calendar.startOfDay(for: startDate)
        let endOnly = calendar.startOfDay(for: endDate)
        
        return dateOnly >= startOnly && dateOnly <= endOnly
    }
    
    /// Get itinerary items for a specific date and trip
    /// - Parameters:
    ///   - date: The date
    ///   - trip: The trip
    ///   - context: The managed object context
    /// - Returns: Array of itinerary items
    func itineraryItems(for date: Date, in trip: Trip, context: NSManagedObjectContext) -> [ItineraryItem] {
        guard let items = trip.itineraryItems?.allObjects as? [ItineraryItem] else {
            return []
        }
        
        let calendar = Calendar.current
        return items.filter { item in
            calendar.isDate(calendar.startOfDay(for: item.startTime!), 
                           equalTo: calendar.startOfDay(for: date), 
                           toGranularity: .day)
        }.sorted { item1, item2 in
            item1.startTime! < item2.startTime!
        }
    }
} 