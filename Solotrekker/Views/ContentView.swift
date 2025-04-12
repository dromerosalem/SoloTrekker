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
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home tab - Trip List
            NavigationView {
                HomeView()
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
                        .navigationTitle("Trip Calendar")
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
                        .navigationBarItems(
                            trailing: Button(action: {
                                appViewModel.isAddingExpense = true
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