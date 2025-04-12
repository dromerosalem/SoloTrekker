// SettingsView.swift
// SoloTrekker
//
// Created on current date
//

import SwiftUI
import CoreData

/// Settings view for app preferences
struct SettingsView: View {
    // Access to managed object context and app view model
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appViewModel: AppViewModel
    
    // App settings
    @AppStorage("preferredCurrency") private var preferredCurrency = "USD"
    @AppStorage("useDarkMode") private var useDarkMode = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("distanceUnit") private var distanceUnit = "metric"
    
    // Trip statistics
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Trip.startDate, ascending: true)],
        animation: .default)
    private var trips: FetchedResults<Trip>
    
    // Computed properties for statistics
    private var tripCount: Int {
        trips.count
    }
    
    private var upcomingTripsCount: Int {
        let now = Date()
        return trips.filter { trip in
            guard let startDate = trip.startDate else { return false }
            return startDate > now
        }.count
    }
    
    private var totalTripDays: Int {
        var total = 0
        for trip in trips {
            guard let startDate = trip.startDate, let endDate = trip.endDate else { continue }
            let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
            total += days + 1 // +1 to include both start and end days
        }
        return total
    }
    
    private var totalBudget: Double {
        trips.reduce(0) { $0 + $1.budget }
    }
    
    var body: some View {
        Form {
            // App preferences section
            Section(header: Text("Preferences")) {
                Picker("Currency", selection: $preferredCurrency) {
                    ForEach(appViewModel.currencyOptions, id: \.self) { currency in
                        Text(currency).tag(currency)
                    }
                }
                .onChange(of: preferredCurrency) { oldValue, newValue in
                    appViewModel.setPreferredCurrency(newValue)
                }
                
                Picker("Distance Unit", selection: $distanceUnit) {
                    Text("Metric (km)").tag("metric")
                    Text("Imperial (mi)").tag("imperial")
                }
                
                Toggle("Dark Mode", isOn: $useDarkMode)
                    .onChange(of: useDarkMode) { oldValue, newValue in
                        appViewModel.colorScheme = newValue ? .dark : .light
                    }
                
                Toggle("Notifications", isOn: $notificationsEnabled)
            }
            
            // Trip statistics section
            Section(header: Text("Trip Statistics")) {
                StatRow(title: "Total Trips", value: "\(tripCount)")
                StatRow(title: "Upcoming Trips", value: "\(upcomingTripsCount)")
                StatRow(title: "Travel Days", value: "\(totalTripDays)")
                
                if totalBudget > 0 {
                    StatRow(title: "Total Budget", value: appViewModel.formatCurrency(totalBudget, currencyCode: preferredCurrency))
                }
            }
            
            // App information section
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                Button(action: {
                    // Contact support action (would send an email)
                    if let url = URL(string: "mailto:support@solotrekker.app") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Contact Support")
                }
                
                Button(action: {
                    // Privacy policy action (would open a web page)
                    if let url = URL(string: "https://www.solotrekker.app/privacy") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Privacy Policy")
                }
                
                Button(action: {
                    // Terms of service action (would open a web page)
                    if let url = URL(string: "https://www.solotrekker.app/terms") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Terms of Service")
                }
            }
            
            // Debug section (for testing)
            #if DEBUG
            Section(header: Text("Debug")) {
                Button(action: {
                    createSampleData()
                }) {
                    Text("Create Sample Data")
                }
                
                Button(action: {
                    clearAllData()
                }) {
                    Text("Clear All Data")
                        .foregroundColor(.red)
                }
            }
            #endif
        }
    }
    
    // MARK: - Debug Methods
    
    /// Create sample data for testing
    private func createSampleData() {
        // Add some sample trips if none exist
        if trips.isEmpty {
            let calendar = Calendar.current
            let now = Date()
            
            // Past trip
            let pastTrip = Trip(context: viewContext)
            pastTrip.id = UUID()
            pastTrip.title = "Barcelona Weekend"
            pastTrip.startDate = calendar.date(byAdding: .month, value: -1, to: now)
            pastTrip.endDate = calendar.date(byAdding: .day, value: 3, to: pastTrip.startDate!)
            pastTrip.destination = "Barcelona, Spain"
            pastTrip.notes = "Short weekend getaway to explore Barcelona's architecture and cuisine"
            pastTrip.budget = 800
            pastTrip.currency = "EUR"
            pastTrip.colorHex = "#FF9500"
            
            // Current trip
            let currentTrip = Trip(context: viewContext)
            currentTrip.id = UUID()
            currentTrip.title = "Thailand Adventure"
            currentTrip.startDate = calendar.date(byAdding: .day, value: -3, to: now)
            currentTrip.endDate = calendar.date(byAdding: .day, value: 7, to: now)
            currentTrip.destination = "Bangkok, Thailand"
            currentTrip.notes = "Exploring temples, street food, and islands"
            currentTrip.budget = 1500
            currentTrip.currency = "USD"
            currentTrip.colorHex = "#5856D6"
            
            // Future trip
            let futureTrip = Trip(context: viewContext)
            futureTrip.id = UUID()
            futureTrip.title = "New Zealand Trek"
            futureTrip.startDate = calendar.date(byAdding: .month, value: 2, to: now)
            futureTrip.endDate = calendar.date(byAdding: .day, value: 14, to: futureTrip.startDate!)
            futureTrip.destination = "Auckland, New Zealand"
            futureTrip.notes = "Hiking, nature photography, and adventure sports"
            futureTrip.budget = 3000
            futureTrip.currency = "USD"
            futureTrip.colorHex = "#34C759"
            
            // Save the context
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error creating sample data: \(nsError)")
            }
        }
    }
    
    /// Clear all data for testing
    private func clearAllData() {
        // Delete all trips (will cascade delete related entities)
        for trip in trips {
            viewContext.delete(trip)
        }
        
        // Save the context
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Error clearing data: \(nsError)")
        }
    }
}

/// Row for displaying a statistic
struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.teal)
        }
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AppViewModel())
    }
} 