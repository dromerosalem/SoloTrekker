// HomeView.swift
// SoloTrekker
//
// Created on current date
//

import SwiftUI
import CoreData
import UIKit

/// Home view displaying a list of trips
struct HomeView: View {
    // Access to managed object context and app view model
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appViewModel: AppViewModel
    
    // Fetch trips from CoreData
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Trip.startDate, ascending: true)],
        animation: .default)
    private var trips: FetchedResults<Trip>
    
    // State for search functionality
    @State private var searchText = ""
    
    // Filtered trips based on search text
    var filteredTrips: [Trip] {
        if searchText.isEmpty {
            return Array(trips)
        } else {
            return trips.filter { trip in
                trip.title?.localizedCaseInsensitiveContains(searchText) == true ||
                trip.destination?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background color
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search trips...", text: $searchText)
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
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 8)
                
                // Content based on whether there are trips
                if trips.isEmpty {
                    emptyStateView
                } else {
                    tripListView
                }
            }
        }
    }
    
    // Empty state when no trips exist
    var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "airplane.circle")
                .font(.system(size: 80))
                .foregroundColor(.teal)
            
            Text("No Trips Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Tap the + button to add your first solo adventure!")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: {
                appViewModel.isAddingTrip = true
            }) {
                Text("Add Your First Trip")
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
    
    // List of trips
    var tripListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Ensure each trip has a clear ID association
                ForEach(filteredTrips, id: \.id) { trip in
                    Button(action: {
                        // Use direct navigation method instead of gesture
                        print("Trip selected: \(trip.title ?? "Untitled")")
                        appViewModel.selectedTrip = trip
                        if let startDate = trip.startDate {
                            appViewModel.selectedDate = startDate
                        }
                        // Set tab index directly rather than through view model
                        // to reduce potential state conflicts
                        DispatchQueue.main.async {
                            appViewModel.selectedTab = 1
                        }
                    }) {
                        TripCard(trip: trip)
                            .id(trip.id?.uuidString ?? UUID().uuidString)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    /// Delete trips at the specified offsets
    /// - Parameter offsets: IndexSet of the trips to delete
    private func deleteTrips(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredTrips[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error deleting trips: \(nsError)")
            }
        }
    }
}

/// Card view for a single trip
struct TripCard: View {
    // Trip to display
    let trip: Trip
    
    // App view model for helper methods
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with title and dates
            tripHeader
            
            // Progress bar and status
            if let startDate = trip.startDate, let endDate = trip.endDate {
                tripProgress(startDate: startDate, endDate: endDate)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // Trip header with title, destination, and dates
    var tripHeader: some View {
        HStack {
            // Title and destination
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.title ?? "Untitled Trip")
                    .font(.title3)
                    .fontWeight(.bold)
                
                if let destination = trip.destination, !destination.isEmpty {
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                        Text(destination)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Trip dates
            if let startDate = trip.startDate, let endDate = trip.endDate {
                tripDateInfo(startDate: startDate, endDate: endDate)
            }
        }
    }
    
    // Trip dates information
    func tripDateInfo(startDate: Date, endDate: Date) -> some View {
        let calendar = Calendar.current
        // Ensure we have a valid date difference calculation
        let numberOfDays = max(0, calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0)
        
        return VStack(alignment: .trailing, spacing: 2) {
            Text("\(numberOfDays + 1) days")
                .font(.headline)
            
            // Show trip dates in a more detailed format
            Text(appViewModel.formatDate(startDate, style: .short))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // Trip progress indicator
    func tripProgress(startDate: Date, endDate: Date) -> some View {
        let now = Date()
        let progressValue = calculateProgress(startDate: startDate, endDate: endDate, currentDate: now)
        let status = getTripStatus(startDate: startDate, endDate: endDate, currentDate: now)
        
        return VStack(alignment: .leading, spacing: 8) {
            // Add start and end date information
            HStack {
                Text("From: \(appViewModel.formatDate(startDate, style: .medium))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("To: \(appViewModel.formatDate(endDate, style: .medium))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progressValue)
                .progressViewStyle(LinearProgressViewStyle(tint: appViewModel.color(from: trip.colorHex)))
            
            HStack {
                // Status badge
                StatusBadge(status: status)
                
                Spacer()
                
                // Budget info if available - ensure non-negative values
                if trip.budget > 0 {
                    Text(appViewModel.formatCurrency(max(0, trip.budget), currencyCode: trip.currency ?? "USD"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // Calculate progress for the trip timeline
    func calculateProgress(startDate: Date, endDate: Date, currentDate: Date) -> Double {
        if currentDate < startDate {
            return 0
        }
        
        if currentDate > endDate {
            return 1
        }
        
        let totalDuration = endDate.timeIntervalSince(startDate)
        // Guard against zero or negative duration to prevent NaN or invalid values
        guard totalDuration > 0 else { return 0 }
        
        let elapsedDuration = currentDate.timeIntervalSince(startDate)
        let progress = elapsedDuration / totalDuration
        
        // Ensure the progress value is between 0 and 1 to prevent NaN
        return max(0, min(1, progress))
    }
    
    // Get the trip status based on dates
    func getTripStatus(startDate: Date, endDate: Date, currentDate: Date) -> TripStatus {
        if currentDate < startDate {
            return .upcoming
        } else if currentDate > endDate {
            return .completed
        } else {
            return .inProgress
        }
    }
}

/// Trip status enumeration
enum TripStatus {
    case upcoming
    case inProgress
    case completed
    
    var color: Color {
        switch self {
        case .upcoming:
            return .orange
        case .inProgress:
            return .green
        case .completed:
            return .gray
        }
    }
    
    var label: String {
        switch self {
        case .upcoming:
            return "Upcoming"
        case .inProgress:
            return "In Progress"
        case .completed:
            return "Completed"
        }
    }
}

/// Status badge component
struct StatusBadge: View {
    let status: TripStatus
    
    var body: some View {
        Text(status.label)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(status.color.opacity(0.2))
            .foregroundColor(status.color)
            .cornerRadius(4)
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AppViewModel())
    }
} 