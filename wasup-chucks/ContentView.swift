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
                VStack(spacing: 20) {
                    StatusCard(status: status)
                    
                    ScheduleCard(status: status, todayMenu: todayMenu, selectedMeal: $selectedMeal)
                    
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        CurrentMealView(menu: todayMenu, slot: currentSlot, isOpen: status.isOpen)
                    }
                }
                .padding(.horizontal)
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
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: status.isOpen ? status.currentPhase.icon : (status.nextPhase?.icon ?? "moon.zzz.fill"))
                    .font(.title2)
                    .foregroundStyle(status.isOpen ? .green : .orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(status.isOpen ? "Open" : "Closed")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(status.isOpen ? .green : .orange)
                    Text(status.isOpen ? status.currentPhase.rawValue : (status.nextPhase?.rawValue ?? ""))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            if let remaining = status.timeRemaining {
                Text(remaining.countdownText)
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .monospacedDigit()
                
                Text(status.isOpen ? "until \(status.currentPhase.shortName) ends" : "until \(status.nextPhase?.shortName ?? "open")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ScheduleButton: View {
    let meal: MealSchedule
    let isCurrent: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: meal.phase.icon)
                    .font(.title3)
                
                Text(meal.phase.shortName)
                    .font(.caption2)
                    .fontWeight(.medium)
                
                Text("\(formatTime(meal.startHour, meal.startMinute))-\(formatTime(meal.endHour, meal.endMinute))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isCurrent ? Color.green : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(isCurrent ? .green : .primary)
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
        let matching = menu.filter { $0.slot == meal.phase.apiSlot || $0.slot == "anytime" }
        // Merge venues that appear with both meal-specific and anytime slots
        var merged: [String: VenueMenu] = [:]
        for venue in matching {
            if let existing = merged[venue.venue] {
                // Combine items, preferring meal-specific slot
                let combinedItems = existing.items + venue.items.filter { item in
                    !existing.items.contains { $0.name == item.name }
                }
                let preferredSlot = existing.slot != "anytime" ? existing.slot : venue.slot
                merged[venue.venue] = VenueMenu(venue: venue.venue, meal: venue.meal ?? existing.meal, slot: preferredSlot, items: combinedItems)
            } else {
                merged[venue.venue] = venue
            }
        }
        return Array(merged.values).sorted { $0.venue < $1.venue }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(venues) { venue in
                        StationCard(venue: venue, highlightAsSpecial: venue.venue == "Home Cooking")
                    }
                }
                .padding()
            }
            .navigationTitle(meal.phase.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Current Meal View

struct CurrentMealView: View {
    let menu: [VenueMenu]
    let slot: String
    let isOpen: Bool
    
    var specialsVenue: VenueMenu? {
        menu.first { $0.venue == "Home Cooking" && $0.slot == slot }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let specials = specialsVenue, !specials.items.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Home Cooking")
                        .font(.headline)
                    
                    ForEach(specials.items) { item in
                        HStack(spacing: 8) {
                            Text("•")
                                .foregroundStyle(.secondary)
                            Text(item.name)
                                .font(.body)
                            Spacer()
                            AllergenRow(allergens: item.allergens)
                        }
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Station Card

struct StationCard: View {
    let venue: VenueMenu
    let highlightAsSpecial: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if highlightAsSpecial {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
                Text(venue.venue)
                    .font(.headline)
                Spacer()
            }
            
            ForEach(venue.items) { item in
                HStack(spacing: 8) {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(item.name)
                        .font(.subheadline)
                    Spacer()
                    AllergenRow(allergens: item.allergens)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Allergen Row

struct AllergenRow: View {
    let allergens: [Allergen]
    
    var body: some View {
        if !allergens.isEmpty {
            HStack(spacing: 2) {
                ForEach(allergens, id: \.alt) { allergen in
                    AllergenBadge(allergen: allergen)
                }
            }
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
            .font(.system(size: 8, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
