//
//  widget.swift
//  widget
//
//  Created by Kieran Klukas on 1/30/26.
//

import WidgetKit
import SwiftUI

// MARK: - Models

struct Allergen: Codable, Hashable {
    let url: String
    let alt: String
}

struct MenuItem: Codable, Hashable, Identifiable {
    let name: String
    let allergens: [Allergen]
    
    var id: String { name }
}

struct VenueMenu: Codable, Hashable {
    let venue: String
    let meal: String?
    let slot: String
    let items: [MenuItem]
}

typealias MenuResponse = [String: [VenueMenu]]

enum MealPhase: String, CaseIterable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case closed = "Closed"
    
    var icon: String {
        switch self {
        case .breakfast: return "cup.and.saucer.fill"
        case .lunch: return "takeoutbag.and.cup.and.straw.fill"
        case .dinner: return "fork.knife.circle.fill"
        case .closed: return "moon.zzz.fill"
        }
    }
    
    var shortName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .closed: return "Closed"
        }
    }
    
    var apiSlot: String {
        switch self {
        case .breakfast: return "breakfast"
        case .lunch: return "lunch"
        case .dinner: return "dinner"
        case .closed: return ""
        }
    }
}

struct MealSchedule {
    let phase: MealPhase
    let startHour: Int
    let startMinute: Int
    let endHour: Int
    let endMinute: Int
    
    var startMinutes: Int { startHour * 60 + startMinute }
    var endMinutes: Int { endHour * 60 + endMinute }
    
    // Mon-Fri: Hot Breakfast 7-8:15, Continental 8:15-9:30, Lunch 10:30-2:30, Dinner 4:30-7:30
    // Treating Hot + Continental as one "Breakfast" period for simplicity
    static let weekdaySchedule: [MealSchedule] = [
        MealSchedule(phase: .breakfast, startHour: 7, startMinute: 0, endHour: 9, endMinute: 30),
        MealSchedule(phase: .lunch, startHour: 10, startMinute: 30, endHour: 14, endMinute: 30),
        MealSchedule(phase: .dinner, startHour: 16, startMinute: 30, endHour: 19, endMinute: 30)
    ]
    
    // Saturday: Continental 8-9, Lunch 11-1, Dinner 4:30-6:30
    static let saturdaySchedule: [MealSchedule] = [
        MealSchedule(phase: .breakfast, startHour: 8, startMinute: 0, endHour: 9, endMinute: 0),
        MealSchedule(phase: .lunch, startHour: 11, startMinute: 0, endHour: 13, endMinute: 0),
        MealSchedule(phase: .dinner, startHour: 16, startMinute: 30, endHour: 18, endMinute: 30)
    ]
    
    // Sunday: Hot Breakfast 8-9, Lunch 11:30-2, Dinner 5-7:30
    static let sundaySchedule: [MealSchedule] = [
        MealSchedule(phase: .breakfast, startHour: 8, startMinute: 0, endHour: 9, endMinute: 0),
        MealSchedule(phase: .lunch, startHour: 11, startMinute: 30, endHour: 14, endMinute: 0),
        MealSchedule(phase: .dinner, startHour: 17, startMinute: 0, endHour: 19, endMinute: 30)
    ]
    
    static func schedule(for weekday: Int) -> [MealSchedule] {
        switch weekday {
        case 1: return sundaySchedule
        case 7: return saturdaySchedule
        default: return weekdaySchedule
        }
    }
}

struct CedarvilleTime {
    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }
}

struct ChucksStatus {
    let currentPhase: MealPhase
    let timeRemaining: TimeInterval?
    let nextPhase: MealPhase?
    let nextPhaseStart: Date?
    let isOpen: Bool
    let currentMealEnd: Date?
    
    static func calculate(for date: Date = Date()) -> ChucksStatus {
        let calendar = CedarvilleTime.calendar
        let weekday = calendar.component(.weekday, from: date)
        let schedule = MealSchedule.schedule(for: weekday)
        
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let currentMinutes = hour * 60 + minute
        
        // Check if currently in a meal period
        for (index, meal) in schedule.enumerated() {
            if currentMinutes >= meal.startMinutes && currentMinutes < meal.endMinutes {
                let endDate = calendar.date(bySettingHour: meal.endHour, minute: meal.endMinute, second: 0, of: date)!
                let remaining = endDate.timeIntervalSince(date)
                
                let nextPhase: MealPhase?
                let nextStart: Date?
                if index + 1 < schedule.count {
                    let next = schedule[index + 1]
                    nextPhase = next.phase
                    nextStart = calendar.date(bySettingHour: next.startHour, minute: next.startMinute, second: 0, of: date)
                } else {
                    nextPhase = .closed
                    nextStart = nil
                }
                
                return ChucksStatus(
                    currentPhase: meal.phase,
                    timeRemaining: remaining,
                    nextPhase: nextPhase,
                    nextPhaseStart: nextStart,
                    isOpen: true,
                    currentMealEnd: endDate
                )
            }
            
            // Check if before this meal period
            if currentMinutes < meal.startMinutes {
                let startDate = calendar.date(bySettingHour: meal.startHour, minute: meal.startMinute, second: 0, of: date)!
                let timeUntil = startDate.timeIntervalSince(date)
                
                return ChucksStatus(
                    currentPhase: .closed,
                    timeRemaining: timeUntil,
                    nextPhase: meal.phase,
                    nextPhaseStart: startDate,
                    isOpen: false,
                    currentMealEnd: nil
                )
            }
        }
        
        // After all meals today, find tomorrow's first meal
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: date)!
        let tomorrowWeekday = calendar.component(.weekday, from: tomorrow)
        let tomorrowSchedule = MealSchedule.schedule(for: tomorrowWeekday)
        
        if let firstMeal = tomorrowSchedule.first {
            var nextStart = calendar.date(bySettingHour: firstMeal.startHour, minute: firstMeal.startMinute, second: 0, of: tomorrow)!
            if nextStart <= date {
                nextStart = calendar.date(byAdding: .day, value: 1, to: nextStart)!
            }
            let timeUntil = nextStart.timeIntervalSince(date)
            
            return ChucksStatus(
                currentPhase: .closed,
                timeRemaining: timeUntil,
                nextPhase: firstMeal.phase,
                nextPhaseStart: nextStart,
                isOpen: false,
                currentMealEnd: nil
            )
        }
        
        return ChucksStatus(
            currentPhase: .closed,
            timeRemaining: nil,
            nextPhase: nil,
            nextPhaseStart: nil,
            isOpen: false,
            currentMealEnd: nil
        )
    }
}

extension TimeInterval {
    /// Compact format for widgets: "2h" or "45m" or "30s"
    var compactCountdown: String {
        let totalSeconds = Int(self)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - API Service

actor ChucksService {
    static let shared = ChucksService()
    
    private let baseURL = "https://diningdata.cedarville.edu/api/menus"
    private var cachedMenu: MenuResponse?
    private var cacheDate: Date?
    private let cacheExpiration: TimeInterval = 3600
    
    func fetchMenu(days: Int = 5) async throws -> MenuResponse {
        if let cached = cachedMenu,
           let date = cacheDate,
           Date().timeIntervalSince(date) < cacheExpiration {
            return cached
        }
        
        guard let url = URL(string: "\(baseURL)?days=\(days)") else {
            throw ChucksError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("https://www.cedarville.edu", forHTTPHeaderField: "Origin")
        request.setValue("https://www.cedarville.edu/offices/the-commons", forHTTPHeaderField: "Referer")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ChucksError.networkError
        }
        
        let menu = try JSONDecoder().decode(MenuResponse.self, from: data)
        cachedMenu = menu
        cacheDate = Date()
        
        return menu
    }
    
    func getSpecials(for date: Date, phase: MealPhase) async throws -> (items: [MenuItem], venueName: String) {
        let venueName = "Home Cooking"
        let menu = try await fetchMenu()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "America/New_York")
        let dateKey = dateFormatter.string(from: date)
        
        guard let dayMenu = menu[dateKey] else {
            return ([], venueName)
        }
        
        let venue = dayMenu.filter { $0.venue == venueName && $0.slot == phase.apiSlot }
        return (venue.flatMap { $0.items }, venueName)
    }
}

enum ChucksError: Error {
    case invalidURL
    case networkError
    case decodingError
}

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
                    let result = try await ChucksService.shared.getSpecials(for: menuDate, phase: phase)
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
