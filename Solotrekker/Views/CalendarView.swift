// CalendarView.swift
// SoloTrekker
//
// Created on current date
//

import SwiftUI
import CoreData

/// Represents a single day in the calendar
struct Day: Identifiable {
    var date: Date
    var isInCurrentMonth: Bool
    var index: Int
    
    var id: Int { index }
}

/// Calendar view for trip planning
struct CalendarView: View {
    // Trip being displayed
    let trip: Trip
    
    // Access to managed object context and app view model
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appViewModel: AppViewModel
    
    // Track the selected date and month
    @State private var selectedDate: Date
    @State private var currentMonth: Date
    @State private var showingItineraryItemSheet = false
    @State private var showingEditTripSheet = false // New state for edit trip sheet
    @State private var refreshID = UUID() // Force view refresh when needed
    
    // Create a DateFormatter for month and year
    private let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    // Extract start and end date once to avoid optionals
    private let startDate: Date
    private let endDate: Date
    
    // Initialize with the trip and optional date
    init(trip: Trip, selectedDate: Date? = nil) {
        self.trip = trip
        
        // Use trip dates or defaults
        let start = trip.startDate ?? Date()
        let end = trip.endDate ?? Date().addingTimeInterval(86400 * 7)
        
        // Store these to avoid optionals
        self.startDate = start
        self.endDate = end
        
        // Initialize the selected date to the provided value or start date
        _selectedDate = State(initialValue: selectedDate ?? start)
        
        // Initialize current month to the month containing the selected date
        _currentMonth = State(initialValue: selectedDate ?? start)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Trip title header with edit button
            HStack {
                Text(trip.title ?? "Trip Calendar")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Edit trip button
                Button(action: {
                    showingEditTripSheet = true
                }) {
                    Image(systemName: "pencil.circle")
                        .font(.title3)
                        .foregroundColor(.teal)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            // Month selector
            HStack {
                Button(action: {
                    withAnimation {
                        currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth)!
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text(monthYearFormatter.string(from: currentMonth))
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth)!
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            
            // Day headers
            HStack(spacing: 0) {
                ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 10)
            .background(Color(UIColor.secondarySystemBackground))
            
            // Calendar grid
            let days = getDays()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 5) {
                ForEach(days, id: \.index) { day in
                    let date = day.date
                    
                    // Get destination color for this date if it exists
                    let destinationColor = colorForDate(date)
                    
                    DayCell(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                        isInTrip: appViewModel.isDateInTrip(date, trip: trip),
                        hasItems: hasItineraryItems(for: date),
                        tripColor: trip.color,
                        destinationColor: destinationColor
                    )
                    .id("day-\(day.index)") // Use the explicit index
                    .onTapGesture {
                        // Update both the local and app view model selected dates
                        // This ensures proper synchronization between the calendar view and app state
                        selectedDate = date
                        appViewModel.selectedDate = date
                        
                        // Force refresh to ensure UI updates properly
                        refreshItems()
                    }
                    .opacity(day.isInCurrentMonth ? 1 : 0.3)
                }
            }
            .padding(.horizontal, 5)
            
            Divider()
                .padding(.top)
            
            // Itinerary for selected day
            ScrollView {
                VStack(alignment: .leading) {
                    HStack {
                        Text(appViewModel.formatDate(selectedDate))
                            .font(.headline)
                            .padding(.leading)
                        
                        Spacer()
                        
                        Button(action: {
                            showingItineraryItemSheet = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.teal)
                        }
                        .padding(.trailing)
                    }
                    .padding(.top)
                    
                    // Display itinerary items
                    let items = appViewModel.itineraryItems(for: selectedDate, in: trip, context: viewContext)
                    
                    if items.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary.opacity(0.5))
                            
                            Text("No activities planned for this day")
                                .font(.callout)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                showingItineraryItemSheet = true
                            }) {
                                Text("Add Activity")
                                    .font(.headline)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.teal)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 30)
                    } else {
                        // Use explicit IDs for itinerary items and include refreshID to force updates
                        ForEach(items, id: \.id) { item in
                            ItineraryItemRow(item: item)
                                .id("\(item.id?.uuidString ?? "")-\(refreshID)")
                                .padding(.vertical, 5)
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingItineraryItemSheet) {
            AddItineraryItemView(trip: trip, selectedDate: selectedDate)
                .environmentObject(appViewModel)
                .environment(\.managedObjectContext, viewContext)
        }
        .onChange(of: showingItineraryItemSheet) { oldValue, newValue in
            // When sheet is dismissed, refresh items
            if !newValue {
                refreshItems()
            }
        }
        // Sync with appViewModel.selectedDate when it changes
        .onAppear {
            // Update our local selectedDate if appViewModel has a different date
            if let appDate = appViewModel.selectedDate, !Calendar.current.isDate(appDate, inSameDayAs: selectedDate) {
                selectedDate = appDate
                
                // Also update currentMonth to show the correct month
                let calendar = Calendar.current
                if !calendar.isDate(currentMonth, equalTo: appDate, toGranularity: .month) {
                    currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: appDate)) ?? currentMonth
                }
            }
            
            // Always refresh items when view appears
            refreshItems()
            
            // Listen for destination changes
            NotificationCenter.default.addObserver(
                forName: Notification.Name("DestinationAdded"),
                object: nil,
                queue: .main
            ) { _ in
                // Trigger calendar refresh
                withAnimation {
                    self.refreshCalendar()
                }
            }
        }
        .onChange(of: appViewModel.selectedDate) { oldValue, newValue in
            if let newValue = newValue, !Calendar.current.isDate(selectedDate, inSameDayAs: newValue) {
                selectedDate = newValue
                
                // Update the current month if the new date is in a different month
                let calendar = Calendar.current
                if !calendar.isDate(currentMonth, equalTo: newValue, toGranularity: .month) {
                    currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: newValue)) ?? currentMonth
                }
                
                // Refresh items when date changes
                refreshItems()
            }
        }
        // Also refresh when selected date changes directly
        .onChange(of: selectedDate) { oldValue, newValue in
            refreshItems()
        }
        // Add sheet for editing trip details
        .sheet(isPresented: $showingEditTripSheet) {
            EditTripView(trip: trip)
                .environmentObject(appViewModel)
                .environment(\.managedObjectContext, viewContext)
        }
        // Refresh when edit sheet is dismissed
        .onChange(of: showingEditTripSheet) { oldValue, newValue in
            if !newValue {
                // When the edit sheet is dismissed, refresh to show updated trip details
                refreshItems()
            }
        }
    }
    
    /// Check if a date has itinerary items
    /// - Parameter date: The date to check
    /// - Returns: True if there are items for this date
    private func hasItineraryItems(for date: Date) -> Bool {
        // Use the updated function from AppViewModel with our local viewContext
        let items = appViewModel.itineraryItems(for: date, in: trip, context: viewContext)
        return !items.isEmpty
    }
    
    /// Force a refresh of the itinerary items
    private func refreshItems() {
        // Generate a new UUID to force the views to update
        DispatchQueue.main.async {
            self.refreshID = UUID()
        }
    }
    
    /// Get the days in the month for display in the calendar
    /// - Parameter month: The month to get days for
    /// - Returns: Array of date options with index information
    private func getDays() -> [Day] {
        var days = [Day]()
        
        // Previous month days
        let firstDay = Calendar.current.firstWeekday
        let firstDayOfMonth = firstDayOfMonth()
        let weekday = Calendar.current.component(.weekday, from: firstDayOfMonth)
        let daysToAdd = (weekday + 7 - firstDay) % 7
        
        if daysToAdd > 0 {
            for i in (1...daysToAdd).reversed() {
                if let date = Calendar.current.date(byAdding: .day, value: -i, to: firstDayOfMonth) {
                    days.append(Day(date: date, isInCurrentMonth: false, index: days.count))
                }
            }
        }
        
        // Current month days
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: currentMonth)?.count ?? 0
        for i in 1...daysInMonth {
            if let date = Calendar.current.date(from: DateComponents(year: Calendar.current.component(.year, from: currentMonth), month: Calendar.current.component(.month, from: currentMonth), day: i)) {
                days.append(Day(date: date, isInCurrentMonth: true, index: days.count))
            }
        }
        
        // Next month days
        let remainingDays = 42 - days.count // Always show 6 weeks
        if remainingDays > 0 {
            let lastDayOfMonth = Calendar.current.date(from: DateComponents(year: Calendar.current.component(.year, from: currentMonth), month: Calendar.current.component(.month, from: currentMonth), day: daysInMonth))!
            for i in 1...remainingDays {
                if let date = Calendar.current.date(byAdding: .day, value: i, to: lastDayOfMonth) {
                    days.append(Day(date: date, isInCurrentMonth: false, index: days.count))
                }
            }
        }
        
        return days
    }
    
    // Determine the color for a specific date based on destinations
    private func colorForDate(_ date: Date) -> Color? {
        // Check if date falls within any destination's date range
        for destination in trip.destinationsArray {
            if let startDate = destination.startDate, 
               let endDate = destination.endDate,
               date >= Calendar.current.startOfDay(for: startDate) && 
               date <= Calendar.current.startOfDay(for: endDate) {
                return destination.color
            }
        }
        // Return nil if no destination covers this date
        return nil
    }
    
    private func firstDayOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        return calendar.date(from: components)!
    }
    
    // Added method to force refresh of calendar display
    private func refreshCalendar() {
        // Simply re-setting selectedDate will refresh the calendar view
        let tempDate = selectedDate
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            selectedDate = tempDate
        }
    }
}

/// Individual day cell in the calendar
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isInTrip: Bool
    let hasItems: Bool
    let tripColor: Color
    let destinationColor: Color?
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        ZStack {
            // Background for days in the trip
            if isInTrip {
                RoundedRectangle(cornerRadius: 10)
                    .fill((destinationColor ?? tripColor).opacity(0.2))
            }
            
            // Selection indicator
            if isSelected {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(destinationColor ?? tripColor, lineWidth: 2)
            }
            
            VStack {
                // Day number
                Text(dayNumber)
                    .font(.system(size: 16))
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isInTrip ? .primary : .secondary)
                
                // Indicator for days with activities
                if hasItems {
                    Circle()
                        .fill(destinationColor ?? tripColor)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(8)
        }
        .frame(height: 50)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
    }
}

/// Row displaying a single itinerary item
struct ItineraryItemRow: View {
    let item: ItineraryItem
    
    // Format time range
    private var timeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        if let startTime = item.startTime, let endTime = item.endTime {
            return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
        } else if let startTime = item.startTime {
            return formatter.string(from: startTime)
        }
        
        return ""
    }
    
    // Get icon based on item type
    private var typeIcon: String {
        switch item.type {
        case "accommodation":
            return "bed.double.fill"
        case "transport":
            return "airplane"
        case "excursion":
            return "map.fill"
        case "food":
            return "fork.knife"
        default:
            return "calendar"
        }
    }
    
    // Get color based on item type
    private var typeColor: Color {
        switch item.type {
        case "accommodation":
            return .blue
        case "transport":
            return .orange
        case "excursion":
            return .green
        case "food":
            return .red
        default:
            return .purple
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Time column
            VStack(alignment: .leading) {
                Text(timeRange)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, alignment: .leading)
            
            // Type indicator
            Image(systemName: typeIcon)
                .foregroundColor(.white)
                .frame(width: 26, height: 26)
                .background(typeColor)
                .cornerRadius(8)
                .padding(.top, 2)
            
            // Content column
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title ?? "Untitled")
                    .font(.headline)
                
                if let description = item.itemDescription, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let location = item.location, !location.isEmpty {
                    HStack(spacing: 2) {
                        Image(systemName: "mappin")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text(location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let tripRequest: NSFetchRequest<Trip> = Trip.fetchRequest()
        let trips = try? context.fetch(tripRequest)
        
        return Group {
            if let firstTrip = trips?.first {
                CalendarView(trip: firstTrip)
                    .environment(\.managedObjectContext, context)
                    .environmentObject(AppViewModel())
            } else {
                Text("No preview data available")
            }
        }
    }
} 