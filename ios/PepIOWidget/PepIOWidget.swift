//
//  PepIOWidget.swift
//  PepIOWidget
//
//  Created by Brett Rosenberg on 12/29/25.
//

import WidgetKit
import SwiftUI
import UIKit

// MARK: - Data Models

struct ProtocolItem: Codable {
    let id: String
    let name: String
    let nextDoseTime: String
    let dosesToday: Int
    let totalDosesToday: Int
    let category: String
}

struct AllProtocolsWidgetData {
    let protocols: [ProtocolItem]
    let overallStreak: Int
    let overallAdherence: Int
    
    // Placeholder with multiple protocols (for medium/large widget previews)
    static let placeholder = AllProtocolsWidgetData(
        protocols: [
            ProtocolItem(id: "1", name: "BPC-157", nextDoseTime: "8:00 AM", dosesToday: 1, totalDosesToday: 2, category: "Regenerative"),
            ProtocolItem(id: "2", name: "CJC-1295", nextDoseTime: "2:00 PM", dosesToday: 0, totalDosesToday: 1, category: "Growth"),
            ProtocolItem(id: "3", name: "Ipamorelin", nextDoseTime: "9:00 PM", dosesToday: 1, totalDosesToday: 2, category: "Performance")
        ],
        overallStreak: 7,
        overallAdherence: 85
    )
    
    // Single protocol placeholder (for small widget preview)
    static let singleProtocol = AllProtocolsWidgetData(
        protocols: [
            ProtocolItem(id: "1", name: "BPC-157", nextDoseTime: "8:00 AM", dosesToday: 1, totalDosesToday: 2, category: "Regenerative")
        ],
        overallStreak: 14,
        overallAdherence: 92
    )
    
    static let empty = AllProtocolsWidgetData(
        protocols: [],
        overallStreak: 0,
        overallAdherence: 0
    )
}

// MARK: - Timeline Entry

struct ProtocolEntry: TimelineEntry {
    let date: Date
    let data: AllProtocolsWidgetData
}

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    
    // App Group identifier - must match Flutter and main app
    let appGroupId = "group.com.pepio.app"
    
    func placeholder(in context: Context) -> ProtocolEntry {
        ProtocolEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (ProtocolEntry) -> Void) {
        let data = loadWidgetData()
        completion(ProtocolEntry(date: Date(), data: data))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ProtocolEntry>) -> Void) {
        let data = loadWidgetData()
        let currentDate = Date()
        
        // Create multiple entries for smoother updates
        var entries: [ProtocolEntry] = []
        
        // Current entry
        entries.append(ProtocolEntry(date: currentDate, data: data))
        
        // Find next dose time to create entry just before it
        if let nextDoseDate = getNextDoseDate(from: data, after: currentDate) {
            // Add entry 1 minute before next dose to prompt refresh
            let refreshBeforeDose = Calendar.current.date(byAdding: .minute, value: -1, to: nextDoseDate)!
            if refreshBeforeDose > currentDate {
                entries.append(ProtocolEntry(date: refreshBeforeDose, data: data))
            }
        }
        
        // Refresh at least every 15 minutes for new protocols
        // Using .atEnd policy ensures widget reloads when all entries are shown
        // AND when app updates data via HomeWidget
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
    
    /// Parse next dose time to find when widget should refresh
    private func getNextDoseDate(from data: AllProtocolsWidgetData, after currentDate: Date) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        var nextDates: [Date] = []
        let calendar = Calendar.current
        
        for protocolItem in data.protocols {
            guard protocolItem.nextDoseTime != "--",
                  let time = formatter.date(from: protocolItem.nextDoseTime) else { continue }
            
            // Combine today's date with the time
            var components = calendar.dateComponents([.year, .month, .day], from: currentDate)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            components.hour = timeComponents.hour
            components.minute = timeComponents.minute
            
            if let date = calendar.date(from: components), date > currentDate {
                nextDates.append(date)
            }
        }
        
        return nextDates.min()
    }
    
    private func loadWidgetData() -> AllProtocolsWidgetData {
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
            return .empty
        }
        
        // Track last update timestamp for debugging
        let lastUpdate = userDefaults.object(forKey: "last_widget_update") as? Date
        if let lastUpdate = lastUpdate {
            print("Widget data last updated: \(lastUpdate)")
        }
        
        // Parse protocols JSON
        var protocols: [ProtocolItem] = []
        if let protocolsJson = userDefaults.string(forKey: "protocols_json"),
           let jsonData = protocolsJson.data(using: .utf8) {
            do {
                protocols = try JSONDecoder().decode([ProtocolItem].self, from: jsonData)
                print("Loaded \(protocols.count) protocols from storage")
            } catch {
                print("Failed to decode protocols: \(error)")
            }
        }
        
        let overallStreak = userDefaults.integer(forKey: "overall_streak")
        let overallAdherence = userDefaults.integer(forKey: "overall_adherence")
        
        return AllProtocolsWidgetData(
            protocols: protocols,
            overallStreak: overallStreak,
            overallAdherence: overallAdherence
        )
    }
}

// MARK: - Widget Views

struct PepIOWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(data: entry.data)
        case .systemMedium:
            MediumWidgetView(data: entry.data)
        case .systemLarge:
            LargeWidgetView(data: entry.data)
        default:
            SmallWidgetView(data: entry.data)
        }
    }
}

// MARK: - Small Widget (shows next upcoming protocol OR upgrade prompt for multiple protocols)

struct SmallWidgetView: View {
    let data: AllProtocolsWidgetData
    @Environment(\.colorScheme) var colorScheme
    
    var nextProtocol: ProtocolItem? {
        data.protocols.first { $0.nextDoseTime != "--" } ?? data.protocols.first
    }
    
    var hasMultipleProtocols: Bool {
        data.protocols.count > 1
    }
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.1) : Color.white
    }
    
    var primaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? Color(white: 0.6) : Color(white: 0.4)
    }
    
    var body: some View {
        if data.protocols.isEmpty {
            EmptyWidgetView()
        } else if hasMultipleProtocols {
            // Show upgrade prompt for multiple protocols
            MultipleProtocolsSmallView(data: data)
        } else if let protocolItem = nextProtocol {
            // Single protocol - show full details
            SingleProtocolSmallView(protocolItem: protocolItem, data: data)
        } else {
            EmptyWidgetView()
        }
    }
}

// MARK: - Single Protocol Small Widget (when user has only 1 protocol)

struct SingleProtocolSmallView: View {
    let protocolItem: ProtocolItem
    let data: AllProtocolsWidgetData
    @Environment(\.colorScheme) var colorScheme
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.1) : Color.white
    }
    
    var primaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? Color(white: 0.6) : Color(white: 0.4)
    }
    
    var body: some View {
        ZStack {
            // Explicit solid background
            backgroundColor
            
            // Gradient overlay
            LinearGradient(
                gradient: Gradient(colors: [
                    categoryColor(for: protocolItem.category).opacity(0.15),
                    Color.clear
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "cross.vial.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    if data.overallStreak > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                            Text("\(data.overallStreak)")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                Text(protocolItem.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(1)
                
                if protocolItem.nextDoseTime != "--" {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(secondaryTextColor)
                        Text(protocolItem.nextDoseTime)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(secondaryTextColor)
                    }
                }
                
                HStack {
                    ProgressRing(
                        progress: protocolItem.totalDosesToday > 0
                            ? Double(protocolItem.dosesToday) / Double(protocolItem.totalDosesToday)
                            : 0,
                        color: categoryColor(for: protocolItem.category),
                        lineWidth: 4,
                        size: 28
                    )
                    
                    Text("\(protocolItem.dosesToday)/\(protocolItem.totalDosesToday)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(categoryColor(for: protocolItem.category))
                    
                    Spacer()
                }
            }
            .padding(14)
        }
    }
    
    func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "regenerative": return .green
        case "cognitive": return .blue
        case "metabolism": return .orange
        case "longevity": return .purple
        case "beauty": return .pink
        case "performance": return .red
        case "growth": return .indigo
        case "gut": return .teal
        default: return .blue
        }
    }
}

// MARK: - Multiple Protocols Small Widget (shows summary + upgrade prompt)

struct MultipleProtocolsSmallView: View {
    let data: AllProtocolsWidgetData
    @Environment(\.colorScheme) var colorScheme
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.1) : Color.white
    }
    
    var primaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? Color(white: 0.6) : Color(white: 0.4)
    }
    
    // Calculate overall progress for today
    var totalDosesCompleted: Int {
        data.protocols.reduce(0) { $0 + $1.dosesToday }
    }
    
    var totalDosesRequired: Int {
        data.protocols.reduce(0) { $0 + $1.totalDosesToday }
    }
    
    var overallProgress: Double {
        totalDosesRequired > 0 ? Double(totalDosesCompleted) / Double(totalDosesRequired) : 0
    }
    
    var body: some View {
        ZStack {
            backgroundColor
            
            // Gradient overlay with blue tint
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 10) {
                // Header with icon
                HStack {
                    Image(systemName: "cross.vial.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    if data.overallStreak > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                            Text("\(data.overallStreak)")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                // Protocol count with progress ring
                HStack(spacing: 12) {
                    ProgressRing(
                        progress: overallProgress,
                        color: .blue,
                        lineWidth: 5,
                        size: 38
                    )
                    .overlay(
                        Text("\(data.protocols.count)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.blue)
                    )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(data.protocols.count) Protocols")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(primaryTextColor)
                        
                        Text("\(totalDosesCompleted)/\(totalDosesRequired) doses")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(secondaryTextColor)
                    }
                    
                    Spacer()
                }
                
                // Upgrade hint
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 9, weight: .medium))
                    Text("Use larger widget for details")
                        .font(.system(size: 9, weight: .medium))
                }
                .foregroundColor(secondaryTextColor.opacity(0.8))
            }
            .padding(14)
        }
    }
}

// MARK: - Medium Widget (shows list of protocols)

struct MediumWidgetView: View {
    let data: AllProtocolsWidgetData
    @Environment(\.colorScheme) var colorScheme
    
    var displayedProtocols: [ProtocolItem] {
        Array(data.protocols.prefix(3))
    }
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.1) : Color.white
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? Color(white: 0.6) : Color(white: 0.4)
    }
    
    var body: some View {
        if data.protocols.isEmpty {
            EmptyWidgetView()
        } else {
            ZStack {
                backgroundColor
                
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        Image(systemName: "cross.vial.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.blue)
                        
                        Text("pep.io")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(secondaryTextColor)
                        
                        Spacer()
                        
                        if data.overallStreak > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 12))
                                Text("\(data.overallStreak)")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(.orange)
                        }
                    }
                    
                    // Protocol list
                    VStack(spacing: 10) {
                        ForEach(displayedProtocols, id: \.id) { protocolItem in
                            ProtocolRowView(protocolItem: protocolItem)
                        }
                        
                        if data.protocols.count > 3 {
                            Text("+\(data.protocols.count - 3) more")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(secondaryTextColor)
                        }
                    }
                }
                .padding(16)
            }
        }
    }
}

struct ProtocolRowView: View {
    let protocolItem: ProtocolItem
    @Environment(\.colorScheme) var colorScheme
    
    var primaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? Color(white: 0.6) : Color(white: 0.4)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Protocol name and next dose
            VStack(alignment: .leading, spacing: 4) {
                Text(protocolItem.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(primaryTextColor)
                
                if protocolItem.nextDoseTime != "--" {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                        Text(protocolItem.nextDoseTime)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(secondaryTextColor)
                }
            }
            
            Spacer()
            
            // Progress
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(protocolItem.dosesToday)/\(protocolItem.totalDosesToday)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(categoryColor(for: protocolItem.category))
                
                ProgressRing(
                    progress: protocolItem.totalDosesToday > 0
                        ? Double(protocolItem.dosesToday) / Double(protocolItem.totalDosesToday)
                        : 0,
                    color: categoryColor(for: protocolItem.category),
                    lineWidth: 3,
                    size: 32
                )
            }
        }
    }
    
    func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "regenerative": return .green
        case "cognitive": return .blue
        case "metabolism": return .orange
        case "longevity": return .purple
        case "beauty": return .pink
        case "performance": return .red
        case "growth": return .indigo
        case "gut": return .teal
        default: return .blue
        }
    }
}

// MARK: - Large Widget (shows all protocols with details)

struct LargeWidgetView: View {
    let data: AllProtocolsWidgetData
    @Environment(\.colorScheme) var colorScheme
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.1) : Color.white
    }
    
    var primaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? Color(white: 0.6) : Color(white: 0.4)
    }
    
    var body: some View {
        if data.protocols.isEmpty {
            EmptyWidgetView()
        } else {
            ZStack {
                backgroundColor
                
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack {
                        Image(systemName: "cross.vial.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.blue)
                        
                        Text("pep.io")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(secondaryTextColor)
                        
                        Spacer()
                        
                        if data.overallStreak > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 14))
                                Text("\(data.overallStreak) day streak")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Overall stats
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(data.protocols.count)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(primaryTextColor)
                            Text("Protocols")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(secondaryTextColor)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(data.overallAdherence)%")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.green)
                            Text("Adherence")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(secondaryTextColor)
                        }
                    }
                    
                    Divider()
                    
                    // Protocol list
                    VStack(spacing: 12) {
                        ForEach(data.protocols, id: \.id) { protocolItem in
                            DetailedProtocolRowView(protocolItem: protocolItem)
                        }
                    }
                }
                .padding(20)
            }
        }
    }
}

struct DetailedProtocolRowView: View {
    let protocolItem: ProtocolItem
    @Environment(\.colorScheme) var colorScheme
    
    var primaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? Color(white: 0.6) : Color(white: 0.4)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(protocolItem.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(primaryTextColor)
                    
                    if protocolItem.nextDoseTime != "--" {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 11))
                            Text("Next: \(protocolItem.nextDoseTime)")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(secondaryTextColor)
                    }
                }
                
                Spacer()
                
                ProgressRing(
                    progress: protocolItem.totalDosesToday > 0
                        ? Double(protocolItem.dosesToday) / Double(protocolItem.totalDosesToday)
                        : 0,
                    color: categoryColor(for: protocolItem.category),
                    lineWidth: 5,
                    size: 50
                )
                .overlay(
                    Text("\(protocolItem.dosesToday)/\(protocolItem.totalDosesToday)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(categoryColor(for: protocolItem.category))
                )
            }
        }
        .padding(.vertical, 4)
    }
    
    func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "regenerative": return .green
        case "cognitive": return .blue
        case "metabolism": return .orange
        case "longevity": return .purple
        case "beauty": return .pink
        case "performance": return .red
        case "growth": return .indigo
        case "gut": return .teal
        default: return .blue
        }
    }
}

// MARK: - Empty Widget View

struct EmptyWidgetView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.1) : Color.white
    }
    
    var primaryTextColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    var secondaryTextColor: Color {
        colorScheme == .dark ? Color(white: 0.6) : Color(white: 0.4)
    }
    
    var body: some View {
        ZStack {
            backgroundColor
            
            VStack(spacing: 8) {
                Image(systemName: "cross.vial.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text("No Protocols")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(primaryTextColor)
                
                Text("Add a protocol in the app")
                    .font(.system(size: 12))
                    .foregroundColor(secondaryTextColor)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Progress Ring Component

struct ProgressRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Widget Configuration

struct PepIOWidget: Widget {
    let kind: String = "PepIOWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PepIOWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("Protocol Tracker")
        .description("Track your peptide protocol and doses at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Previews

#Preview("Small - Single Protocol", as: .systemSmall) {
    PepIOWidget()
} timeline: {
    ProtocolEntry(date: .now, data: .singleProtocol)
}

#Preview("Small - Multiple Protocols", as: .systemSmall) {
    PepIOWidget()
} timeline: {
    ProtocolEntry(date: .now, data: .placeholder)
}

#Preview("Medium", as: .systemMedium) {
    PepIOWidget()
} timeline: {
    ProtocolEntry(date: .now, data: .placeholder)
}

#Preview("Large", as: .systemLarge) {
    PepIOWidget()
} timeline: {
    ProtocolEntry(date: .now, data: .placeholder)
}
