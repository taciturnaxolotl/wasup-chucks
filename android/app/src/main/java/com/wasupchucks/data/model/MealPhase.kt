package com.wasupchucks.data.model

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bedtime
import androidx.compose.material.icons.filled.DinnerDining
import androidx.compose.material.icons.filled.FreeBreakfast
import androidx.compose.material.icons.filled.LunchDining
import androidx.compose.ui.graphics.vector.ImageVector

enum class MealPhase(
    val displayName: String,
    val apiSlot: String
) {
    BREAKFAST("Breakfast", "breakfast"),
    LUNCH("Lunch", "lunch"),
    DINNER("Dinner", "dinner"),
    CLOSED("Closed", "");

    val icon: ImageVector
        get() = when (this) {
            BREAKFAST -> Icons.Filled.FreeBreakfast
            LUNCH -> Icons.Filled.LunchDining
            DINNER -> Icons.Filled.DinnerDining
            CLOSED -> Icons.Filled.Bedtime
        }
}
