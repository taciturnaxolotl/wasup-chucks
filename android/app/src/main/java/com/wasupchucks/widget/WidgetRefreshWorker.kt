package com.wasupchucks.widget

import android.content.Context
import androidx.glance.appwidget.updateAll
import androidx.hilt.work.HiltWorker
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import com.wasupchucks.data.model.ChucksStatus
import com.wasupchucks.data.model.MealPhase
import com.wasupchucks.data.repository.MenuRepository
import com.wasupchucks.data.repository.ScheduleRepository
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject
import java.time.LocalDate
import java.time.ZoneId
import java.util.concurrent.TimeUnit

@HiltWorker
class WidgetRefreshWorker @AssistedInject constructor(
    @Assisted private val context: Context,
    @Assisted params: WorkerParameters,
    private val menuRepository: MenuRepository,
    private val scheduleRepository: ScheduleRepository
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        return try {
            scheduleRepository.refreshIfNeeded()
            val status = ChucksStatus.calculate()
            val phase = if (status.isOpen) status.currentPhase else (status.nextPhase ?: MealPhase.LUNCH)
            val cedarvilleZone = ZoneId.of("America/New_York")
            val today = LocalDate.now(cedarvilleZone)

            // When closed, the next meal is often tomorrow's, so follow the phase we
            // are actually advertising instead of assuming today.
            val menuDate = if (status.isOpen) {
                today
            } else {
                status.nextPhaseStart?.withZoneSameInstant(cedarvilleZone)?.toLocalDate() ?: today
            }

            if (phase != MealPhase.CLOSED) {
                menuRepository.getSpecialsWithVenue(menuDate, phase)
                    .onSuccess { (items, venueName) ->
                        WidgetState.save(
                            context,
                            WidgetData(
                                specials = items,
                                venueName = venueName,
                                lastUpdate = System.currentTimeMillis()
                            )
                        )
                    }
            }

            // Update all widget instances
            ChucksSmallWidget().updateAll(context)
            ChucksMediumWidget().updateAll(context)
            ChucksLargeWidget().updateAll(context)

            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
    }

    companion object {
        private const val WORK_NAME = "widget_refresh"

        fun enqueue(context: Context) {
            val request = PeriodicWorkRequestBuilder<WidgetRefreshWorker>(
                15, TimeUnit.MINUTES
            ).build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                request
            )
        }
    }
}
