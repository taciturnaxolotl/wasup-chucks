package com.wasupchucks.data.model

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass
import java.time.DayOfWeek

/**
 * Pioneer's public hours feed for Cedarville. One entry per dining location,
 * each with rows for "SUN", "MON-FRI", "SAT", and so on.
 */
@JsonClass(generateAdapter = true)
data class ServiceHoursLocation(
    val location: String,
    val meals: List<ServiceHoursMeal>
)

@JsonClass(generateAdapter = true)
data class ServiceHoursMeal(
    val hours: List<ServiceHoursEntry>
)

@JsonClass(generateAdapter = true)
data class ServiceHoursEntry(
    val day: String,
    @Json(name = "open") val openTime: String,
    @Json(name = "close") val closeTime: String,
    val isOpen: Boolean
)

object ServiceHoursParser {

    private val dayNames = mapOf(
        "SUN" to DayOfWeek.SUNDAY,
        "MON" to DayOfWeek.MONDAY,
        "TUE" to DayOfWeek.TUESDAY,
        "WED" to DayOfWeek.WEDNESDAY,
        "THU" to DayOfWeek.THURSDAY,
        "FRI" to DayOfWeek.FRIDAY,
        "SAT" to DayOfWeek.SATURDAY
    )

    /**
     * The Commons splits each meal across several listings. Hot and continental
     * breakfast are one breakfast window here; Saturday brunch counts as lunch.
     */
    private fun phaseFor(location: String): MealPhase? {
        val name = location.trim().lowercase()
        if (!name.startsWith("the commons")) return null
        return when {
            name.endsWith("breakfast") -> MealPhase.BREAKFAST
            name.endsWith("lunch") || name.endsWith("brunch") -> MealPhase.LUNCH
            name.endsWith("dinner") -> MealPhase.DINNER
            else -> null
        }
    }

    /** Accepts the feed's mixed formats: "8:00 AM", "8:15am", "11:00pm". */
    private fun minutesOf(raw: String): Int? {
        val text = raw.filterNot { it.isWhitespace() }.lowercase()
        val isPm = text.endsWith("pm")
        if (!isPm && !text.endsWith("am")) return null
        val clock = text.dropLast(2).split(":")
        if (clock.size != 2) return null
        var hour = clock[0].toIntOrNull() ?: return null
        val minute = clock[1].toIntOrNull() ?: return null
        if (hour !in 1..12 || minute !in 0..59) return null
        if (hour == 12) hour = 0
        if (isPm) hour += 12
        return hour * 60 + minute
    }

    /** "MON-FRI" spans several days; "SUN" is just one. */
    private fun daysOf(day: String): List<DayOfWeek> {
        val parts = day.uppercase().split("-")
        val start = dayNames[parts.firstOrNull()] ?: return emptyList()
        val end = parts.getOrNull(1)?.let { dayNames[it] } ?: return listOf(start)
        return generateSequence(start) { it.plus(1L) }
            .takeWhile { it != end }
            .toList() + end
    }

    fun parse(locations: List<ServiceHoursLocation>): Map<DayOfWeek, List<MealSchedule>> {
        // Widest window wins when a phase is listed more than once for a day.
        val windows = mutableMapOf<DayOfWeek, MutableMap<MealPhase, IntRange>>()

        for (location in locations) {
            val phase = phaseFor(location.location) ?: continue
            for (meal in location.meals) {
                for (entry in meal.hours) {
                    if (!entry.isOpen) continue
                    val start = minutesOf(entry.openTime) ?: continue
                    val end = minutesOf(entry.closeTime) ?: continue
                    if (start >= end) continue
                    for (day in daysOf(entry.day)) {
                        val byPhase = windows.getOrPut(day) { mutableMapOf() }
                        val existing = byPhase[phase]
                        byPhase[phase] = if (existing == null) {
                            start..end
                        } else {
                            minOf(start, existing.first)..maxOf(end, existing.last)
                        }
                    }
                }
            }
        }

        return windows.mapValues { (_, byPhase) ->
            byPhase.map { (phase, window) ->
                MealSchedule(
                    phase = phase,
                    startHour = window.first / 60,
                    startMinute = window.first % 60,
                    endHour = window.last / 60,
                    endMinute = window.last % 60
                )
            }.sortedBy { it.startMinutes }
        }
    }
}
