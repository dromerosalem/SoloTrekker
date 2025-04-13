// DestinationsView.swift
// SoloTrekker
//
// Created on current date
//

import SwiftUI
import CoreData

/// View for displaying and managing trip destinations
struct DestinationsView: View {
    // MARK: - Environment
    
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - Properties
    
    /// The trip whose destinations are being displayed
    @ObservedObject var trip: Trip
    
    /// State for managing the sheet presentation
    @State private var showingAddDestination = false
    @State private var selectedDestination: TripDestination?
    
    // MARK: - Body
    
    var body: some View {
        List {
            ForEach(trip.destinationsArray) { destination in
                DestinationRow(destination: destination)
                    .onTapGesture {
                        selectedDestination = destination
                    }
            }
            .onDelete(perform: deleteDestinations)
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
            } else {
                Text("No preview data available")
            }
        }
    }
} 