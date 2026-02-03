package com.wasupchucks.ui.screens.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.wasupchucks.data.model.ChucksStatus
import com.wasupchucks.data.model.MealSchedule
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
import javax.inject.Inject

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val menuRepository: MenuRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(HomeUiState())
    val uiState: StateFlow<HomeUiState> = _uiState.asStateFlow()

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

            val cedarvilleZone = ZoneId.of("America/New_York")
            val today = LocalDate.now(cedarvilleZone)

            menuRepository.getMenuForDate(today)
                .onSuccess { menu ->
                    _uiState.update {
                        it.copy(
                            todayMenu = menu,
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

            val cedarvilleZone = ZoneId.of("America/New_York")
            val today = LocalDate.now(cedarvilleZone)

            menuRepository.getMenuForDate(today)
                .onSuccess { menu ->
                    _uiState.update {
                        it.copy(
                            todayMenu = menu,
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

    fun selectMeal(meal: MealSchedule?) {
        _uiState.update { it.copy(selectedMeal = meal) }
    }
}
