package com.wasupchucks.ui.screens.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.wasupchucks.data.model.ChucksStatus
import com.wasupchucks.data.model.MealPhase
import com.wasupchucks.data.model.MealSchedule
import com.wasupchucks.data.model.VenueMenu
import com.wasupchucks.data.repository.MenuRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import javax.inject.Inject

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val menuRepository: MenuRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(HomeUiState())
    val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow()

    private val cedarvilleZone = ZoneId.of("America/New_York")
    private val dateFormatter = DateTimeFormatter.ISO_LOCAL_DATE

    init {
        loadMenu()
        startStatusTimer()
    }

    private fun startStatusTimer() {
        viewModelScope.launch {
            while (true) {
                _uiState.update { it.copy(status = ChucksStatus.calculate()) }
                delay(1000L)
            }
        }
    }

    fun loadMenu() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true, error = null) }

            menuRepository.fetchMenu()
                .onSuccess { menuMap ->
                    val today = LocalDate.now(cedarvilleZone)
                    val todayMenu = menuMap[today.toString()] ?: emptyList()
                    val dates = parseSortedDates(menuMap)

                    _uiState.update {
                        it.copy(
                            allMenus = menuMap,
                            availableDates = dates,
                            todayMenu = todayMenu,
                            todaySchedule = MealSchedule.scheduleForToday(),
                            isLoading = false,
                            error = null
                        )
                    }
                }
                .onFailure { error ->
                    _uiState.update {
                        it.copy(
                            isLoading = false,
                            error = error
                        )
                    }
                }
        }
    }

    fun refresh() {
        viewModelScope.launch {
            _uiState.update { it.copy(isRefreshing = true) }

            menuRepository.invalidateCache()

            menuRepository.fetchMenu()
                .onSuccess { menuMap ->
                    val today = LocalDate.now(cedarvilleZone)
                    val todayMenu = menuMap[today.toString()] ?: emptyList()
                    val dates = parseSortedDates(menuMap)

                    _uiState.update {
                        it.copy(
                            allMenus = menuMap,
                            availableDates = dates,
                            todayMenu = todayMenu,
                            todaySchedule = MealSchedule.scheduleForToday(),
                            isRefreshing = false,
                            error = null
                        )
                    }
                }
                .onFailure { error ->
                    _uiState.update {
                        it.copy(
                            isRefreshing = false,
                            error = error
                        )
                    }
                }
        }
    }

    fun selectDate(index: Int) {
        _uiState.update {
            it.copy(
                selectedDateIndex = index,
                selectedFutureMealPhase = MealPhase.BREAKFAST
            )
        }
    }

    fun selectFutureMeal(phase: MealPhase) {
        _uiState.update { it.copy(selectedFutureMealPhase = phase) }
    }

    fun selectMeal(meal: MealSchedule?) {
        _uiState.update { it.copy(selectedMeal = meal) }
    }

    private fun parseSortedDates(menuMap: Map<String, List<VenueMenu>>): List<LocalDate> {
        return menuMap.keys
            .mapNotNull { key ->
                runCatching { LocalDate.parse(key, dateFormatter) }.getOrNull()
            }
            .sorted()
    }
}
