package com.wasupchucks.ui.screens.home

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.animation.AnimatedContent
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
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowLeft
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.material3.windowsizeclass.WindowWidthSizeClass
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.wasupchucks.R
import com.wasupchucks.data.model.MealPhase
import com.wasupchucks.data.model.MealSchedule
import com.wasupchucks.data.model.VenueMenu
import com.wasupchucks.ui.components.ErrorCard
import com.wasupchucks.ui.components.FavoritesManagerSheet
import com.wasupchucks.ui.components.MealDetailSheet
import com.wasupchucks.ui.components.ScheduleCard
import com.wasupchucks.ui.components.StatusCard
import com.wasupchucks.ui.components.VenueCard
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.format.DateTimeFormatter

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    widthSizeClass: WindowWidthSizeClass,
    viewModel: HomeViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    val isExpandedWidth = widthSizeClass == WindowWidthSizeClass.Expanded ||
            widthSizeClass == WindowWidthSizeClass.Medium

    val pageCount = uiState.availableDates.size.coerceAtLeast(1)
    val pagerState = rememberPagerState(pageCount = { pageCount })

    // Sync pager -> viewModel
    LaunchedEffect(pagerState) {
        snapshotFlow { pagerState.currentPage }.collect { page ->
            if (page != uiState.selectedDateIndex) {
                viewModel.selectDate(page)
            }
        }
    }

    // Sync viewModel -> pager
    LaunchedEffect(uiState.selectedDateIndex) {
        if (pagerState.currentPage != uiState.selectedDateIndex) {
            pagerState.animateScrollToPage(uiState.selectedDateIndex)
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.app_name)) },
                actions = {
                    IconButton(onClick = { viewModel.showFavoritesManager(true) }) {
                        Icon(
                            imageVector = Icons.Filled.Star,
                            contentDescription = "Manage favorites",
                            tint = Color(0xFFFF9800)
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surfaceContainer
                )
            )
        },
        containerColor = MaterialTheme.colorScheme.surfaceContainer,
        contentWindowInsets = WindowInsets(0, 0, 0, 0)
    ) { paddingValues ->
        PullToRefreshBox(
            isRefreshing = uiState.isRefreshing,
            onRefresh = { viewModel.refresh() },
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            Column(modifier = Modifier.fillMaxSize()) {
                // Day navigation header
                if (uiState.availableDates.size > 1) {
                    DateNavigationHeader(
                        selectedDateIndex = uiState.selectedDateIndex,
                        availableDates = uiState.availableDates,
                        onPrevious = {
                            scope.launch {
                                pagerState.animateScrollToPage(uiState.selectedDateIndex - 1)
                            }
                        },
                        onNext = {
                            scope.launch {
                                pagerState.animateScrollToPage(uiState.selectedDateIndex + 1)
                            }
                        }
                    )
                }

                HorizontalPager(
                    state = pagerState,
                    modifier = Modifier.fillMaxSize(),
                    beyondViewportPageCount = 1
                ) { page ->
                    if (page == 0) {
                        TodayPage(
                            uiState = uiState,
                            isExpandedWidth = isExpandedWidth,
                            onMealClick = { viewModel.selectMeal(it) },
                            onRetry = { viewModel.loadMenu() },
                            context = context
                        )
                    } else {
                        FutureDayPage(
                            uiState = uiState,
                            page = page,
                            isExpandedWidth = isExpandedWidth,
                            onMealSelect = { viewModel.selectFutureMeal(it) },
                            onRetry = { viewModel.loadMenu() },
                            context = context
                        )
                    }
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

    // Favorites Manager Sheet
    if (uiState.showFavoritesManager) {
        FavoritesManagerSheet(
            favoriteItems = uiState.favoriteItems,
            favoriteKeywords = uiState.favoriteKeywords,
            onAddKeyword = { viewModel.addFavoriteKeyword(it) },
            onRemoveKeyword = { viewModel.removeFavoriteKeyword(it) },
            onToggleItem = { viewModel.toggleFavoriteItem(it) },
            onDismiss = { viewModel.showFavoritesManager(false) }
        )
    }
}

@Composable
private fun DateNavigationHeader(
    selectedDateIndex: Int,
    availableDates: List<LocalDate>,
    onPrevious: () -> Unit,
    onNext: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 4.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        IconButton(
            onClick = onPrevious,
            enabled = selectedDateIndex > 0
        ) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.KeyboardArrowLeft,
                contentDescription = stringResource(R.string.previous_day),
                tint = if (selectedDateIndex > 0)
                    MaterialTheme.colorScheme.onSurface
                else
                    MaterialTheme.colorScheme.onSurface.copy(alpha = 0.3f)
            )
        }

        AnimatedContent(
            targetState = selectedDateIndex,
            label = "dateLabel"
        ) { index ->
            Text(
                text = formatDateLabel(index, availableDates),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                textAlign = TextAlign.Center
            )
        }

        IconButton(
            onClick = onNext,
            enabled = selectedDateIndex < availableDates.size - 1
        ) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                contentDescription = stringResource(R.string.next_day),
                tint = if (selectedDateIndex < availableDates.size - 1)
                    MaterialTheme.colorScheme.onSurface
                else
                    MaterialTheme.colorScheme.onSurface.copy(alpha = 0.3f)
            )
        }
    }
}

@Composable
private fun TodayPage(
    uiState: HomeUiState,
    isExpandedWidth: Boolean,
    onMealClick: (MealSchedule) -> Unit,
    onRetry: () -> Unit,
    context: Context,
    viewModel: HomeViewModel = hiltViewModel()
) {
    val mealLabel = getMealLabel(uiState.currentSlot)

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
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
                        schedule = uiState.todaySchedule,
                        onMealClick = { onMealClick(it) },
                        modifier = Modifier.weight(1f),
                        status = uiState.status
                    )
                }
            } else {
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    StatusCard(status = uiState.status)
                    ScheduleCard(
                        schedule = uiState.todaySchedule,
                        onMealClick = { onMealClick(it) },
                        status = uiState.status
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
                    onRetry = onRetry,
                    modifier = Modifier.widthIn(max = 900.dp)
                )
            }
        }

        // Menu content
        if (!uiState.isLoading && uiState.error == null) {
            MenuVenueContent(
                mealVenues = uiState.mealSpecificVenues,
                alwaysAvailableVenues = uiState.alwaysAvailableVenues,
                mealLabel = mealLabel,
                isExpandedWidth = isExpandedWidth,
                onFavoriteToggle = { viewModel.toggleFavoriteItem(it) },
                isFavorite = { viewModel.isFavorite(it) }
            )
        }

        // Footer
        item { FooterContent(context = context) }
        item { Spacer(modifier = Modifier.height(16.dp)) }
    }
}

@Composable
private fun FutureDayPage(
    uiState: HomeUiState,
    page: Int,
    isExpandedWidth: Boolean,
    onMealSelect: (MealPhase) -> Unit,
    onRetry: () -> Unit,
    context: Context,
    viewModel: HomeViewModel = hiltViewModel()
) {
    val date = uiState.availableDates.getOrNull(page)
    val schedule = if (date != null) {
        MealSchedule.scheduleFor(date)
    } else {
        emptyList()
    }

    // For future pages, get venue data based on the selected date
    val dateMenu = if (date != null) {
        uiState.allMenus[date.toString()] ?: emptyList()
    } else {
        emptyList()
    }

    val mealVenues = dateMenu
        .filter { it.slot == uiState.selectedFutureMealPhase.apiSlot }
        .sortedBy { it.venue }

    val alwaysAvailable = dateMenu
        .filter { it.slot == "anytime" }
        .sortedBy { it.venue }

    val scheduleTitle = if (date != null) {
        stringResource(R.string.schedule_for, formatDateLabel(page, uiState.availableDates))
    } else {
        stringResource(R.string.todays_schedule)
    }

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Schedule card in tab mode
        item {
            ScheduleCard(
                schedule = schedule,
                onMealClick = {},
                title = scheduleTitle,
                selectedPhase = uiState.selectedFutureMealPhase,
                onMealSelect = onMealSelect
            )
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
                    onRetry = onRetry,
                    modifier = Modifier.widthIn(max = 900.dp)
                )
            }
        }

        // Menu content for future day
        if (!uiState.isLoading && uiState.error == null) {
            MenuVenueContent(
                mealVenues = mealVenues,
                alwaysAvailableVenues = alwaysAvailable,
                mealLabel = uiState.selectedFutureMealPhase.displayName,
                isExpandedWidth = isExpandedWidth,
                onFavoriteToggle = { viewModel.toggleFavoriteItem(it) },
                isFavorite = { viewModel.isFavorite(it) }
            )
        }

        // Footer
        item { FooterContent(context = context) }
        item { Spacer(modifier = Modifier.height(16.dp)) }
    }
}

private fun LazyListScope.MenuVenueContent(
    mealVenues: List<VenueMenu>,
    alwaysAvailableVenues: List<VenueMenu>,
    mealLabel: String,
    isExpandedWidth: Boolean,
    onFavoriteToggle: ((String) -> Unit)? = null,
    isFavorite: ((com.wasupchucks.data.model.MenuItem) -> Boolean)? = null
) {
    // Meal Specials Section
    if (mealVenues.isNotEmpty()) {
        item(key = "meal-header") {
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
            val chunkedVenues = mealVenues.chunked(2)
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
            items(mealVenues, key = { it.id }) { venue ->
                VenueCard(
                    venue = venue,
                    onFavoriteToggle = onFavoriteToggle,
                    isFavorite = isFavorite
                )
            }
        }
    }

    // Always Available Section
    if (alwaysAvailableVenues.isNotEmpty()) {
        item(key = "always-header") {
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
            val chunkedVenues = alwaysAvailableVenues.chunked(2)
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
                            modifier = Modifier.weight(1f),
                            onFavoriteToggle = onFavoriteToggle,
                            isFavorite = isFavorite
                        )
                    }
                    if (rowVenues.size == 1) {
                        Spacer(modifier = Modifier.weight(1f))
                    }
                }
            }
        } else {
            items(alwaysAvailableVenues, key = { "${it.id}-always" }) { venue ->
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
private fun FooterContent(context: Context) {
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

@Composable
private fun formatDateLabel(index: Int, dates: List<LocalDate>): String {
    if (index == 0) return stringResource(R.string.today)
    if (index == 1) return stringResource(R.string.tomorrow)
    val date = dates.getOrNull(index) ?: return ""
    return date.format(DateTimeFormatter.ofPattern("EEEE, MMM d"))
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
