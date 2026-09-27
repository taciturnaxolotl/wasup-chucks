package com.wasupchucks.ui.theme

import androidx.compose.material3.ColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

/**
 * Semantic status colors that adapt to the system theme.
 * Uses the color scheme's primary for positive states and tertiary for neutral/closed states.
 */
object StatusColors {
    val ColorScheme.openStatus: Color
        @Composable get() = primary

    val ColorScheme.closedStatus: Color
        @Composable get() = tertiary

    val ColorScheme.openContainer: Color
        @Composable get() = primaryContainer

    val ColorScheme.closedContainer: Color
        @Composable get() = tertiaryContainer

    val ColorScheme.onOpenContainer: Color
        @Composable get() = onPrimaryContainer

    val ColorScheme.onClosedContainer: Color
        @Composable get() = onTertiaryContainer
}

/**
 * Favorites accent. iOS hardcodes orange; here it rides the user's Material You
 * palette instead. Secondary is free: primary marks open/venue names and
 * tertiary marks closed, so this stays distinct from both.
 */
object FavoriteColors {
    val ColorScheme.favoriteAccent: Color
        @Composable get() = secondary

    val ColorScheme.favoriteHighlight: Color
        @Composable get() = secondaryContainer
}
