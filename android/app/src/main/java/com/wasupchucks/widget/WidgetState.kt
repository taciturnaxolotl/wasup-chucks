package com.wasupchucks.widget

import android.content.Context
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.squareup.moshi.Moshi
import com.squareup.moshi.Types
import com.wasupchucks.data.model.MenuItem
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map

private val Context.widgetDataStore by preferencesDataStore(name = "widget_data")

data class WidgetData(
    val specials: List<MenuItem> = emptyList(),
    val venueName: String = "Home Cooking",
    val lastUpdate: Long = 0
)

object WidgetState {
    private val SPECIALS_KEY = stringPreferencesKey("specials_json")
    private val VENUE_NAME_KEY = stringPreferencesKey("venue_name")
    private val LAST_UPDATE_KEY = longPreferencesKey("last_update")

    private val moshi = Moshi.Builder().build()
    private val menuItemListType = Types.newParameterizedType(List::class.java, MenuItem::class.java)
    private val menuItemListAdapter = moshi.adapter<List<MenuItem>>(menuItemListType)

    suspend fun save(context: Context, data: WidgetData) {
        context.widgetDataStore.edit { prefs ->
            prefs[SPECIALS_KEY] = menuItemListAdapter.toJson(data.specials)
            prefs[VENUE_NAME_KEY] = data.venueName
            prefs[LAST_UPDATE_KEY] = data.lastUpdate
        }
    }

    suspend fun load(context: Context): WidgetData {
        return context.widgetDataStore.data.map { prefs ->
            val specialsJson = prefs[SPECIALS_KEY]
            val specials = if (specialsJson != null) {
                try {
                    menuItemListAdapter.fromJson(specialsJson) ?: emptyList()
                } catch (e: Exception) {
                    emptyList()
                }
            } else {
                emptyList()
            }

            WidgetData(
                specials = specials,
                venueName = prefs[VENUE_NAME_KEY] ?: "Home Cooking",
                lastUpdate = prefs[LAST_UPDATE_KEY] ?: 0
            )
        }.first()
    }
}
