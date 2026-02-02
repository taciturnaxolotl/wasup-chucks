//
//  SiriIntents.swift
//  wasup-chucks
//
//  Created by Kieran Klukas on 2/2/26.
//

import AppIntents

// MARK: - Chuck's Status Intent

struct ChucksStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Chuck's Status"
    static var description = IntentDescription("Check if Chuck's dining hall is currently open or closed.")
    static var openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let status = ChucksStatus.calculate()

        if status.isOpen {
            if let remaining = status.timeRemaining {
                let timeStr = remaining.compactCountdown
                return .result(dialog: "Chuck's is open for \(status.currentPhase.rawValue). It closes in \(timeStr).")
            } else {
                return .result(dialog: "Chuck's is open for \(status.currentPhase.rawValue).")
            }
        } else {
            if let next = status.nextPhase, next != .closed, let remaining = status.timeRemaining {
                let timeStr = remaining.compactCountdown
                return .result(dialog: "Chuck's is closed. \(next.rawValue) starts in \(timeStr).")
            } else {
                return .result(dialog: "Chuck's is closed for the day.")
            }
        }
    }
}

// MARK: - Chuck's Menu Intent

struct ChucksMenuIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Chuck's Menu"
    static var description = IntentDescription("Find out what's being served at Chuck's.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Meal", default: .current)
    var meal: MealParameter

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
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
            return .result(dialog: "Chuck's is closed for the day. Check back tomorrow!")
        }

        do {
            let items = try await ChucksService.shared.getSpecials(for: Date(), phase: phase)
            if items.isEmpty {
                return .result(dialog: "I couldn't find the menu for \(phase.rawValue) right now.")
            }

            let itemNames = items.prefix(5).map { $0.name }.joined(separator: ", ")
            return .result(dialog: "For \(phase.rawValue) at Home Cooking: \(itemNames).")
        } catch {
            return .result(dialog: "I couldn't load the menu right now. Try again later.")
        }
    }
}

// MARK: - Meal Time Intent

struct ChucksMealTimeIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Meal Time"
    static var description = IntentDescription("Find out what time a meal is served at Chuck's.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Meal")
    var meal: MealTimeParameter

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let calendar = CedarvilleTime.calendar
        let weekday = calendar.component(.weekday, from: Date())
        let schedule = MealSchedule.schedule(for: weekday)

        let phase: MealPhase
        switch meal {
        case .breakfast:
            phase = .breakfast
        case .lunch:
            phase = .lunch
        case .dinner:
            phase = .dinner
        }

        guard let mealSchedule = schedule.first(where: { $0.phase == phase }) else {
            return .result(dialog: "\(phase.rawValue) isn't served today.")
        }

        let startTime = formatTime(mealSchedule.startHour, mealSchedule.startMinute)
        let endTime = formatTime(mealSchedule.endHour, mealSchedule.endMinute)

        return .result(dialog: "\(phase.rawValue) is served from \(startTime) to \(endTime) today.")
    }

    private func formatTime(_ hour: Int, _ minute: Int) -> String {
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        if minute == 0 {
            return "\(displayHour) \(period)"
        }
        return "\(displayHour):\(String(format: "%02d", minute)) \(period)"
    }
}

// MARK: - Meal Parameters

enum MealTimeParameter: String, AppEnum {
    case breakfast
    case lunch
    case dinner

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Meal"

    static var caseDisplayRepresentations: [MealTimeParameter: DisplayRepresentation] = [
        .breakfast: "Breakfast",
        .lunch: "Lunch",
        .dinner: "Dinner"
    ]
}

enum MealParameter: String, AppEnum {
    case current
    case breakfast
    case lunch
    case dinner

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Meal"

    static var caseDisplayRepresentations: [MealParameter: DisplayRepresentation] = [
        .current: "Current Meal",
        .breakfast: "Breakfast",
        .lunch: "Lunch",
        .dinner: "Dinner"
    ]
}

// MARK: - App Shortcuts

struct ChucksShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ChucksStatusIntent(),
            phrases: [
                "Is \(.applicationName) open",
                "Check \(.applicationName) status",
                "When does \(.applicationName) open",
                "When does \(.applicationName) close"
            ],
            shortTitle: "Chuck's Status",
            systemImageName: "fork.knife.circle"
        )

        AppShortcut(
            intent: ChucksMenuIntent(),
            phrases: [
                "What's for \(\.$meal) at \(.applicationName)",
                "\(.applicationName) menu",
                "What's being served at \(.applicationName)"
            ],
            shortTitle: "Chuck's Menu",
            systemImageName: "menucard"
        )

        AppShortcut(
            intent: ChucksMealTimeIntent(),
            phrases: [
                "What time is \(\.$meal) at \(.applicationName)",
                "When is \(\.$meal) at \(.applicationName)",
                "\(.applicationName) \(\.$meal) hours"
            ],
            shortTitle: "Meal Times",
            systemImageName: "clock"
        )
    }
}
