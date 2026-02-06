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
    @StateObject private var favoritesStore = FavoritesStore()
    @State private var showFavoritesManager = false
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
        NavigationStack {
            Group {
                if availableDates.count > 1 {
                    TabView(selection: $selectedDateIndex) {
                        ForEach(availableDates.indices, id: \.self) { index in
                            dayPage(for: index)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .ignoresSafeArea(.container, edges: .bottom)
                    .onChange(of: selectedDateIndex) { _ in
                        selectedFutureMeal = .breakfast
                    }
                } else {
                    dayPage(for: 0)
                }
            }
            .navigationTitle("Wasup Chuck's")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if availableDates.count > 1 {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            withAnimation { selectedDateIndex -= 1 }
                            selectedFutureMeal = .breakfast
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .disabled(selectedDateIndex <= 0)
                    }
                    ToolbarItem(placement: .principal) {
                        Text(dateLabel(for: selectedDateIndex))
                            .font(.headline)
                            .animation(.easeInOut, value: selectedDateIndex)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 12) {
                            Button {
                                showFavoritesManager = true
                            } label: {
                                Image(systemName: "star.fill")
                            }
                            .tint(.orange)
                            Button {
                                withAnimation { selectedDateIndex += 1 }
                                selectedFutureMeal = .breakfast
                            } label: {
                                Image(systemName: "chevron.right")
                            }
                            .disabled(selectedDateIndex >= availableDates.count - 1)
                        }
                    }
                } else {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showFavoritesManager = true
                        } label: {
                            Image(systemName: "star.fill")
                        }
                        .tint(.orange)
                    }
                }
            }
            .onReceive(timer) { _ in
                status = ChucksStatus.calculate()
            }
            .task {
                await loadMenu()
            }
            .sheet(item: $selectedMeal) { meal in
                MealDetailSheet(meal: meal, menu: todayMenu, favoritesStore: favoritesStore)
            }
            .sheet(isPresented: $showFavoritesManager) {
                FavoritesManagerSheet(favoritesStore: favoritesStore)
            }
            .onChange(of: favoritesStore.favoriteItems) { _ in
                if !favoritesStore.favoriteItems.isEmpty || !favoritesStore.favoriteKeywords.isEmpty {
                    NotificationScheduler.shared.requestPermissionIfNeeded()
                }
                NotificationScheduler.shared.reschedule(
                    menus: allMenus,
                    favoriteItems: favoritesStore.favoriteItems,
                    favoriteKeywords: favoritesStore.favoriteKeywords
                )
            }
            .onChange(of: favoritesStore.favoriteKeywords) { _ in
                if !favoritesStore.favoriteItems.isEmpty || !favoritesStore.favoriteKeywords.isEmpty {
                    NotificationScheduler.shared.requestPermissionIfNeeded()
                }
                NotificationScheduler.shared.reschedule(
                    menus: allMenus,
                    favoriteItems: favoritesStore.favoriteItems,
                    favoriteKeywords: favoritesStore.favoriteKeywords
                )
            }
        }
    }

    @ViewBuilder
    func dayPage(for index: Int) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                if index == 0 {
                    TodayContent(
                        status: status,
                        todayMenu: todayMenu,
                        selectedMeal: $selectedMeal,
                        currentSlot: currentSlot,
                        isLoading: isLoading,
                        loadError: loadError,
                        isRegularWidth: isRegularWidth,
                        favoritesStore: favoritesStore,
                        onRetry: { Task { await loadMenu() } }
                    )
                } else {
                    FutureDayContent(
                        schedule: scheduleForDate(at: index),
                        selectedFutureMeal: $selectedFutureMeal,
                        menu: menuForDate(at: index),
                        isLoading: isLoading,
                        loadError: loadError,
                        isRegularWidth: isRegularWidth,
                        favoritesStore: favoritesStore,
                        onRetry: { Task { await loadMenu() } }
                    )
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
        .refreshable {
            selectedDateIndex = 0
            await ChucksService.shared.invalidateCache()
            await loadMenu()
        }
    }

    func menuForDate(at index: Int) -> [VenueMenu] {
        guard index < availableDates.count else { return [] }
        return allMenus[availableDates[index]] ?? []
    }

    func scheduleForDate(at index: Int) -> [MealSchedule] {
        guard index < availableDates.count else { return [] }
        let dateKey = availableDates[index]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        guard let date = formatter.date(from: dateKey) else { return [] }
        let weekday = CedarvilleTime.calendar.component(.weekday, from: date)
        return MealSchedule.schedule(for: weekday)
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
            NotificationScheduler.shared.reschedule(
                menus: allMenus,
                favoriteItems: favoritesStore.favoriteItems,
                favoriteKeywords: favoritesStore.favoriteKeywords
            )
        } catch {
            loadError = error
            print("Failed to load menu: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Page Content Views

private struct TodayContent: View {
    let status: ChucksStatus
    let todayMenu: [VenueMenu]
    @Binding var selectedMeal: MealSchedule?
    let currentSlot: String
    let isLoading: Bool
    let loadError: Error?
    let isRegularWidth: Bool
    @ObservedObject var favoritesStore: FavoritesStore
    let onRetry: () -> Void

    var body: some View {
        Group {
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
                ErrorCard(error: error, retry: onRetry)
            } else {
                CurrentMealView(menu: todayMenu, slot: currentSlot, isOpen: status.isOpen, isRegularWidth: isRegularWidth, favoritesStore: favoritesStore)
            }
        }
    }
}

private struct FutureDayContent: View {
    let schedule: [MealSchedule]
    @Binding var selectedFutureMeal: MealPhase
    let menu: [VenueMenu]
    let isLoading: Bool
    let loadError: Error?
    let isRegularWidth: Bool
    @ObservedObject var favoritesStore: FavoritesStore
    let onRetry: () -> Void

    var body: some View {
        Group {
            ScheduleCard(
                schedule: schedule,
                selectedMealPhase: $selectedFutureMeal
            )

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else if let error = loadError {
                ErrorCard(error: error, retry: onRetry)
            } else {
                CurrentMealView(menu: menu, slot: selectedFutureMeal.apiSlot, isOpen: true, isRegularWidth: isRegularWidth, favoritesStore: favoritesStore)
            }
        }
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
    @ObservedObject var favoritesStore: FavoritesStore
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
                                        Button {
                                            favoritesStore.toggleItem(item.name)
                                        } label: {
                                            Image(systemName: favoritesStore.isFavorite(item) ? "star.fill" : "star")
                                                .foregroundStyle(favoritesStore.isFavorite(item) ? .orange : .secondary)
                                                .font(.subheadline)
                                        }
                                        .buttonStyle(.plain)
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
    @ObservedObject var favoritesStore: FavoritesStore

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

    var favoriteMatches: [(item: MenuItem, venueName: String)] {
        let allVenues = mealSpecificVenues + alwaysAvailableVenues
        var matches: [(item: MenuItem, venueName: String)] = []
        for venue in allVenues {
            for item in venue.items where favoritesStore.isFavorite(item) {
                matches.append((item: item, venueName: venue.venue))
            }
        }
        return matches
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Your Favorites Section
            if !favoriteMatches.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Your Favorites", systemImage: "star.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(favoriteMatches, id: \.item.id) { match in
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(match.item.name)
                                        .font(.subheadline)
                                    Text(match.venueName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                AllergenRow(allergens: match.item.allergens)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                }
            }

            // Meal Specials Section
            if !mealSpecificVenues.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Label("\(mealLabel) Specials", systemImage: "clock.fill")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 4)

                    MasonryLayout(mealSpecificVenues, columns: isRegularWidth ? 2 : 1, spacing: 12) { venue in
                        VenueCard(venue: venue, favoritesStore: favoritesStore)
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
                        VenueCard(venue: venue, favoritesStore: favoritesStore)
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
    @ObservedObject var favoritesStore: FavoritesStore
    @State private var isExpanded = true

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(venue.items) { item in
                    let isFav = favoritesStore.isFavorite(item)
                    HStack(spacing: 8) {
                        Button {
                            favoritesStore.toggleItem(item.name)
                        } label: {
                            Image(systemName: isFav ? "star.fill" : "star")
                                .foregroundStyle(isFav ? .orange : .secondary)
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        Text(item.name)
                            .font(.subheadline)
                        Spacer()
                        AllergenRow(allergens: item.allergens)
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 4)
                    .background(isFav ? Color.orange.opacity(0.08) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(item.name)\(isFav ? ", favorited" : "")")
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

// MARK: - Favorites Manager Sheet

struct FavoritesManagerSheet: View {
    @ObservedObject var favoritesStore: FavoritesStore
    @Environment(\.dismiss) private var dismiss
    @State private var newKeyword = ""

    var sortedKeywords: [String] {
        favoritesStore.favoriteKeywords.sorted()
    }

    var sortedItems: [String] {
        favoritesStore.favoriteItems.sorted()
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("Add keyword (e.g. fish, pizza)", text: $newKeyword)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .onSubmit { addKeyword() }
                        Button {
                            addKeyword()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.orange)
                        }
                        .disabled(newKeyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                } header: {
                    Text("Keywords")
                } footer: {
                    Text("Items containing a keyword will be highlighted as favorites.")
                }

                if !sortedKeywords.isEmpty {
                    Section("Current Keywords") {
                        ForEach(sortedKeywords, id: \.self) { keyword in
                            HStack {
                                Image(systemName: "tag.fill")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                                Text(keyword)
                            }
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                favoritesStore.removeKeyword(sortedKeywords[index])
                            }
                        }
                    }
                }

                if !sortedItems.isEmpty {
                    Section("Favorited Items") {
                        ForEach(sortedItems, id: \.self) { item in
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                                Text(item)
                            }
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                favoritesStore.toggleItem(sortedItems[index])
                            }
                        }
                    }
                }
            }
            .navigationTitle("Favorites")
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

    private func addKeyword() {
        let trimmed = newKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        favoritesStore.addKeyword(trimmed)
        newKeyword = ""
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
