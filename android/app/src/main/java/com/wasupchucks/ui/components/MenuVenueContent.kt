package com.wasupchucks.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.wasupchucks.R
import com.wasupchucks.data.model.MenuItem
import com.wasupchucks.data.model.VenueMenu

/**
 * The venue list for a single meal: the meal's own specials first, then the
 * always-available stations under a divider. Shared by the Today tab and the
 * upcoming-day sheet so both render a meal the same way.
 */
fun LazyListScope.menuVenueContent(
    mealVenues: List<VenueMenu>,
    alwaysAvailableVenues: List<VenueMenu>,
    mealLabel: String,
    isExpandedWidth: Boolean,
    keyPrefix: String = "",
    onFavoriteToggle: ((String) -> Unit)? = null,
    isFavorite: ((MenuItem) -> Boolean)? = null
) {
    // Meal specials
    if (mealVenues.isNotEmpty()) {
        item(key = "$keyPrefix-meal-header") {
            Row(
                modifier = Modifier
                    .widthIn(max = 900.dp)
                    .fillMaxWidth()
                    .padding(horizontal = 4.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Icon(
                    imageVector = Icons.Filled.Schedule,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary
                )
                Text(
                    text = stringResource(R.string.meal_specials, mealLabel),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold
                )
            }
        }

        if (isExpandedWidth) {
            items(
                mealVenues.chunked(2),
                key = { row -> "$keyPrefix-${row.joinToString { it.id }}" }
            ) { rowVenues ->
                VenueRow(
                    venues = rowVenues,
                    onFavoriteToggle = onFavoriteToggle,
                    isFavorite = isFavorite
                )
            }
        } else {
            items(mealVenues, key = { "$keyPrefix-${it.id}" }) { venue ->
                VenueCard(
                    venue = venue,
                    onFavoriteToggle = onFavoriteToggle,
                    isFavorite = isFavorite
                )
            }
        }
    }

    // Always available
    if (alwaysAvailableVenues.isNotEmpty()) {
        item(key = "$keyPrefix-always-header") {
            Row(
                modifier = Modifier
                    .widthIn(max = 900.dp)
                    .fillMaxWidth()
                    .padding(top = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                HorizontalDivider(modifier = Modifier.weight(1f))
                Text(
                    text = stringResource(R.string.always_available),
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                HorizontalDivider(modifier = Modifier.weight(1f))
            }
        }

        if (isExpandedWidth) {
            items(
                alwaysAvailableVenues.chunked(2),
                key = { row -> "$keyPrefix-${row.joinToString { it.id }}-always" }
            ) { rowVenues ->
                VenueRow(
                    venues = rowVenues,
                    onFavoriteToggle = onFavoriteToggle,
                    isFavorite = isFavorite
                )
            }
        } else {
            items(alwaysAvailableVenues, key = { "$keyPrefix-${it.id}-always" }) { venue ->
                VenueCard(
                    venue = venue,
                    onFavoriteToggle = onFavoriteToggle,
                    isFavorite = isFavorite
                )
            }
        }
    }
}

@Composable
private fun VenueRow(
    venues: List<VenueMenu>,
    onFavoriteToggle: ((String) -> Unit)?,
    isFavorite: ((MenuItem) -> Boolean)?
) {
    Row(
        modifier = Modifier
            .widthIn(max = 900.dp)
            .fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        venues.forEach { venue ->
            VenueCard(
                venue = venue,
                modifier = Modifier.weight(1f),
                onFavoriteToggle = onFavoriteToggle,
                isFavorite = isFavorite
            )
        }
        if (venues.size == 1) {
            Spacer(modifier = Modifier.weight(1f))
        }
    }
}
