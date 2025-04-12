// CalendarView.swift
// SoloTrekker
//
// Created on current date
//

import SwiftUI
import CoreData

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
            let days = daysInMonth(for: currentMonth)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 5) {
                // Use explicit indices from our daysInMonth structure
                ForEach(days, id: \.index) { day in
                    if let date = day.date {
                        DayCell(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            isInTrip: appViewModel.isDateInTrip(date, trip: trip),
                            hasItems: hasItineraryItems(for: date),
                            tripColor: appViewModel.color(from: trip.colorHex)
                        )
                        .id("day-\(day.index)") // Use the explicit index
                        .onTapGesture {
                            selectedDate = date
                            appViewModel.selectedDate = date
                        }
                    } else {
                        // Empty cell for days not in this month
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 50)
                            .id("empty-\(day.index)") // Use the explicit index
                    }
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
                        // Use explicit IDs for itinerary items
                        ForEach(items, id: \.id) { item in
                            ItineraryItemRow(item: item)
                                .id(item.id) // Explicit ID
                                .padding(.vertical, 5)
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingItineraryItemSheet) {
            AddItineraryItemView(trip: trip, selectedDate: selectedDate)
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
        }
        // Listen for changes to appViewModel.selectedDate
        .onChange(of: appViewModel.selectedDate) { _, newDate in
            if let newDate = newDate, !Calendar.current.isDate(selectedDate, inSameDayAs: newDate) {
                selectedDate = newDate
                
                // Update the current month if the new date is in a different month
                let calendar = Calendar.current
                if !calendar.isDate(currentMonth, equalTo: newDate, toGranularity: .month) {
                    currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: newDate)) ?? currentMonth
                }
            }
        }
    }
    
    /// Check if a date has itinerary items
    /// - Parameter date: The date to check
    /// - Returns: True if there are items for this date
    private func hasItineraryItems(for date: Date) -> Bool {
        !appViewModel.itineraryItems(for: date, in: trip, context: viewContext).isEmpty
    }
    
    /// Get the days in the month for display in the calendar
    /// - Parameter month: The month to get days for
    /// - Returns: Array of date options with index information
    private func daysInMonth(for month: Date) -> [(index: Int, date: Date?)] {
        let calendar = Calendar.current
        
        // Get the first day of the month
        let components = calendar.dateComponents([.year, .month], from: month)
        let firstDayOfMonth = calendar.date(from: components)!
        
        // Determine the first date to show (may be in the previous month)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let daysToOffset = (firstWeekday - calendar.firstWeekday + 7) % 7
        
        // Get the range of days in the month
        let daysInMonth = calendar.range(of: .day, in: .month, for: firstDayOfMonth)!.count
        
        // Create array with empty slots for days from previous month
        var days: [(index: Int, date: Date?)] = []
        
        // Add empty days for previous month
        for i in 0..<daysToOffset {
            days.append((index: i, date: nil))
        }
        
        // Add all days in the current month
        for day in 1...daysInMonth {
            let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth)!
            days.append((index: daysToOffset + day - 1, date: date))
        }
        
        // Add placeholder days to complete the grid (up to 42 cells total - 6 weeks)
        let remainingDays = 42 - days.count
        for i in 0..<remainingDays {
            days.append((index: daysToOffset + daysInMonth + i, date: nil))
        }
        
        return days
    }
}

/// Individual day cell in the calendar
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isInTrip: Bool
    let hasItems: Bool
    let tripColor: Color
    
    var body: some View {
        ZStack {
            // Background for days in the trip
            if isInTrip {
                RoundedRectangle(cornerRadius: 10)
                    .fill(tripColor.opacity(0.2))
            }
            
            // Selection indicator
            if isSelected {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(tripColor, lineWidth: 2)
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
                        .fill(tripColor)
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
    
    // Get the day number as string
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
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