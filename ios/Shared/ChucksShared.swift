//
//  ChucksShared.swift
//  wasup-chucks
//
//  Shared models and services for main app and widget.
//

import Foundation

// MARK: - API Models

public struct Allergen: Codable, Hashable, Sendable {
    public let url: String
    public let alt: String

    public nonisolated init(url: String, alt: String) {
        self.url = url
        self.alt = alt
    }
}

public struct MenuItem: Codable, Hashable, Identifiable, Sendable {
    public let name: String
    public let allergens: [Allergen]

    public nonisolated var id: String { "\(name)-\(allergens.map { $0.alt }.joined())" }

    public nonisolated init(name: String, allergens: [Allergen]) {
        self.name = name
        self.allergens = allergens
    }
}

public struct VenueMenu: Codable, Hashable, Identifiable, Sendable {
    public let venue: String
    public let meal: String?
    public let slot: String
    public let items: [MenuItem]

    public nonisolated var id: String { "\(venue)-\(slot)-\(meal ?? "")" }

    public nonisolated init(venue: String, meal: String?, slot: String, items: [MenuItem]) {
        self.venue = venue
        self.meal = meal
        self.slot = slot
        self.items = items
    }
}

public typealias MenuResponse = [String: [VenueMenu]]

// MARK: - Meal Phase

public enum MealPhase: String, CaseIterable, Sendable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case closed = "Closed"

    public nonisolated var icon: String {
        switch self {
        case .breakfast: return "cup.and.saucer.fill"
        case .lunch: return "takeoutbag.and.cup.and.straw.fill"
        case .dinner: return "fork.knife.circle.fill"
        case .closed: return "moon.zzz.fill"
        }
    }

    public nonisolated var shortName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .closed: return "Closed"
        }
    }

    public nonisolated var apiSlot: String {
        switch self {
        case .breakfast: return "breakfast"
        case .lunch: return "lunch"
        case .dinner: return "dinner"
        case .closed: return ""
        }
    }
}

// MARK: - Meal Schedule

public struct MealSchedule: Identifiable, Sendable {
    public nonisolated var id: String { phase.rawValue }
    public let phase: MealPhase
    public let startHour: Int
    public let startMinute: Int
    public let endHour: Int
    public let endMinute: Int

    public nonisolated var startMinutes: Int { startHour * 60 + startMinute }
    public nonisolated var endMinutes: Int { endHour * 60 + endMinute }

    public nonisolated init(phase: MealPhase, startHour: Int, startMinute: Int, endHour: Int, endMinute: Int) {
        self.phase = phase
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
    }

    // Mon-Fri: Hot Breakfast 7-8:15, Continental 8:15-9:30, Lunch 10:30-2:30, Dinner 4:30-7:30
    // Treating Hot + Continental as one "Breakfast" period for simplicity
    public nonisolated static let weekdaySchedule: [MealSchedule] = [
        MealSchedule(phase: .breakfast, startHour: 7, startMinute: 0, endHour: 9, endMinute: 30),
        MealSchedule(phase: .lunch, startHour: 10, startMinute: 30, endHour: 14, endMinute: 30),
        MealSchedule(phase: .dinner, startHour: 16, startMinute: 30, endHour: 19, endMinute: 30)
    ]

    // Saturday: Continental 8-9, Lunch 11-1, Dinner 4:30-6:30
    public nonisolated static let saturdaySchedule: [MealSchedule] = [
        MealSchedule(phase: .breakfast, startHour: 8, startMinute: 0, endHour: 9, endMinute: 0),
        MealSchedule(phase: .lunch, startHour: 11, startMinute: 0, endHour: 13, endMinute: 0),
        MealSchedule(phase: .dinner, startHour: 16, startMinute: 30, endHour: 18, endMinute: 30)
    ]

    // Sunday: Hot Breakfast 8-9, Lunch 11:30-2, Dinner 5-7:30
    public nonisolated static let sundaySchedule: [MealSchedule] = [
        MealSchedule(phase: .breakfast, startHour: 8, startMinute: 0, endHour: 9, endMinute: 0),
        MealSchedule(phase: .lunch, startHour: 11, startMinute: 30, endHour: 14, endMinute: 0),
        MealSchedule(phase: .dinner, startHour: 17, startMinute: 0, endHour: 19, endMinute: 30)
    ]

    public nonisolated static func schedule(for weekday: Int) -> [MealSchedule] {
        switch weekday {
        case 1: return sundaySchedule
        case 7: return saturdaySchedule
        default: return weekdaySchedule
        }
    }
}

// MARK: - Cedarville Timezone

public struct CedarvilleTime: Sendable {
    public nonisolated static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .current
        return calendar
    }
}

// MARK: - Chuck's Status

public struct ChucksStatus: Sendable {
    public let currentPhase: MealPhase
    public let timeRemaining: TimeInterval?
    public let nextPhase: MealPhase?
    public let nextPhaseStart: Date?
    public let isOpen: Bool
    public let currentMealEnd: Date?

    public nonisolated init(currentPhase: MealPhase, timeRemaining: TimeInterval?, nextPhase: MealPhase?, nextPhaseStart: Date?, isOpen: Bool, currentMealEnd: Date?) {
        self.currentPhase = currentPhase
        self.timeRemaining = timeRemaining
        self.nextPhase = nextPhase
        self.nextPhaseStart = nextPhaseStart
        self.isOpen = isOpen
        self.currentMealEnd = currentMealEnd
    }

    public nonisolated static func calculate(for date: Date = Date()) -> ChucksStatus {
        let calendar = CedarvilleTime.calendar
        let weekday = calendar.component(.weekday, from: date)
        let schedule = MealSchedule.schedule(for: weekday)

        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let currentMinutes = hour * 60 + minute

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

// MARK: - TimeInterval Extension

extension TimeInterval {
    /// Compact format for widgets: "2h" or "45m" or "30s"
    public nonisolated var compactCountdown: String {
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

    /// Expanded format for app: "2h 15m" or "45m" or "30s"
    public nonisolated var expandedCountdown: String {
        let totalSeconds = Int(self)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - Persistent Cache

private enum MenuCacheIO: Sendable {
    nonisolated static func load(from directory: URL) -> (menu: MenuResponse, cacheDate: Date)? {
        let menuURL = directory.appendingPathComponent("menu_cache.json")
        let metaURL = directory.appendingPathComponent("menu_cache_meta.plist")

        guard FileManager.default.fileExists(atPath: menuURL.path),
              FileManager.default.fileExists(atPath: metaURL.path) else { return nil }

        do {
            let menuData = try Data(contentsOf: menuURL)
            let menu = try JSONDecoder().decode(MenuResponse.self, from: menuData)

            let metaData = try Data(contentsOf: metaURL)
            guard let meta = try PropertyListSerialization.propertyList(from: metaData, format: nil) as? [String: Any],
                  let timestamp = meta["cacheTimestamp"] as? Date else { return nil }

            return (menu, timestamp)
        } catch {
            return nil
        }
    }

    nonisolated static func save(menu: MenuResponse, to directory: URL) {
        let menuURL = directory.appendingPathComponent("menu_cache.json")
        let metaURL = directory.appendingPathComponent("menu_cache_meta.plist")

        do {
            let menuData = try JSONEncoder().encode(menu)
            try menuData.write(to: menuURL)

            let meta: [String: Any] = ["cacheTimestamp": Date()]
            let metaData = try PropertyListSerialization.data(fromPropertyList: meta, format: .binary, options: 0)
            try metaData.write(to: metaURL)
        } catch {
            // Ignore save errors
        }
    }

    nonisolated static func delete(from directory: URL) {
        let menuURL = directory.appendingPathComponent("menu_cache.json")
        let metaURL = directory.appendingPathComponent("menu_cache_meta.plist")
        try? FileManager.default.removeItem(at: menuURL)
        try? FileManager.default.removeItem(at: metaURL)
    }
}

// MARK: - API Service

public actor ChucksService {
    public static let shared = ChucksService()

    private let baseURL = "https://diningdata.cedarville.edu/api/menus"
    private var cachedMenu: MenuResponse?
    private var cacheDate: Date?
    private let cacheExpiration: TimeInterval = 12 * 60 * 60 // 12 hours

    private static let appGroupID = "group.sh.dunkirk.wasup-chucks"

    private var cacheDirectory: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupID)
    }

    public init() {
        // Load persistent cache on init
        Task { await loadPersistentCache() }
    }

    private func loadPersistentCache() {
        guard let dir = cacheDirectory,
              let cached = MenuCacheIO.load(from: dir) else { return }
        self.cachedMenu = cached.menu
        self.cacheDate = cached.cacheDate
    }

    private func savePersistentCache(menu: MenuResponse) {
        guard let dir = cacheDirectory else { return }
        MenuCacheIO.save(menu: menu, to: dir)
    }

    public func invalidateCache() {
        cachedMenu = nil
        cacheDate = nil
        if let dir = cacheDirectory {
            MenuCacheIO.delete(from: dir)
        }
    }

    public func fetchMenu(days: Int = 5) async throws -> MenuResponse {
        // Check in-memory cache first
        if let cached = cachedMenu,
           let date = cacheDate,
           Date().timeIntervalSince(date) < cacheExpiration {
            return cached
        }

        // Check persistent cache
        if cachedMenu == nil {
            loadPersistentCache()
            if let cached = cachedMenu,
               let date = cacheDate,
               Date().timeIntervalSince(date) < cacheExpiration {
                return cached
            }
        }

        guard let url = URL(string: "\(baseURL)?days=\(days)") else {
            throw ChucksError.invalidURL
        }

        var request = URLRequest(url: url, timeoutInterval: 30)
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("https://www.cedarville.edu", forHTTPHeaderField: "Origin")
        request.setValue("https://www.cedarville.edu/offices/the-commons", forHTTPHeaderField: "Referer")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                // Return stale cache on network error if available
                if let cached = cachedMenu {
                    return cached
                }
                throw ChucksError.networkError
            }

            let menu: MenuResponse
            do {
                menu = try JSONDecoder().decode(MenuResponse.self, from: data)
            } catch {
                throw ChucksError.decodingError(underlying: error)
            }
            cachedMenu = menu
            cacheDate = Date()
            savePersistentCache(menu: menu)

            return menu
        } catch let error as ChucksError {
            throw error
        } catch {
            // Return stale cache on network error if available
            if let cached = cachedMenu {
                return cached
            }
            throw ChucksError.networkError
        }
    }

    public func getSpecials(for date: Date, phase: MealPhase) async throws -> [MenuItem] {
        let menu = try await fetchMenu()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "America/New_York")
        let dateKey = dateFormatter.string(from: date)

        guard let dayMenu = menu[dateKey] else {
            return []
        }

        let slot = phase.apiSlot
        let homeCooking = dayMenu.filter { $0.venue == "Home Cooking" && $0.slot == slot }
        return homeCooking.flatMap { $0.items }
    }

    public func getSpecialsWithVenue(for date: Date, phase: MealPhase) async throws -> (items: [MenuItem], venueName: String) {
        let venueName = "Home Cooking"
        let items = try await getSpecials(for: date, phase: phase)
        return (items, venueName)
    }
}

public enum ChucksError: Error, LocalizedError, Sendable {
    case invalidURL
    case networkError
    case decodingError(underlying: Error)

    public nonisolated var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError:
            return "Network error"
        case .decodingError(let underlying):
            return "Failed to parse menu data: \(underlying.localizedDescription)"
        }
    }
}
