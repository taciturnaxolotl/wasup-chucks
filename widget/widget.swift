//
//  widget.swift
//  widget
//
//  Created by Kieran Klukas on 1/30/26.
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry & Provider

struct ChucksEntry: TimelineEntry {
    let date: Date
    let status: ChucksStatus
    let specials: [MenuItem]
    let venueName: String
}

struct ChucksProvider: TimelineProvider {
    func placeholder(in context: Context) -> ChucksEntry {
        ChucksEntry(
            date: Date(),
            status: ChucksStatus.calculate(),
            specials: [],
            venueName: "Home Cooking"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ChucksEntry) -> Void) {
        let entry = ChucksEntry(
            date: Date(),
            status: ChucksStatus.calculate(),
            specials: [],
            venueName: "Home Cooking"
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChucksEntry>) -> Void) {
        Task {
            let status = ChucksStatus.calculate()
            var specials: [MenuItem] = []
            var venueName = "Home Cooking"

            let phase = status.isOpen ? status.currentPhase : (status.nextPhase ?? .lunch)
            let menuDate = status.isOpen ? Date() : (status.nextPhaseStart ?? Date())
            if phase != .closed {
                do {
                    let result = try await ChucksService.shared.getSpecialsWithVenue(for: menuDate, phase: phase)
                    specials = result.items
                    venueName = result.venueName
                } catch {
                    print("Failed to fetch specials: \(error)")
                }
            }

            let entry = ChucksEntry(
                date: Date(),
                status: status,
                specials: specials,
                venueName: venueName
            )

            let nextUpdate: Date
            if let remaining = status.timeRemaining {
                nextUpdate = min(
                    Date().addingTimeInterval(remaining + 60),
                    Date().addingTimeInterval(15 * 60)
                )
            } else {
                nextUpdate = Date().addingTimeInterval(15 * 60)
            }

            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

// MARK: - Small Widget View
struct SmallWidgetView: View {
    let entry: ChucksEntry

    private var statusColor: Color {
        entry.status.isOpen ? .green : .orange
    }

    var body: some View {
        ZStack {
            VStack {
                HStack(spacing: 4) {
                    Image(systemName: entry.status.isOpen ? entry.status.currentPhase.icon : (entry.status.nextPhase?.icon ?? "moon.zzz.fill"))
                        .foregroundStyle(statusColor)
                        .accessibilityHidden(true)
                    Text(entry.status.isOpen ? "Open" : "Closed")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(statusColor)
                    Spacer()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(entry.status.isOpen ? "Chuck's is open for \(entry.status.currentPhase.shortName)" : "Chuck's is closed")
                Spacer()
            }

            VStack(spacing: 4) {
                if let remaining = entry.status.timeRemaining {
                    Text(remaining.compactCountdown)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.5)
                }

                if entry.status.isOpen {
                    Text("until \(entry.status.currentPhase.shortName) ends")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let next = entry.status.nextPhase, next != .closed {
                    Text("until \(next.shortName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("See you tomorrow!")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Medium Widget View
struct MediumWidgetView: View {
    let entry: ChucksEntry

    private var statusColor: Color {
        entry.status.isOpen ? .green : .orange
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: entry.status.isOpen ? entry.status.currentPhase.icon : (entry.status.nextPhase?.icon ?? "moon.zzz.fill"))
                        .foregroundStyle(statusColor)
                        .accessibilityHidden(true)
                    Text(entry.status.isOpen ? "Open" : "Closed")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(statusColor)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(entry.status.isOpen ? "Chuck's is open" : "Chuck's is closed")

                if let remaining = entry.status.timeRemaining {
                    Text(remaining.compactCountdown)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.5)
                }

                if entry.status.isOpen {
                    Text("until \(entry.status.currentPhase.shortName) ends")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else if let next = entry.status.nextPhase, next != .closed {
                    Text("until \(next.shortName)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.venueName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                if entry.specials.isEmpty {
                    Spacer()
                    Text("No specials available")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Spacer()
                } else {
                    ForEach(entry.specials.prefix(4)) { item in
                        Text("• \(item.name)")
                            .font(.caption2)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Today's specials from \(entry.venueName): \(entry.specials.map { $0.name }.joined(separator: ", "))")
        }
    }
}

// MARK: - Large Widget View
struct LargeWidgetView: View {
    let entry: ChucksEntry

    private var statusColor: Color {
        entry.status.isOpen ? .green : .orange
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: entry.status.isOpen ? entry.status.currentPhase.icon : (entry.status.nextPhase?.icon ?? "moon.zzz.fill"))
                        .font(.title2)
                        .foregroundStyle(statusColor)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.status.isOpen ? "Open" : "Closed")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(statusColor)

                        Text(entry.status.isOpen ? entry.status.currentPhase.shortName : (entry.status.nextPhase?.shortName ?? ""))
                            .font(.headline.weight(.bold))
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(entry.status.isOpen ? "Chuck's is open for \(entry.status.currentPhase.shortName)" : "Chuck's is closed, next meal is \(entry.status.nextPhase?.shortName ?? "tomorrow")")

                Spacer()

                if let remaining = entry.status.timeRemaining {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(remaining.compactCountdown)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .monospacedDigit()

                        Text(entry.status.isOpen ? "until \(entry.status.currentPhase.shortName) ends" : "until open")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text(entry.venueName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                if entry.specials.isEmpty {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("No specials available")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                        Spacer()
                    }
                    Spacer()
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(entry.specials.prefix(6)) { item in
                            Text("• \(item.name)")
                                .font(.callout)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Today's specials from \(entry.venueName): \(entry.specials.map { $0.name }.joined(separator: ", "))")
        }
    }
}

// MARK: - Lock Screen Widgets

struct AccessoryInlineView: View {
    let entry: ChucksEntry

    var body: some View {
        if entry.status.isOpen {
            if let remaining = entry.status.timeRemaining {
                Label("Open • \(remaining.compactCountdown) left", systemImage: entry.status.currentPhase.icon)
            } else {
                Label("Open for \(entry.status.currentPhase.shortName)", systemImage: entry.status.currentPhase.icon)
            }
        } else if let next = entry.status.nextPhase, next != .closed {
            if let remaining = entry.status.timeRemaining {
                Label("\(next.shortName) in \(remaining.compactCountdown)", systemImage: next.icon)
            } else {
                Label("\(next.shortName) soon", systemImage: next.icon)
            }
        } else {
            Label("Closed", systemImage: "moon.zzz.fill")
        }
    }
}

struct AccessoryCircularView: View {
    let entry: ChucksEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Image(systemName: entry.status.isOpen ? entry.status.currentPhase.icon : (entry.status.nextPhase?.icon ?? "moon.zzz.fill"))
                    .font(.caption)
                if let remaining = entry.status.timeRemaining {
                    Text(remaining.compactCountdown)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .monospacedDigit()
                }
            }
        }
    }
}

struct AccessoryRectangularView: View {
    let entry: ChucksEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: entry.status.isOpen ? entry.status.currentPhase.icon : (entry.status.nextPhase?.icon ?? "moon.zzz.fill"))
                Text(entry.status.isOpen ? "Open" : "Closed")
                    .font(.headline)
            }

            if entry.status.isOpen {
                if let remaining = entry.status.timeRemaining {
                    Text("\(entry.status.currentPhase.shortName) ends in \(remaining.compactCountdown)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if let next = entry.status.nextPhase, next != .closed {
                if let remaining = entry.status.timeRemaining {
                    Text("\(next.shortName) opens in \(remaining.compactCountdown)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !entry.specials.isEmpty {
                Text(entry.specials.prefix(2).map { $0.name }.joined(separator: ", "))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Widget Configuration
struct ChucksWidget: Widget {
    let kind: String = "ChucksWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ChucksProvider()) { entry in
            WidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Chuck's Status")
        .description("See current meal times and specials at Chuck's.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

struct WidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: ChucksEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        case .accessoryInline:
            AccessoryInlineView(entry: entry)
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Previews
#Preview("Small", as: .systemSmall) {
    ChucksWidget()
} timeline: {
    ChucksEntry(date: Date(), status: ChucksStatus.calculate(), specials: [], venueName: "Home Cooking")
}

#Preview("Medium", as: .systemMedium) {
    ChucksWidget()
} timeline: {
    ChucksEntry(date: Date(), status: ChucksStatus.calculate(), specials: [
        MenuItem(name: "Scrambled Eggs", allergens: []),
        MenuItem(name: "Sausage Patties", allergens: []),
        MenuItem(name: "Tater Tots", allergens: []),
        MenuItem(name: "Biscuits", allergens: [])
    ], venueName: "Home Cooking")
}

#Preview("Large", as: .systemLarge) {
    ChucksWidget()
} timeline: {
    ChucksEntry(date: Date(), status: ChucksStatus.calculate(), specials: [
        MenuItem(name: "Scrambled Eggs", allergens: []),
        MenuItem(name: "Sausage Patties", allergens: []),
        MenuItem(name: "Tater Tots", allergens: []),
        MenuItem(name: "Biscuits", allergens: []),
        MenuItem(name: "Country Gravy", allergens: []),
        MenuItem(name: "Hash Browns", allergens: [])
    ], venueName: "Home Cooking")
}

#Preview("Lock Screen - Inline", as: .accessoryInline) {
    ChucksWidget()
} timeline: {
    ChucksEntry(date: Date(), status: ChucksStatus.calculate(), specials: [], venueName: "Home Cooking")
}

#Preview("Lock Screen - Circular", as: .accessoryCircular) {
    ChucksWidget()
} timeline: {
    ChucksEntry(date: Date(), status: ChucksStatus.calculate(), specials: [], venueName: "Home Cooking")
}

#Preview("Lock Screen - Rectangular", as: .accessoryRectangular) {
    ChucksWidget()
} timeline: {
    ChucksEntry(date: Date(), status: ChucksStatus.calculate(), specials: [
        MenuItem(name: "Scrambled Eggs", allergens: []),
        MenuItem(name: "Sausage Patties", allergens: [])
    ], venueName: "Home Cooking")
}
