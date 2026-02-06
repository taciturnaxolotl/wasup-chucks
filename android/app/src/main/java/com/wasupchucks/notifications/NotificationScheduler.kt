package com.wasupchucks.notifications

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.CoroutineWorker
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import androidx.work.workDataOf
import com.wasupchucks.R
import com.wasupchucks.data.model.MealPhase
import com.wasupchucks.data.model.MealSchedule
import com.wasupchucks.data.model.VenueMenu
import com.wasupchucks.data.model.findFavoriteMatches
import com.wasupchucks.data.repository.FavoritesRepository
import com.wasupchucks.data.repository.MenuRepository
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.first
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.temporal.ChronoUnit
import java.util.concurrent.TimeUnit
import javax.inject.Inject
import javax.inject.Singleton

private const val CHANNEL_ID = "favorites_notifications"
private const val NOTIFICATION_WORK_TAG = "favorites_notification_work"

@Singleton
class NotificationScheduler @Inject constructor(
    @ApplicationContext private val context: Context,
    private val favoritesRepository: FavoritesRepository,
    private val menuRepository: MenuRepository
) {
    private val cedarvilleZone = ZoneId.of("America/New_York")
    private val workManager = WorkManager.getInstance(context)

    init {
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Favorite Menu Items"
            val descriptionText = "Notifications when your favorite items are available"
            val importance = NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            val notificationManager: NotificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    suspend fun rescheduleNotifications(
        menus: Map<String, List<VenueMenu>>,
        favoriteItems: Set<String>,
        favoriteKeywords: Set<String>
    ) {
        // Cancel all existing notification work
        workManager.cancelAllWorkByTag(NOTIFICATION_WORK_TAG)

        if (favoriteItems.isEmpty() && favoriteKeywords.isEmpty()) {
            return
        }

        val matches = findFavoriteMatches(menus, favoriteItems, favoriteKeywords)
        val now = LocalDateTime.now(cedarvilleZone)
        val dateFormatter = DateTimeFormatter.ISO_LOCAL_DATE

        for (match in matches) {
            val date = try {
                LocalDate.parse(match.dateKey, dateFormatter)
            } catch (e: Exception) {
                continue
            }

            val schedule = MealSchedule.scheduleFor(date)
            val mealSchedule = schedule.firstOrNull { it.phase == match.meal } ?: continue

            // Calculate notification time (1 hour before meal start)
            val mealStartTime = LocalDateTime.of(
                date,
                java.time.LocalTime.of(mealSchedule.startHour, mealSchedule.startMinute)
            )
            val notificationTime = mealStartTime.minusHours(1)

            if (notificationTime.isAfter(now)) {
                val delay = ChronoUnit.MILLIS.between(now, notificationTime)
                
                val itemNames = match.matchedItems.take(3).joinToString(", ")
                val additionalCount = match.matchedItems.size - 3

                val workData = workDataOf(
                    "mealName" to match.meal.displayName,
                    "itemNames" to itemNames,
                    "additionalCount" to additionalCount,
                    "notificationId" to "${match.dateKey}-${match.meal.name}".hashCode()
                )

                val notificationWork = OneTimeWorkRequestBuilder<NotificationWorker>()
                    .setInitialDelay(delay, TimeUnit.MILLISECONDS)
                    .setInputData(workData)
                    .addTag(NOTIFICATION_WORK_TAG)
                    .build()

                workManager.enqueueUniqueWork(
                    "${match.dateKey}-${match.meal.name}",
                    ExistingWorkPolicy.REPLACE,
                    notificationWork
                )
            }
        }
    }
}

class NotificationWorker(
    appContext: Context,
    params: WorkerParameters
) : CoroutineWorker(appContext, params) {

    override suspend fun doWork(): Result {
        val mealName = inputData.getString("mealName") ?: return Result.failure()
        val itemNames = inputData.getString("itemNames") ?: return Result.failure()
        val additionalCount = inputData.getInt("additionalCount", 0)
        val notificationId = inputData.getInt("notificationId", 0)

        val bodyText = if (additionalCount > 0) {
            "$itemNames +$additionalCount more at Chuck's today."
        } else {
            "$itemNames at Chuck's today."
        }

        val builder = NotificationCompat.Builder(applicationContext, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle("$mealName has your favorites!")
            .setContentText(bodyText)
            .setStyle(NotificationCompat.BigTextStyle().bigText(bodyText))
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)

        if (ActivityCompat.checkSelfPermission(
                applicationContext,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED || Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU
        ) {
            NotificationManagerCompat.from(applicationContext)
                .notify(notificationId, builder.build())
        }

        return Result.success()
    }
}
