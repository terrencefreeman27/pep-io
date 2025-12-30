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
    
    static let placeholder = AllProtocolsWidgetData(
        protocols: [
            ProtocolItem(id: "1", name: "BPC-157", nextDoseTime: "8:00 AM", dosesToday: 1, totalDosesToday: 2, category: "Regenerative"),
            ProtocolItem(id: "2", name: "CJC-1295", nextDoseTime: "2:00 PM", dosesToday: 0, totalDosesToday: 1, category: "Growth")
        ],
        overallStreak: 7,
        overallAdherence: 85
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
        let entry = ProtocolEntry(date: Date(), data: data)
        
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func loadWidgetData() -> AllProtocolsWidgetData {
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
            return .empty
        }
        
        // Parse protocols JSON
        var protocols: [ProtocolItem] = []
        if let protocolsJson = userDefaults.string(forKey: "protocols_json"),
           let data = protocolsJson.data(using: .utf8) {
            do {
                protocols = try JSONDecoder().decode([ProtocolItem].self, from: data)
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

// MARK: - Small Widget (shows next upcoming protocol)

struct SmallWidgetView: View {
    let data: AllProtocolsWidgetData
    
    var nextProtocol: ProtocolItem? {
        data.protocols.first { $0.nextDoseTime != "--" } ?? data.protocols.first
    }
    
    var body: some View {
        if let protocolItem = nextProtocol {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        categoryColor(for: protocolItem.category).opacity(0.15),
                        Color(.systemBackground)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if let uiImage = UIImage(named: "AppIconImage") {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .cornerRadius(4)
                        } else {
                            Image(systemName: "cross.vial.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                        
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
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if protocolItem.nextDoseTime != "--" {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Text(protocolItem.nextDoseTime)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
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
        } else {
            EmptyWidgetView()
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

// MARK: - Medium Widget (shows list of protocols)

struct MediumWidgetView: View {
    let data: AllProtocolsWidgetData
    
    var displayedProtocols: [ProtocolItem] {
        Array(data.protocols.prefix(3))
    }
    
    var body: some View {
        if data.protocols.isEmpty {
            EmptyWidgetView()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    if let uiImage = UIImage(named: "AppIconImage") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .cornerRadius(5)
                    } else {
                        Image(systemName: "cross.vial.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    
                    Text("pep.io")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
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
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
        }
    }
}

struct ProtocolRowView: View {
    let protocolItem: ProtocolItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Protocol name and next dose
            VStack(alignment: .leading, spacing: 4) {
                Text(protocolItem.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                if protocolItem.nextDoseTime != "--" {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                        Text(protocolItem.nextDoseTime)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.secondary)
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
    
    var body: some View {
        if data.protocols.isEmpty {
            EmptyWidgetView()
        } else {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    if let uiImage = UIImage(named: "AppIconImage") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 28)
                            .cornerRadius(6)
                    } else {
                        Image(systemName: "cross.vial.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    
                    Text("pep.io")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
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
                        Text("Protocols")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(data.overallAdherence)%")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.green)
                        Text("Adherence")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
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

struct DetailedProtocolRowView: View {
    let protocolItem: ProtocolItem
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(protocolItem.name)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)
                    
                    if protocolItem.nextDoseTime != "--" {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 11))
                            Text("Next: \(protocolItem.nextDoseTime)")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.secondary)
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
    var body: some View {
        VStack {
            if let uiImage = UIImage(named: "AppIconImage") {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .cornerRadius(8)
            } else {
                Image(systemName: "cross.vial.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.blue)
            }
            
            Text("No Protocols")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
            
            Text("Add a protocol in the app")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
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
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Protocol Tracker")
        .description("Track your peptide protocol and doses at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    PepIOWidget()
} timeline: {
    ProtocolEntry(date: .now, data: .placeholder)
}

#Preview(as: .systemMedium) {
    PepIOWidget()
} timeline: {
    ProtocolEntry(date: .now, data: .placeholder)
}

#Preview(as: .systemLarge) {
    PepIOWidget()
} timeline: {
    ProtocolEntry(date: .now, data: .placeholder)
}
