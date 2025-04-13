// DestinationsView.swift
// SoloTrekker
//
// Created on current date
//

import SwiftUI
import CoreData

// Note: dismissToCalendar notification name is defined in Notification+Extensions.swift

/// View for displaying and managing trip destinations
struct DestinationsView: View {
    // MARK: - Environment
    
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var appViewModel: AppViewModel
    
    // MARK: - Properties
    
    /// The trip whose destinations are being displayed
    @ObservedObject var trip: Trip
    
    /// State for managing the sheet presentation
    @State private var showingAddDestination = false
    @State private var selectedDestination: TripDestination?
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // More subtle back to calendar button
            HStack {
                Button(action: {
                    // Set the trip in the view model
                    appViewModel.selectedTrip = trip
                    
                    // Ensure we have a selected date
                    if appViewModel.selectedDate == nil {
                        appViewModel.selectedDate = trip.startDate ?? Date()
                    }
                    
                    // Set calendar tab 
                    appViewModel.selectedTab = 1
                    
                    // Post notification to dismiss all the way to calendar
                    NotificationCenter.default.post(
                        name: .dismissToCalendar,
                        object: nil
                    )
                    
                    // Dismiss this view
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 16))
                        Text("Back to Calendar")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.blue)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                }
                .padding(.leading, 8)
                
                Spacer()
            }
            .padding(.top, 8)
            .padding(.bottom, 4)
            
            // Existing content
            Group {
                if trip.destinationsArray.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "map")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No Destinations")
                            .font(.headline)
                        
                        Text("Add destinations to organize different parts of your trip")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: { showingAddDestination = true }) {
                            Label("Add a Destination", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                } else {
                    List {
                        ForEach(trip.destinationsArray) { destination in
                            DestinationRow(destination: destination)
                                .onTapGesture {
                                    selectedDestination = destination
                                }
                        }
                        .onDelete(perform: deleteDestinations)
                    }
                }
            }
        }
        .navigationTitle("Destinations")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddDestination = true }) {
                    Label("Add Destination", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddDestination) {
            NavigationView {
                AddDestinationView(trip: trip)
            }
        }
        .sheet(item: $selectedDestination) { destination in
            NavigationView {
                EditDestinationView(destination: destination)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
    
    // MARK: - Methods
    
    /// Deletes destinations at the specified offsets
    private func deleteDestinations(offsets: IndexSet) {
        withAnimation {
            offsets.map { trip.destinationsArray[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting destinations: \(error)")
            }
        }
    }
}

/// A row displaying a single destination
struct DestinationRow: View {
    @ObservedObject var destination: TripDestination
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(destination.color)
                    .frame(width: 12, height: 12)
                Text(destination.wrappedName)
                    .font(.headline)
            }
            
            Text(destination.formattedDateRange)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if !destination.wrappedNotes.isEmpty {
                Text(destination.wrappedNotes)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

/// Preview provider
struct DestinationsView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let request: NSFetchRequest<Trip> = Trip.fetchRequest()
        let trips = try? context.fetch(request)
        
        return NavigationView {
            if let firstTrip = trips?.first {
                DestinationsView(trip: firstTrip)
                    .environment(\.managedObjectContext, context)
                    .environmentObject(AppViewModel())
            } else {
                Text("No preview data available")
            }
        }
    }
} 