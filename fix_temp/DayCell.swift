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
            // Base background
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.secondarySystemBackground))
            // Background for days in the trip
            if isInTrip {
                RoundedRectangle(cornerRadius: 10)
                    .fill((destinationColor ?? tripColor).opacity(0.3))
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
        .cornerRadius(10)
    }
}
