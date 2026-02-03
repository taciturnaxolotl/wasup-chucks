package com.wasupchucks.data.repository

import com.wasupchucks.data.api.ChucksApiService
import com.wasupchucks.data.model.MealPhase
import com.wasupchucks.data.model.MenuItem
import com.wasupchucks.data.model.VenueMenu
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class MenuRepositoryImpl @Inject constructor(
    private val apiService: ChucksApiService,
    private val menuCache: MenuCache
) : MenuRepository {

    private val mutex = Mutex()
    private var cachedMenu: Map<String, List<VenueMenu>>? = null
    private var cacheTime: Long = 0
    private val cacheExpiration = 12 * 60 * 60 * 1000L // 12 hours in milliseconds

    private val dateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
        .withZone(ZoneId.of("America/New_York"))

    override suspend fun fetchMenu(): Result<Map<String, List<VenueMenu>>> {
        return mutex.withLock {
            val currentTime = System.currentTimeMillis()

            // Check in-memory cache first
            val memCached = cachedMenu
            if (memCached != null && currentTime - cacheTime < cacheExpiration) {
                return@withLock Result.success(memCached)
            }

            // Check persistent cache
            val diskCached = menuCache.load()
            if (diskCached != null && currentTime - diskCached.cacheTime < cacheExpiration) {
                cachedMenu = diskCached.menu
                cacheTime = diskCached.cacheTime
                return@withLock Result.success(diskCached.menu)
            }

            // Fetch from API
            try {
                val menu = apiService.fetchMenu()
                cachedMenu = menu
                cacheTime = currentTime
                menuCache.save(menu)
                Result.success(menu)
            } catch (e: retrofit2.HttpException) {
                // Return stale cache if available on network error
                diskCached?.menu?.let { return@withLock Result.success(it) }
                Result.failure(ChucksError.NetworkError)
            } catch (e: java.io.IOException) {
                diskCached?.menu?.let { return@withLock Result.success(it) }
                Result.failure(ChucksError.NetworkError)
            } catch (e: com.squareup.moshi.JsonDataException) {
                Result.failure(ChucksError.DecodingError(e))
            } catch (e: Exception) {
                Result.failure(ChucksError.DecodingError(e))
            }
        }
    }

    override suspend fun getMenuForDate(date: LocalDate): Result<List<VenueMenu>> {
        return fetchMenu().map { menu ->
            val dateKey = date.format(dateFormatter)
            menu[dateKey] ?: emptyList()
        }
    }

    override suspend fun getSpecials(date: LocalDate, phase: MealPhase): Result<List<MenuItem>> {
        return getMenuForDate(date).map { dayMenu ->
            val slot = phase.apiSlot
            dayMenu
                .filter { it.venue == "Home Cooking" && it.slot == slot }
                .flatMap { it.items }
        }
    }

    override suspend fun getSpecialsWithVenue(
        date: LocalDate,
        phase: MealPhase
    ): Result<Pair<List<MenuItem>, String>> {
        val venueName = "Home Cooking"
        return getSpecials(date, phase).map { items ->
            items to venueName
        }
    }

    override suspend fun invalidateCache() {
        mutex.withLock {
            cachedMenu = null
            cacheTime = 0
            menuCache.clear()
        }
    }
}
