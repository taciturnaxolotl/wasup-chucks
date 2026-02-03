package com.wasupchucks.data.repository

import com.wasupchucks.data.model.MealPhase
import com.wasupchucks.data.model.MenuItem
import com.wasupchucks.data.model.VenueMenu
import java.time.LocalDate

interface MenuRepository {
    suspend fun fetchMenu(): Result<Map<String, List<VenueMenu>>>
    suspend fun getMenuForDate(date: LocalDate): Result<List<VenueMenu>>
    suspend fun getSpecials(date: LocalDate, phase: MealPhase): Result<List<MenuItem>>
    suspend fun getSpecialsWithVenue(date: LocalDate, phase: MealPhase): Result<Pair<List<MenuItem>, String>>
    fun invalidateCache()
}

sealed class ChucksError : Exception() {
    data object InvalidUrl : ChucksError() {
        private fun readResolve(): Any = InvalidUrl
    }
    data object NetworkError : ChucksError() {
        private fun readResolve(): Any = NetworkError
    }
    data class DecodingError(override val cause: Throwable) : ChucksError()
}
