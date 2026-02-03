package com.wasupchucks.ui.screens.home

import com.wasupchucks.data.model.ChucksStatus
import com.wasupchucks.data.model.MealSchedule
import com.wasupchucks.data.model.VenueMenu

data class HomeUiState(
    val status: ChucksStatus = ChucksStatus.calculate(),
    val todayMenu: List<VenueMenu> = emptyList(),
    val todaySchedule: List<MealSchedule> = MealSchedule.scheduleForToday(),
    val isLoading: Boolean = true,
    val error: Throwable? = null,
    val selectedMeal: MealSchedule? = null,
    val isRefreshing: Boolean = false
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
}
