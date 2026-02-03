package com.wasupchucks.data.model

import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.temporal.ChronoUnit
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

data class ChucksStatus(
    val currentPhase: MealPhase,
    val timeRemaining: Duration?,
    val nextPhase: MealPhase?,
    val nextPhaseStart: ZonedDateTime?,
    val isOpen: Boolean,
    val currentMealEnd: ZonedDateTime?
) {
    companion object {
        private val cedarvilleZone = ZoneId.of("America/New_York")

        fun calculate(dateTime: ZonedDateTime = ZonedDateTime.now(cedarvilleZone)): ChucksStatus {
            val localDateTime = dateTime.withZoneSameInstant(cedarvilleZone).toLocalDateTime()
            val schedule = MealSchedule.scheduleFor(localDateTime.dayOfWeek)

            val currentMinutes = localDateTime.hour * 60 + localDateTime.minute

            // Check each meal period
            for ((index, meal) in schedule.withIndex()) {
                // Currently in a meal period
                if (currentMinutes >= meal.startMinutes && currentMinutes < meal.endMinutes) {
                    val endDateTime = localDateTime.toLocalDate()
                        .atTime(meal.endHour, meal.endMinute)
                        .atZone(cedarvilleZone)
                    val remaining = ChronoUnit.SECONDS.between(dateTime, endDateTime).seconds

                    val nextPhase: MealPhase?
                    val nextStart: ZonedDateTime?
                    if (index + 1 < schedule.size) {
                        val next = schedule[index + 1]
                        nextPhase = next.phase
                        nextStart = localDateTime.toLocalDate()
                            .atTime(next.startHour, next.startMinute)
                            .atZone(cedarvilleZone)
                    } else {
                        nextPhase = MealPhase.CLOSED
                        nextStart = null
                    }

                    return ChucksStatus(
                        currentPhase = meal.phase,
                        timeRemaining = remaining,
                        nextPhase = nextPhase,
                        nextPhaseStart = nextStart,
                        isOpen = true,
                        currentMealEnd = endDateTime
                    )
                }

                // Before a meal starts
                if (currentMinutes < meal.startMinutes) {
                    val startDateTime = localDateTime.toLocalDate()
                        .atTime(meal.startHour, meal.startMinute)
                        .atZone(cedarvilleZone)
                    val timeUntil = ChronoUnit.SECONDS.between(dateTime, startDateTime).seconds

                    return ChucksStatus(
                        currentPhase = MealPhase.CLOSED,
                        timeRemaining = timeUntil,
                        nextPhase = meal.phase,
                        nextPhaseStart = startDateTime,
                        isOpen = false,
                        currentMealEnd = null
                    )
                }
            }

            // After all meals - calculate time until tomorrow's first meal
            val tomorrow = localDateTime.toLocalDate().plusDays(1)
            val tomorrowSchedule = MealSchedule.scheduleFor(tomorrow.dayOfWeek)

            if (tomorrowSchedule.isNotEmpty()) {
                val firstMeal = tomorrowSchedule.first()
                var nextStart = tomorrow
                    .atTime(firstMeal.startHour, firstMeal.startMinute)
                    .atZone(cedarvilleZone)

                // Handle edge case if calculated time is in the past
                if (!nextStart.isAfter(dateTime)) {
                    nextStart = nextStart.plusDays(1)
                }

                val timeUntil = ChronoUnit.SECONDS.between(dateTime, nextStart).seconds

                return ChucksStatus(
                    currentPhase = MealPhase.CLOSED,
                    timeRemaining = timeUntil,
                    nextPhase = firstMeal.phase,
                    nextPhaseStart = nextStart,
                    isOpen = false,
                    currentMealEnd = null
                )
            }

            // Fallback - should never reach here
            return ChucksStatus(
                currentPhase = MealPhase.CLOSED,
                timeRemaining = null,
                nextPhase = null,
                nextPhaseStart = null,
                isOpen = false,
                currentMealEnd = null
            )
        }
    }
}

// Extension functions for Duration formatting
fun Duration.toCompactCountdown(): String {
    val totalSeconds = inWholeSeconds
    val hours = totalSeconds / 3600
    val minutes = (totalSeconds % 3600) / 60
    val seconds = totalSeconds % 60

    return when {
        hours > 0 -> "${hours}h"
        minutes > 0 -> "${minutes}m"
        else -> "${seconds}s"
    }
}

fun Duration.toExpandedCountdown(): String {
    val totalSeconds = inWholeSeconds
    val hours = totalSeconds / 3600
    val minutes = (totalSeconds % 3600) / 60
    val seconds = totalSeconds % 60

    return when {
        hours > 0 && minutes > 0 -> "${hours}h ${minutes}m"
        hours > 0 -> "${hours}h"
        minutes > 0 -> "${minutes}m"
        else -> "${seconds}s"
    }
}
