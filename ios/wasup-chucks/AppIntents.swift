//
//  AppIntents.swift
//  wasup-chucks
//
//  Created by Kieran Klukas on 2/2/26.
//

import AppIntents

// MARK: - Check Status

struct CheckChucksStatus: AppIntent {
    static var title: LocalizedStringResource = "Check Chuck's Status"
    static var description = IntentDescription("Check if Chuck's is open or closed.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let status = ChucksStatus.calculate()

        if status.isOpen {
            if let remaining = status.timeRemaining {
                return .result(value: "Open for \(status.currentPhase.rawValue). Closes in \(remaining.compactCountdown).")
            }
            return .result(value: "Open for \(status.currentPhase.rawValue).")
        } else {
            if let next = status.nextPhase, next != .closed, let remaining = status.timeRemaining {
                return .result(value: "Closed. \(next.rawValue) starts in \(remaining.compactCountdown).")
            }
            return .result(value: "Closed for the day.")
        }
    }
}

// MARK: - Is Open

struct IsChucksOpen: AppIntent {
    static var title: LocalizedStringResource = "Is Chuck's Open"
    static var description = IntentDescription("Returns true if Chuck's is currently open.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        let status = ChucksStatus.calculate()
        return .result(value: status.isOpen)
    }
}

// MARK: - Get Menu

struct GetChucksMenu: AppIntent {
    static var title: LocalizedStringResource = "Get Chuck's Menu"
    static var description = IntentDescription("Get what's being served at Chuck's.")

    @Parameter(title: "Meal", default: .current)
    var meal: MealOption

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[String]> {
        let status = ChucksStatus.calculate()
        let phase: MealPhase

        switch meal {
        case .current:
            phase = status.isOpen ? status.currentPhase : (status.nextPhase ?? .lunch)
        case .breakfast:
            phase = .breakfast
        case .lunch:
            phase = .lunch
        case .dinner:
            phase = .dinner
        }

        if phase == .closed {
            return .result(value: [])
        }

        do {
            let items = try await ChucksService.shared.getSpecials(for: Date(), phase: phase)
            return .result(value: items.map { $0.name })
        } catch {
            return .result(value: [])
        }
    }
}

// MARK: - Get Meal Time

struct GetMealTime: AppIntent {
    static var title: LocalizedStringResource = "Get Meal Time"
    static var description = IntentDescription("Get when a meal is served at Chuck's.")

    @Parameter(title: "Meal")
    var meal: MealTimeOption

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let calendar = CedarvilleTime.calendar
        let weekday = calendar.component(.weekday, from: Date())
        let schedule = MealSchedule.schedule(for: weekday)

        let phase: MealPhase = switch meal {
        case .breakfast: .breakfast
        case .lunch: .lunch
        case .dinner: .dinner
        }

        guard let mealSchedule = schedule.first(where: { $0.phase == phase }) else {
            return .result(value: "Not served today")
        }

        let start = formatTime(mealSchedule.startHour, mealSchedule.startMinute)
        let end = formatTime(mealSchedule.endHour, mealSchedule.endMinute)
        return .result(value: "\(start) - \(end)")
    }

    private func formatTime(_ hour: Int, _ minute: Int) -> String {
        let period = hour >= 12 ? "PM" : "AM"
        let h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        return minute == 0 ? "\(h) \(period)" : "\(h):\(String(format: "%02d", minute)) \(period)"
    }
}

// MARK: - Get Current Meal Phase

struct GetCurrentMealPhase: AppIntent {
    static var title: LocalizedStringResource = "Get Current Meal Phase"
    static var description = IntentDescription("Get which meal is currently being served (or next up).")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let status = ChucksStatus.calculate()
        if status.isOpen {
            return .result(value: status.currentPhase.rawValue)
        } else if let next = status.nextPhase, next != .closed {
            return .result(value: next.rawValue)
        }
        return .result(value: "Closed")
    }
}

// MARK: - Get Minutes Until Close

struct GetMinutesUntilClose: AppIntent {
    static var title: LocalizedStringResource = "Get Minutes Until Close"
    static var description = IntentDescription("Get how many minutes until Chuck's closes. Returns 0 if already closed.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Int> {
        let status = ChucksStatus.calculate()
        guard status.isOpen, let remaining = status.timeRemaining else {
            return .result(value: 0)
        }
        return .result(value: Int(remaining / 60))
    }
}

// MARK: - Get Minutes Until Open

struct GetMinutesUntilOpen: AppIntent {
    static var title: LocalizedStringResource = "Get Minutes Until Open"
    static var description = IntentDescription("Get how many minutes until Chuck's opens. Returns 0 if already open.")

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<Int> {
        let status = ChucksStatus.calculate()
        if status.isOpen {
            return .result(value: 0)
        }
        guard let remaining = status.timeRemaining else {
            return .result(value: 0)
        }
        return .result(value: Int(remaining / 60))
    }
}

// MARK: - Parameters

enum MealOption: String, AppEnum {
    case current, breakfast, lunch, dinner

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Meal"
    static var caseDisplayRepresentations: [MealOption: DisplayRepresentation] = [
        .current: "Current",
        .breakfast: "Breakfast",
        .lunch: "Lunch",
        .dinner: "Dinner"
    ]
}

enum MealTimeOption: String, AppEnum {
    case breakfast, lunch, dinner

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Meal"
    static var caseDisplayRepresentations: [MealTimeOption: DisplayRepresentation] = [
        .breakfast: "Breakfast",
        .lunch: "Lunch",
        .dinner: "Dinner"
    ]
}
