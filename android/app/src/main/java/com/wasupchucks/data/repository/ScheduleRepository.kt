package com.wasupchucks.data.repository

import android.content.Context
import com.squareup.moshi.Moshi
import com.squareup.moshi.Types
import com.wasupchucks.data.api.ServiceHoursApiService
import com.wasupchucks.data.model.MealSchedule
import com.wasupchucks.data.model.ScheduleStore
import com.wasupchucks.data.model.ServiceHoursParser
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.time.DayOfWeek
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Keeps [ScheduleStore] filled with the live dining hours.
 *
 * The cache is SharedPreferences rather than DataStore so that the stored hours can
 * be read synchronously at app start, before any widget or notification does meal math.
 */
@Singleton
class ScheduleRepository @Inject constructor(
    @ApplicationContext context: Context,
    private val apiService: ServiceHoursApiService,
    moshi: Moshi
) {
    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    private val mutex = Mutex()

    private val scheduleMapType = Types.newParameterizedType(
        Map::class.java,
        String::class.java,
        Types.newParameterizedType(List::class.java, MealSchedule::class.java)
    )
    private val scheduleAdapter = moshi.adapter<Map<String, List<MealSchedule>>>(scheduleMapType)

    /** Applies the last stored hours, if any. Safe to call on the main thread. */
    fun loadCached() {
        val json = prefs.getString(SCHEDULE_KEY, null) ?: return
        // An unrecognised day key must not take the app down: this runs during
        // Application.onCreate, so a throw here is an unrecoverable launch loop.
        val stored = try {
            scheduleAdapter.fromJson(json)?.mapNotNull { (key, value) ->
                runCatching { DayOfWeek.valueOf(key) }.getOrNull()?.let { it to value }
            }?.toMap()
        } catch (e: Exception) {
            null
        } ?: return
        if (stored.isNotEmpty()) ScheduleStore.apply(stored)
    }

    /**
     * Refreshes the hours from Pioneer's feed. Failures are silent: the previously
     * stored schedule, or the baked-in one, keeps the app working offline.
     */
    suspend fun refreshIfNeeded(force: Boolean = false) {
        mutex.withLock {
            // Re-read disk if the store is somehow empty, so a bad load does not
            // strand us on the baked-in hours until the cache expires.
            if (ScheduleStore.isEmpty) loadCached()

            val fetchedAt = prefs.getLong(FETCHED_AT_KEY, 0L)
            val age = System.currentTimeMillis() - fetchedAt
            if (!force && fetchedAt > 0L && age < CACHE_EXPIRATION) return

            val parsed = try {
                ServiceHoursParser.parse(apiService.fetchServiceHours())
            } catch (e: Exception) {
                return
            }
            if (parsed.isEmpty()) return

            ScheduleStore.apply(parsed)
            prefs.edit()
                .putString(SCHEDULE_KEY, scheduleAdapter.toJson(parsed.mapKeys { it.key.name }))
                .putLong(FETCHED_AT_KEY, System.currentTimeMillis())
                .apply()
        }
    }

    private companion object {
        const val PREFS_NAME = "service_hours"
        const val SCHEDULE_KEY = "schedule_json"
        const val FETCHED_AT_KEY = "fetched_at"
        const val CACHE_EXPIRATION = 12 * 60 * 60 * 1000L // 12 hours
    }
}
