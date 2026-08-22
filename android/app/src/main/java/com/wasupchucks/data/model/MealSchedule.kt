package com.wasupchucks.data.model

import com.squareup.moshi.JsonClass
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.ZoneId

@JsonClass(generateAdapter = true)
data class MealSchedule(
    val phase: MealPhase,
    val startHour: Int,
    val startMinute: Int,
    val endHour: Int,
    val endMinute: Int
) {
    val startMinutes: Int
        get() = startHour * 60 + startMinute

    val endMinutes: Int
        get() = endHour * 60 + endMinute

    companion object {
        // Mon-Fri: Hot Breakfast 7-8:15, Continental 8:15-9:30, Lunch 10:30-2:30, Dinner 4:30-7:30
        // Treating Hot + Continental as one "Breakfast" period for simplicity
        val weekdaySchedule = listOf(
            MealSchedule(MealPhase.BREAKFAST, 7, 0, 9, 30),
            MealSchedule(MealPhase.LUNCH, 10, 30, 14, 30),
            MealSchedule(MealPhase.DINNER, 16, 30, 19, 30)
        )

        // Saturday: Continental 8-9, Lunch 11-1, Dinner 4:30-6:30
        val saturdaySchedule = listOf(
            MealSchedule(MealPhase.BREAKFAST, 8, 0, 9, 0),
            MealSchedule(MealPhase.LUNCH, 11, 0, 13, 0),
            MealSchedule(MealPhase.DINNER, 16, 30, 18, 30)
        )

        // Sunday: Hot Breakfast 8-9, Lunch 11:30-2, Dinner 5-7:30
        val sundaySchedule = listOf(
            MealSchedule(MealPhase.BREAKFAST, 8, 0, 9, 0),
            MealSchedule(MealPhase.LUNCH, 11, 30, 14, 0),
            MealSchedule(MealPhase.DINNER, 17, 0, 19, 30)
        )

        /** Baked-in hours, used until the live service-hours feed has been fetched. */
        fun fallbackScheduleFor(dayOfWeek: DayOfWeek): List<MealSchedule> {
            return when (dayOfWeek) {
                DayOfWeek.SUNDAY -> sundaySchedule
                DayOfWeek.SATURDAY -> saturdaySchedule
                else -> weekdaySchedule
            }
        }

        fun scheduleFor(dayOfWeek: DayOfWeek): List<MealSchedule> {
            return ScheduleStore.scheduleFor(dayOfWeek) ?: fallbackScheduleFor(dayOfWeek)
        }

        fun scheduleFor(date: LocalDate): List<MealSchedule> {
            return scheduleFor(date.dayOfWeek)
        }

        fun scheduleForToday(): List<MealSchedule> {
            val cedarvilleZone = ZoneId.of("America/New_York")
            val today = LocalDate.now(cedarvilleZone)
            return scheduleFor(today.dayOfWeek)
        }
    }
}

/**
 * Holds the live dining hours in memory. Reads are synchronous because widgets,
 * notifications and the countdown all ask for the schedule far more often than it
 * changes; [com.wasupchucks.data.repository.ScheduleRepository] keeps it filled.
 */
object ScheduleStore {
    @Volatile
    private var overrides: Map<DayOfWeek, List<MealSchedule>> = emptyMap()

    /** Live hours for the given day, or null to fall back to the baked-in schedule. */
    fun scheduleFor(dayOfWeek: DayOfWeek): List<MealSchedule>? =
        overrides[dayOfWeek]?.takeIf { it.isNotEmpty() }

    fun apply(schedules: Map<DayOfWeek, List<MealSchedule>>) {
        overrides = schedules
    }
}
