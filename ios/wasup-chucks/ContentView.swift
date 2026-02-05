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
    @State private var allMenus: MenuResponse = [:]
    @State private var selectedDateIndex: Int = 0
    @State private var selectedFutureMeal: MealPhase = .breakfast
    @State private var isLoading = true
    @State private var loadError: Error? = nil
    @State private var selectedMeal: MealSchedule? = nil
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var currentSlot: String {
        if status.isOpen {
            return status.currentPhase.apiSlot
        } else if let next = status.nextPhase {
            return next.apiSlot
        }
        return "lunch"
    }

    private var isRegularWidth: Bool {
        horizontalSizeClass == .regular
    }

    var availableDates: [String] {
        allMenus.keys.sorted()
    }

    var isViewingToday: Bool {
        selectedDateIndex == 0
    }

    var selectedDateMenu: [VenueMenu] {
        guard selectedDateIndex < availableDates.count else { return [] }
        return allMenus[availableDates[selectedDateIndex]] ?? []
    }

    var selectedDateSchedule: [MealSchedule] {
        guard selectedDateIndex < availableDates.count else { return [] }
        let dateKey = availableDates[selectedDateIndex]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        guard let date = formatter.date(from: dateKey) else { return [] }
        let weekday = CedarvilleTime.calendar.component(.weekday, from: date)
        return MealSchedule.schedule(for: weekday)
    }

    var futureMealVenues: [VenueMenu] {
        selectedDateMenu.filter { $0.slot == selectedFutureMeal.apiSlot }
            .sorted { $0.venue < $1.venue }
    }

    var futureAlwaysAvailable: [VenueMenu] {
        selectedDateMenu.filter { $0.slot == "anytime" }
            .sorted { $0.venue < $1.venue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if availableDates.count > 1 {
                        DateNavigationHeader(
                            selectedDateIndex: $selectedDateIndex,
                            selectedFutureMeal: $selectedFutureMeal,
                            availableDates: availableDates
                        )
                    }

                    if isViewingToday {
                        // Today's view
                        if isRegularWidth {
                            HStack(spacing: 16) {
                                StatusCard(status: status)
                                    .frame(maxHeight: .infinity, alignment: .top)
                                ScheduleCard(status: status, todayMenu: todayMenu, selectedMeal: $selectedMeal)
                                    .frame(maxHeight: .infinity, alignment: .top)
                            }
                            .fixedSize(horizontal: false, vertical: true)
                        } else {
                            StatusCard(status: status)
                            ScheduleCard(status: status, todayMenu: todayMenu, selectedMeal: $selectedMeal)
                        }

                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 200)
                        } else if let error = loadError {
                            ErrorCard(error: error) {
                                Task { await loadMenu() }
                            }
                        } else {
                            CurrentMealView(menu: todayMenu, slot: currentSlot, isOpen: status.isOpen, isRegularWidth: isRegularWidth)
                        }
                    } else {
                        // Future day view
                        ScheduleCard(
                            schedule: selectedDateSchedule,
                            selectedMealPhase: $selectedFutureMeal
                        )

                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 200)
                        } else if let error = loadError {
                            ErrorCard(error: error) {
                                Task { await loadMenu() }
                            }
                        } else {
                            CurrentMealView(menu: selectedDateMenu, slot: selectedFutureMeal.apiSlot, isOpen: true, isRegularWidth: isRegularWidth)
                        }
                    }

                    // Footer
                    VStack(spacing: 4) {
                        Text("Made with \u{2665} by Kieran Klukas")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Link("Privacy Policy", destination: URL(string: "https://dunkirk.sh/wasup-chucks/")!)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.top, 16)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .frame(maxWidth: isRegularWidth ? 900 : .infinity)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Wasup Chuck's")
            .onReceive(timer) { _ in
                status = ChucksStatus.calculate()
            }
            .task {
                await loadMenu()
            }
            .refreshable {
                selectedDateIndex = 0
                await ChucksService.shared.invalidateCache()
                await loadMenu()
            }
            .sheet(item: $selectedMeal) { meal in
                MealDetailSheet(meal: meal, menu: todayMenu)
            }
        }
    }

    func loadMenu() async {
        isLoading = true
        loadError = nil
        do {
            let menu = try await ChucksService.shared.fetchMenu()
            allMenus = menu
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone(identifier: "America/New_York")
            let dateKey = dateFormatter.string(from: Date())
            todayMenu = menu[dateKey] ?? []
        } catch {
            loadError = error
            print("Failed to load menu: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Date Navigation Header

struct DateNavigationHeader: View {
    @Binding var selectedDateIndex: Int
    @Binding var selectedFutureMeal: MealPhase
    let availableDates: [String]

    private func dateLabel(for index: Int) -> String {
        guard index < availableDates.count else { return "" }
        if index == 0 { return "Today" }
        if index == 1 { return "Tomorrow" }
        let dateKey = availableDates[index]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        guard let date = formatter.date(from: dateKey) else { return dateKey }
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "EEEE, MMM d"
        displayFormatter.timeZone = TimeZone(identifier: "America/New_York")
        return displayFormatter.string(from: date)
    }

    var body: some View {
        HStack {
            Button {
                selectedDateIndex -= 1
                selectedFutureMeal = .breakfast
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
            }
            .disabled(selectedDateIndex <= 0)
            .modifier(LiquidGlassButtonModifier())

            Spacer()

            Text(dateLabel(for: selectedDateIndex))
                .font(.headline)
                .animation(.easeInOut, value: selectedDateIndex)

            Spacer()

            Button {
                selectedDateIndex += 1
                selectedFutureMeal = .breakfast
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
            }
            .disabled(selectedDateIndex >= availableDates.count - 1)
            .modifier(LiquidGlassButtonModifier())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
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
                    .modifier(NumericContentTransition())
                
                Text(status.isOpen ? "until \(status.currentPhase.shortName) ends" : "until \(status.nextPhase?.shortName ?? "open")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Error Card

struct ErrorCard: View {
    let error: Error
    let retry: () -> Void

    private var errorMessage: String {
        if let chucksError = error as? ChucksError {
            switch chucksError {
            case .invalidURL:
                return "There was a problem with the request."
            case .networkError:
                return "Couldn't connect to the server. Check your internet connection."
            case .decodingError:
                return "The menu data couldn't be read."
            }
        }
        return "Something went wrong loading the menu."
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("Menu Unavailable")
                .font(.headline)

            Text(errorMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(action: retry) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Schedule Card

struct ScheduleCard: View {
    let title: String
    let schedule: [MealSchedule]
    let status: ChucksStatus?
    @Binding var selectedMeal: MealSchedule?
    var selectedMealPhase: Binding<MealPhase>?

    /// Today mode: shows schedule with sheet on tap
    init(status: ChucksStatus, todayMenu: [VenueMenu], selectedMeal: Binding<MealSchedule?>) {
        self.title = "Today's Schedule"
        self.schedule = MealSchedule.schedule(for: CedarvilleTime.calendar.component(.weekday, from: Date()))
        self.status = status
        self._selectedMeal = selectedMeal
        self.selectedMealPhase = nil
    }

    /// Future day mode: shows schedule with tab selection
    init(schedule: [MealSchedule], selectedMealPhase: Binding<MealPhase>) {
        self.title = "Schedule"
        self.schedule = schedule
        self.status = nil
        self._selectedMeal = .constant(nil)
        self.selectedMealPhase = selectedMealPhase
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(schedule, id: \.phase) { meal in
                    if let binding = selectedMealPhase {
                        ScheduleButton(
                            meal: meal,
                            isCurrent: false,
                            isSelected: binding.wrappedValue == meal.phase
                        ) {
                            binding.wrappedValue = meal.phase
                        }
                    } else {
                        ScheduleButton(
                            meal: meal,
                            isCurrent: status?.isOpen == true && status?.currentPhase == meal.phase
                        ) {
                            selectedMeal = meal
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

struct ScheduleButton: View {
    let meal: MealSchedule
    let isCurrent: Bool
    var isSelected: Bool = false
    let action: () -> Void

    private var isHighlighted: Bool {
        isCurrent || isSelected
    }

    private var highlightColor: Color {
        isSelected ? .orange : .green
    }

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
            .background(isHighlighted ? highlightColor.opacity(0.15) : Color.clear, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isHighlighted ? highlightColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(isHighlighted ? highlightColor : .primary)
        .selectionHaptic(trigger: meal.phase)
        .accessibilityLabel("\(meal.phase.shortName), \(formatTime(meal.startHour, meal.startMinute)) to \(formatTime(meal.endHour, meal.endMinute))\(isCurrent ? ", current meal" : "")\(isSelected ? ", selected" : "")")
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
                    if #available(iOS 17.0, *) {
                        ContentUnavailableView(
                            "No Menu Available",
                            systemImage: "fork.knife.circle",
                            description: Text("No specific menu items for \(meal.phase.rawValue) today.")
                        )
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "fork.knife.circle")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("No Menu Available")
                                .font(.headline)
                            Text("No specific menu items for \(meal.phase.rawValue) today.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
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
    let isRegularWidth: Bool

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
            // Meal Specials Section
            if !mealSpecificVenues.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Label("\(mealLabel) Specials", systemImage: "clock.fill")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 4)

                    MasonryLayout(mealSpecificVenues, columns: isRegularWidth ? 2 : 1, spacing: 12) { venue in
                        VenueCard(venue: venue)
                    }
                }
            }

            // Always Available Section
            if !alwaysAvailableVenues.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    if !mealSpecificVenues.isEmpty {
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
                        .padding(.top, 8)
                    }

                    MasonryLayout(alwaysAvailableVenues, columns: isRegularWidth ? 2 : 1, spacing: 12) { venue in
                        VenueCard(venue: venue)
                    }
                }
            }
        }
    }
}

// MARK: - Masonry Layout

struct MasonryLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Identifiable {
    let data: Data
    let columns: Int
    let spacing: CGFloat
    let content: (Data.Element) -> Content

    init(_ data: Data, columns: Int = 2, spacing: CGFloat = 12, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.columns = columns
        self.spacing = spacing
        self.content = content
    }

    private func itemsForColumn(_ column: Int) -> [Data.Element] {
        data.enumerated().compactMap { index, item in
            index % columns == column ? item : nil
        }
    }

    var body: some View {
        if columns == 1 {
            VStack(spacing: spacing) {
                ForEach(data) { item in
                    content(item)
                }
            }
        } else {
            HStack(alignment: .top, spacing: spacing) {
                ForEach(0..<columns, id: \.self) { column in
                    VStack(spacing: spacing) {
                        ForEach(itemsForColumn(column)) { item in
                            content(item)
                        }
                    }
                }
            }
        }
    }
}

struct VenueCard: View {
    let venue: VenueMenu
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
            Text(venue.venue)
                .font(.subheadline.weight(.semibold))
        }
        .tint(.orange)
        .selectionHaptic(trigger: isExpanded)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
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

// MARK: - Liquid Glass Button

struct LiquidGlassButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glass)
        } else {
            content.buttonStyle(.bordered)
        }
    }
}

// MARK: - iOS 16 Compatibility

struct NumericContentTransition: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.contentTransition(.numericText())
        } else {
            content
        }
    }
}

struct SelectionHaptic: ViewModifier {
    let trigger: AnyHashable

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.sensoryFeedback(.selection, trigger: trigger)
        } else {
            content.onChange(of: trigger) { _ in
                UISelectionFeedbackGenerator().selectionChanged()
            }
        }
    }
}

extension View {
    func selectionHaptic<T: Hashable>(trigger: T) -> some View {
        modifier(SelectionHaptic(trigger: AnyHashable(trigger)))
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}

#Preview("Error - Network") {
    ErrorCard(error: ChucksError.networkError) {}
        .padding()
}

#Preview("Error - Decoding") {
    ErrorCard(error: ChucksError.decodingError(underlying: NSError(domain: "Preview", code: 0, userInfo: [NSLocalizedDescriptionKey: "Sample decoding error"]))) {}
        .padding()
}
