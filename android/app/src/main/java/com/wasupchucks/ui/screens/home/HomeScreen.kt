package com.wasupchucks.ui.screens.home

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.LargeTopAppBar
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.material3.windowsizeclass.WindowWidthSizeClass
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.wasupchucks.R
import com.wasupchucks.ui.components.ErrorCard
import com.wasupchucks.ui.components.MealDetailSheet
import com.wasupchucks.ui.components.ScheduleCard
import com.wasupchucks.ui.components.StatusCard
import com.wasupchucks.ui.components.VenueCard

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    widthSizeClass: WindowWidthSizeClass,
    viewModel: HomeViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val scrollBehavior = TopAppBarDefaults.exitUntilCollapsedScrollBehavior()
    val context = LocalContext.current

    val isExpandedWidth = widthSizeClass == WindowWidthSizeClass.Expanded ||
            widthSizeClass == WindowWidthSizeClass.Medium

    Scaffold(
        modifier = Modifier.nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            LargeTopAppBar(
                title = { Text(stringResource(R.string.app_name)) },
                scrollBehavior = scrollBehavior,
                colors = TopAppBarDefaults.largeTopAppBarColors(
                    scrolledContainerColor = MaterialTheme.colorScheme.surface
                )
            )
        },
        contentWindowInsets = WindowInsets(0, 0, 0, 0)
    ) { paddingValues ->
        PullToRefreshBox(
            isRefreshing = uiState.isRefreshing,
            onRefresh = { viewModel.refresh() },
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                item {
                    Spacer(modifier = Modifier.height(8.dp))
                }

                // Status and Schedule cards
                item {
                    if (isExpandedWidth) {
                        Row(
                            modifier = Modifier
                                .widthIn(max = 900.dp)
                                .fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(16.dp)
                        ) {
                            StatusCard(
                                status = uiState.status,
                                modifier = Modifier.weight(1f)
                            )
                            ScheduleCard(
                                status = uiState.status,
                                schedule = uiState.todaySchedule,
                                onMealClick = { viewModel.selectMeal(it) },
                                modifier = Modifier.weight(1f)
                            )
                        }
                    } else {
                        Column(
                            modifier = Modifier.fillMaxWidth(),
                            verticalArrangement = Arrangement.spacedBy(16.dp)
                        ) {
                            StatusCard(status = uiState.status)
                            ScheduleCard(
                                status = uiState.status,
                                schedule = uiState.todaySchedule,
                                onMealClick = { viewModel.selectMeal(it) }
                            )
                        }
                    }
                }

                // Loading state
                if (uiState.isLoading) {
                    item {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(200.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            CircularProgressIndicator()
                        }
                    }
                }

                // Error state
                uiState.error?.let { error ->
                    item {
                        ErrorCard(
                            error = error,
                            onRetry = { viewModel.loadMenu() },
                            modifier = Modifier.widthIn(max = 900.dp)
                        )
                    }
                }

                // Menu content
                if (!uiState.isLoading && uiState.error == null) {
                    // Meal Specials Section
                    if (uiState.mealSpecificVenues.isNotEmpty()) {
                        item {
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
                                    text = stringResource(R.string.meal_specials, getMealLabel(uiState.currentSlot)),
                                    style = MaterialTheme.typography.titleMedium,
                                    fontWeight = FontWeight.SemiBold
                                )
                            }
                        }

                        if (isExpandedWidth) {
                            // Two-column layout for expanded width
                            val chunkedVenues = uiState.mealSpecificVenues.chunked(2)
                            items(chunkedVenues, key = { it.map { v -> v.id }.joinToString() }) { rowVenues ->
                                Row(
                                    modifier = Modifier
                                        .widthIn(max = 900.dp)
                                        .fillMaxWidth(),
                                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                                ) {
                                    rowVenues.forEach { venue ->
                                        VenueCard(
                                            venue = venue,
                                            modifier = Modifier.weight(1f)
                                        )
                                    }
                                    if (rowVenues.size == 1) {
                                        Spacer(modifier = Modifier.weight(1f))
                                    }
                                }
                            }
                        } else {
                            items(uiState.mealSpecificVenues, key = { it.id }) { venue ->
                                VenueCard(venue = venue)
                            }
                        }
                    }

                    // Always Available Section
                    if (uiState.alwaysAvailableVenues.isNotEmpty()) {
                        item {
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
                            val chunkedVenues = uiState.alwaysAvailableVenues.chunked(2)
                            items(chunkedVenues, key = { it.map { v -> v.id }.joinToString() + "-always" }) { rowVenues ->
                                Row(
                                    modifier = Modifier
                                        .widthIn(max = 900.dp)
                                        .fillMaxWidth(),
                                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                                ) {
                                    rowVenues.forEach { venue ->
                                        VenueCard(
                                            venue = venue,
                                            modifier = Modifier.weight(1f)
                                        )
                                    }
                                    if (rowVenues.size == 1) {
                                        Spacer(modifier = Modifier.weight(1f))
                                    }
                                }
                            }
                        } else {
                            items(uiState.alwaysAvailableVenues, key = { "${it.id}-always" }) { venue ->
                                VenueCard(venue = venue)
                            }
                        }
                    }
                }

                // Footer
                item {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(
                            text = stringResource(R.string.made_with_love),
                            style = MaterialTheme.typography.labelSmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        TextButton(
                            onClick = {
                                val intent = Intent(Intent.ACTION_VIEW, Uri.parse(context.getString(R.string.privacy_policy_url)))
                                context.startActivity(intent)
                            }
                        ) {
                            Text(
                                text = stringResource(R.string.privacy_policy),
                                style = MaterialTheme.typography.labelSmall
                            )
                        }
                    }
                }

                item {
                    Spacer(modifier = Modifier.height(16.dp))
                }
            }
        }
    }

    // Meal Detail Sheet
    uiState.selectedMeal?.let { meal ->
        MealDetailSheet(
            meal = meal,
            menu = uiState.todayMenu,
            onDismiss = { viewModel.selectMeal(null) }
        )
    }
}

@Composable
private fun getMealLabel(slot: String): String {
    return when (slot) {
        "breakfast" -> stringResource(R.string.breakfast)
        "lunch" -> stringResource(R.string.lunch)
        "dinner" -> stringResource(R.string.dinner)
        else -> "This Meal"
    }
}
