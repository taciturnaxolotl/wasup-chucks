package com.wasupchucks.ui.screens.home

import com.wasupchucks.data.model.ChucksStatus
import com.wasupchucks.data.model.MealPhase
import com.wasupchucks.data.model.MealSchedule
import com.wasupchucks.data.model.VenueMenu
import java.time.LocalDate

data class HomeUiState(
    val status: ChucksStatus = ChucksStatus.calculate(),
    val todayMenu: List<VenueMenu> = emptyList(),
    val todaySchedule: List<MealSchedule> = MealSchedule.scheduleForToday(),
    val isLoading: Boolean = true,
    val error: Throwable? = null,
    val selectedMeal: MealSchedule? = null,
    val isRefreshing: Boolean = false,
    val allMenus: Map<String, List<VenueMenu>> = emptyMap(),
    val availableDates: List<LocalDate> = emptyList(),
    val selectedDateIndex: Int = 0,
    val selectedFutureMealPhase: MealPhase = MealPhase.BREAKFAST,
    val favoriteItems: Set<String> = emptySet(),
    val favoriteKeywords: Set<String> = emptySet(),
    val showFavoritesManager: Boolean = false
) {
    val currentSlot: String
        get() = if (status.isOpen) {
            status.currentPhase.apiSlot
        } else {
            status.nextPhase?.apiSlot ?: "lunch"
        }

    val mealSpecificVenues: List<VenueMenu>
        get() = todayMenu
            .filter { it.slot == currentSlot }
            .sortedBy { it.venue }

    val alwaysAvailableVenues: List<VenueMenu>
        get() = todayMenu
            .filter { it.slot == "anytime" }
            .sortedBy { it.venue }

    val isViewingToday: Boolean
        get() = selectedDateIndex == 0

    val selectedDateMenu: List<VenueMenu>
        get() {
            val date = availableDates.getOrNull(selectedDateIndex) ?: return emptyList()
            return allMenus[date.toString()] ?: emptyList()
        }

    val selectedDateSchedule: List<MealSchedule>
        get() {
            val date = availableDates.getOrNull(selectedDateIndex) ?: return emptyList()
            return MealSchedule.scheduleFor(date)
        }

    val futureMealVenues: List<VenueMenu>
        get() = selectedDateMenu
            .filter { it.slot == selectedFutureMealPhase.apiSlot }
            .sortedBy { it.venue }

    val futureAlwaysAvailableVenues: List<VenueMenu>
        get() = selectedDateMenu
            .filter { it.slot == "anytime" }
            .sortedBy { it.venue }
}
