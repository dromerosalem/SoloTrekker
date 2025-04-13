// ContentView.swift
// SoloTrekker
//
// Created on current date
//

import SwiftUI
import CoreData

/// Main container view for the app
struct ContentView: View {
    // Access to managed object context and app view model
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appViewModel: AppViewModel
    
    // State for tab selection
    @State private var selectedTab = 0
    @State private var homeViewKey = UUID() // Force HomeView recreation
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home tab - Trip List
            NavigationView {
                HomeView()
                    .id(homeViewKey) // Force view recreation when key changes
                    .navigationTitle("My Trips")
                    .navigationBarItems(
                        trailing: Button(action: {
                            appViewModel.isAddingTrip = true
                        }) {
                            Image(systemName: "plus")
                                .font(.headline)
                        }
                    )
            }
            .tabItem {
                Label("Trips", systemImage: "airplane")
            }
            .tag(0)
            
            // Calendar tab
            NavigationView {
                if let selectedTrip = appViewModel.selectedTrip {
                    CalendarView(trip: selectedTrip)
                        .id("calendar-\(selectedTrip.id?.uuidString ?? UUID().uuidString)") // Force recreation when trip changes
                        .navigationTitle("Trip Calendar")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                VStack {
                                    Text("Trip Calendar")
                                        .font(.headline)
                                    Text(selectedTrip.wrappedTitle)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: {
                                    appViewModel.isEditingTrip = true
                                }) {
                                    Image(systemName: "pencil.circle")
                                        .font(.headline)
                                }
                            }
                        }
                } else {
                    Text("Select a trip first")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }
            .tag(1)
            
            // Expenses tab
            NavigationView {
                if let selectedTrip = appViewModel.selectedTrip {
                    ExpensesView(trip: selectedTrip)
                        .navigationTitle("Expenses")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                VStack {
                                    Text("Expenses")
                                        .font(.headline)
                                    Text(selectedTrip.wrappedTitle)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: {
                                    appViewModel.isAddingExpense = true
                                }) {
                                    Image(systemName: "plus")
                                        .font(.headline)
                                }
                            }
                        }
                } else {
                    Text("Select a trip first")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .tabItem {
                Label("Expenses", systemImage: "dollarsign.circle")
            }
            .tag(2)
            
            // Documents tab
            NavigationView {
                if let selectedTrip = appViewModel.selectedTrip {
                    DocumentsView(trip: selectedTrip)
                        .navigationTitle("Documents")
                        .navigationBarItems(
                            trailing: Button(action: {
                                appViewModel.isAddingDocument = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.headline)
                            }
                        )
                } else {
                    Text("Select a trip first")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            .tabItem {
                Label("Documents", systemImage: "doc")
            }
            .tag(3)
            
            // Settings tab
            NavigationView {
                SettingsView()
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(4)
        }
        .onChange(of: appViewModel.selectedTab) { oldValue, newValue in
            selectedTab = newValue
            
            // Important: When navigating back to the Trips tab, regenerate the HomeView
            if newValue == 0 && oldValue != 0 {
                // Force HomeView recreation when coming back to it
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    homeViewKey = UUID()
                }
            }
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            // Keep appViewModel in sync with selectedTab
            appViewModel.selectedTab = newValue
        }
        .onChange(of: appViewModel.isEditingTrip) { oldValue, newValue in
            if !newValue && oldValue {
                // Force HomeView and other views to refresh when trip editing is completed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    homeViewKey = UUID()
                }
            }
        }
        .sheet(isPresented: $appViewModel.isAddingTrip) {
            AddTripView()
        }
        .sheet(isPresented: $appViewModel.isAddingExpense) {
            if let trip = appViewModel.selectedTrip {
                AddExpenseView(trip: trip)
            }
        }
        .sheet(isPresented: $appViewModel.isAddingDocument) {
            if let trip = appViewModel.selectedTrip {
                AddDocumentView(trip: trip)
            }
        }
        .sheet(isPresented: $appViewModel.isEditingTrip) {
            if let trip = appViewModel.selectedTrip {
                EditTripView(trip: trip)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        // Apply preferred color scheme
        .preferredColorScheme(appViewModel.colorScheme)
        .accentColor(Color.teal)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AppViewModel())
    }
} 