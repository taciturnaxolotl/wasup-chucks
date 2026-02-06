package com.wasupchucks.data.repository

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringSetPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.wasupchucks.data.model.MenuItem
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

private val Context.favoritesDataStore: DataStore<Preferences> by preferencesDataStore(name = "favorites")

@Singleton
class FavoritesRepository @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val favoriteItemsKey = stringSetPreferencesKey("favorite_items")
    private val favoriteKeywordsKey = stringSetPreferencesKey("favorite_keywords")

    val favoriteItems: Flow<Set<String>> = context.favoritesDataStore.data
        .map { preferences -> preferences[favoriteItemsKey] ?: emptySet() }

    val favoriteKeywords: Flow<Set<String>> = context.favoritesDataStore.data
        .map { preferences -> preferences[favoriteKeywordsKey] ?: emptySet() }

    suspend fun toggleItem(name: String) {
        context.favoritesDataStore.edit { preferences ->
            val current = preferences[favoriteItemsKey] ?: emptySet()
            preferences[favoriteItemsKey] = if (current.contains(name)) {
                current - name
            } else {
                current + name
            }
        }
    }

    suspend fun addKeyword(keyword: String) {
        val trimmed = keyword.trim()
        if (trimmed.isEmpty()) return

        context.favoritesDataStore.edit { preferences ->
            val current = preferences[favoriteKeywordsKey] ?: emptySet()
            preferences[favoriteKeywordsKey] = current + trimmed
        }
    }

    suspend fun removeKeyword(keyword: String) {
        context.favoritesDataStore.edit { preferences ->
            val current = preferences[favoriteKeywordsKey] ?: emptySet()
            preferences[favoriteKeywordsKey] = current - keyword
        }
    }

    fun isFavorite(item: MenuItem, favoriteItems: Set<String>, favoriteKeywords: Set<String>): Boolean {
        if (favoriteItems.contains(item.name)) return true
        val lowered = item.name.lowercase()
        return favoriteKeywords.any { lowered.contains(it.lowercase()) }
    }
}
