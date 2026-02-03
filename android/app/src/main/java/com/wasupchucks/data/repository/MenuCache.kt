package com.wasupchucks.data.repository

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.squareup.moshi.Moshi
import com.squareup.moshi.Types
import com.wasupchucks.data.model.VenueMenu
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

private val Context.menuDataStore by preferencesDataStore(name = "menu_cache")

data class CachedMenu(
    val menu: Map<String, List<VenueMenu>>,
    val cacheTime: Long
)

@Singleton
class MenuCache @Inject constructor(
    @ApplicationContext private val context: Context,
    moshi: Moshi
) {
    private val menuKey = stringPreferencesKey("menu_json")
    private val cacheTimeKey = longPreferencesKey("cache_time")

    private val menuMapType = Types.newParameterizedType(
        Map::class.java,
        String::class.java,
        Types.newParameterizedType(List::class.java, VenueMenu::class.java)
    )
    private val menuAdapter = moshi.adapter<Map<String, List<VenueMenu>>>(menuMapType)

    suspend fun save(menu: Map<String, List<VenueMenu>>) {
        context.menuDataStore.edit { prefs ->
            prefs[menuKey] = menuAdapter.toJson(menu)
            prefs[cacheTimeKey] = System.currentTimeMillis()
        }
    }

    suspend fun load(): CachedMenu? {
        return context.menuDataStore.data.map { prefs ->
            val json = prefs[menuKey] ?: return@map null
            val cacheTime = prefs[cacheTimeKey] ?: return@map null
            val menu = try {
                menuAdapter.fromJson(json) ?: return@map null
            } catch (e: Exception) {
                return@map null
            }
            CachedMenu(menu, cacheTime)
        }.first()
    }

    suspend fun clear() {
        context.menuDataStore.edit { prefs ->
            prefs.remove(menuKey)
            prefs.remove(cacheTimeKey)
        }
    }
}
