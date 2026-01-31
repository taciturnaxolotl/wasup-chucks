//
//  ContentView.swift
//  wasup-chucks
//
//  Created by Kieran Klukas on 1/30/26.
//

import SwiftUI
internal import Combine

// MARK: - Main View

struct ContentView: View {
    @State private var status = ChucksStatus.calculate()
    @State private var todayMenu: [VenueMenu] = []
    @State private var isLoading = true
    @State private var selectedMeal: MealSchedule? = nil
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var currentSlot: String {
        if status.isOpen {
            return status.currentPhase.apiSlot
        } else if let next = status.nextPhase {
            return next.apiSlot
        }
        return "lunch"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    StatusCard(status: status)
                    
                    ScheduleCard(status: status, todayMenu: todayMenu, selectedMeal: $selectedMeal)
                    
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        CurrentMealView(menu: todayMenu, slot: currentSlot, isOpen: status.isOpen)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .navigationTitle("Wasup Chucks")
            .onReceive(timer) { _ in
                status = ChucksStatus.calculate()
            }
            .task {
                await loadMenu()
            }
            .refreshable {
                await loadMenu()
            }
            .sheet(item: $selectedMeal) { meal in
                MealDetailSheet(meal: meal, menu: todayMenu)
            }
        }
    }
    
    func loadMenu() async {
        isLoading = true
        do {
            let menu = try await ChucksService.shared.fetchMenu()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone(identifier: "America/New_York")
            let dateKey = dateFormatter.string(from: Date())
            todayMenu = menu[dateKey] ?? []
        } catch {
            print("Failed to load menu: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Status Card

struct StatusCard: View {
    let status: ChucksStatus
    
    private var statusColor: Color {
        status.isOpen ? .green : .orange
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: status.isOpen ? status.currentPhase.icon : (status.nextPhase?.icon ?? "moon.zzz.fill"))
                    .font(.title2)
                    .foregroundStyle(statusColor)
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(status.isOpen ? "Open" : "Closed")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(statusColor)
                    Text(status.isOpen ? status.currentPhase.rawValue : (status.nextPhase?.rawValue ?? ""))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(status.isOpen ? "Chuck's is currently open for \(status.currentPhase.rawValue)" : "Chuck's is closed")
            
            if let remaining = status.timeRemaining {
                Text(remaining.expandedCountdown)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                
                Text(status.isOpen ? "until \(status.currentPhase.shortName) ends" : "until \(status.nextPhase?.shortName ?? "open")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Schedule Card

struct ScheduleCard: View {
    let status: ChucksStatus
    let todayMenu: [VenueMenu]
    @Binding var selectedMeal: MealSchedule?
    
    var schedule: [MealSchedule] {
        MealSchedule.schedule(for: Calendar.current.component(.weekday, from: Date()))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Schedule")
                .font(.headline)
            
            HStack(spacing: 8) {
                ForEach(schedule, id: \.phase) { meal in
                    ScheduleButton(
                        meal: meal,
                        isCurrent: status.isOpen && status.currentPhase == meal.phase
                    ) {
                        selectedMeal = meal
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

struct ScheduleButton: View {
    let meal: MealSchedule
    let isCurrent: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: meal.phase.icon)
                    .font(.title3)
                    .accessibilityHidden(true)
                
                Text(meal.phase.shortName)
                    .font(.caption.weight(.medium))
                
                Text("\(formatTime(meal.startHour, meal.startMinute))-\(formatTime(meal.endHour, meal.endMinute))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isCurrent ? Color.green.opacity(0.15) : Color.clear, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCurrent ? Color.green : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(isCurrent ? .green : .primary)
        .sensoryFeedback(.selection, trigger: meal.phase)
        .accessibilityLabel("\(meal.phase.shortName), \(formatTime(meal.startHour, meal.startMinute)) to \(formatTime(meal.endHour, meal.endMinute))\(isCurrent ? ", current meal" : "")")
        .accessibilityHint("Double tap to view menu")
    }
    
    func formatTime(_ hour: Int, _ minute: Int) -> String {
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        if minute == 0 {
            return "\(displayHour)\(period)"
        }
        return "\(displayHour):\(String(format: "%02d", minute))\(period)"
    }
}

// MARK: - Meal Detail Sheet

struct MealDetailSheet: View {
    let meal: MealSchedule
    let menu: [VenueMenu]
    @Environment(\.dismiss) private var dismiss
    
    var venues: [VenueMenu] {
        menu.filter { $0.slot == meal.phase.apiSlot }
            .sorted { $0.venue < $1.venue }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if venues.isEmpty {
                    ContentUnavailableView(
                        "No Menu Available",
                        systemImage: "fork.knife.circle",
                        description: Text("No specific menu items for \(meal.phase.rawValue) today.")
                    )
                } else {
                    List {
                        ForEach(venues) { venue in
                            Section {
                                ForEach(venue.items) { item in
                                    HStack {
                                        Text(item.name)
                                            .font(.body)
                                        Spacer()
                                        AllergenRow(allergens: item.allergens)
                                    }
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel("\(item.name), \(item.allergens.map { $0.alt }.joined(separator: ", "))")
                                }
                            } header: {
                                Text(venue.venue)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(meal.phase.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Current Meal View

struct CurrentMealView: View {
    let menu: [VenueMenu]
    let slot: String
    let isOpen: Bool
    
    var mealSpecificVenues: [VenueMenu] {
        menu.filter { $0.slot == slot }
            .sorted { $0.venue < $1.venue }
    }
    
    var alwaysAvailableVenues: [VenueMenu] {
        menu.filter { $0.slot == "anytime" }
            .sorted { $0.venue < $1.venue }
    }
    
    var mealLabel: String {
        switch slot {
        case "breakfast": return "Breakfast"
        case "lunch": return "Lunch"
        case "dinner": return "Dinner"
        default: return "This Meal"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !mealSpecificVenues.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Label("\(mealLabel) Specials", systemImage: "clock.fill")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    ForEach(mealSpecificVenues) { venue in
                        VenueSection(venue: venue, isHighlighted: venue.venue == "Home Cooking")
                    }
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            }
            
            if !mealSpecificVenues.isEmpty && !alwaysAvailableVenues.isEmpty {
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(.secondary.opacity(0.3))
                        .frame(height: 1)
                    Text("Always Available")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Rectangle()
                        .fill(.secondary.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.vertical, 8)
            }
            
            if !alwaysAvailableVenues.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(alwaysAvailableVenues) { venue in
                        VenueSection(venue: venue, isHighlighted: false)
                    }
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            }
        }
    }
}

struct VenueSection: View {
    let venue: VenueMenu
    let isHighlighted: Bool
    @State private var isExpanded = true
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(venue.items) { item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(.secondary.opacity(0.5))
                            .frame(width: 4, height: 4)
                        Text(item.name)
                            .font(.subheadline)
                        Spacer()
                        AllergenRow(allergens: item.allergens)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(item.name)")
                }
            }
            .padding(.top, 8)
        } label: {
            HStack(spacing: 6) {
                Text(venue.venue)
                    .font(.subheadline.weight(.semibold))
            }
        }
        .sensoryFeedback(.selection, trigger: isExpanded)
    }
}

// MARK: - Allergen Row

struct AllergenRow: View {
    let allergens: [Allergen]
    
    var body: some View {
        if !allergens.isEmpty {
            HStack(spacing: 4) {
                ForEach(allergens, id: \.alt) { allergen in
                    AllergenBadge(allergen: allergen)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Contains: \(allergens.map { allergenName($0.alt) }.joined(separator: ", "))")
        }
    }
    
    private func allergenName(_ alt: String) -> String {
        switch alt {
        case "gluten": return "gluten"
        case "dairy": return "dairy"
        case "egg": return "egg"
        case "soy": return "soy"
        case "fish": return "fish"
        case "hasPeanut": return "peanuts"
        case "tree nut": return "tree nuts"
        case "hasShellfish": return "shellfish"
        case "vegetarian": return "vegetarian"
        case "gluten-free": return "gluten-free"
        default: return alt
        }
    }
}

struct AllergenBadge: View {
    let allergen: Allergen
    
    var symbol: String {
        switch allergen.alt {
        case "gluten": return "G"
        case "dairy": return "D"
        case "egg": return "E"
        case "soy": return "S"
        case "fish": return "F"
        case "hasPeanut": return "P"
        case "tree nut": return "N"
        case "hasShellfish": return "SF"
        case "vegetarian": return "V"
        case "gluten-free": return "GF"
        default: return "?"
        }
    }
    
    var color: Color {
        switch allergen.alt {
        case "vegetarian", "gluten-free": return .green
        default: return .orange
        }
    }
    
    var body: some View {
        Text(symbol)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 3)
            .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 4))
            .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
