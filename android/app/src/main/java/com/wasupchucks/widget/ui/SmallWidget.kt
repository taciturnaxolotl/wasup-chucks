package com.wasupchucks.widget.ui

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import com.wasupchucks.R
import com.wasupchucks.data.model.ChucksStatus
import com.wasupchucks.data.model.MealPhase
import com.wasupchucks.data.model.toCompactCountdown

@Composable
fun SmallWidgetContent(status: ChucksStatus) {
    val statusColor = if (status.isOpen) {
        GlanceTheme.colors.primary
    } else {
        GlanceTheme.colors.error
    }

    val iconRes = when {
        status.isOpen -> when (status.currentPhase) {
            MealPhase.BREAKFAST -> R.drawable.ic_breakfast
            MealPhase.LUNCH -> R.drawable.ic_lunch
            MealPhase.DINNER -> R.drawable.ic_dinner
            MealPhase.CLOSED -> R.drawable.ic_closed
        }
        status.nextPhase != null -> when (status.nextPhase) {
            MealPhase.BREAKFAST -> R.drawable.ic_breakfast
            MealPhase.LUNCH -> R.drawable.ic_lunch
            MealPhase.DINNER -> R.drawable.ic_dinner
            MealPhase.CLOSED -> R.drawable.ic_closed
        }
        else -> R.drawable.ic_closed
    }

    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .padding(12.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            modifier = GlanceModifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Status indicator
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalAlignment = Alignment.Start
            ) {
                Image(
                    provider = ImageProvider(iconRes),
                    contentDescription = null,
                    modifier = GlanceModifier.size(20.dp)
                )
                Spacer(modifier = GlanceModifier.size(4.dp))
                Text(
                    text = if (status.isOpen) "Open" else "Closed",
                    style = TextStyle(
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = statusColor
                    )
                )
            }

            Spacer(modifier = GlanceModifier.defaultWeight())

            // Countdown
            status.timeRemaining?.let { remaining ->
                Text(
                    text = remaining.toCompactCountdown(),
                    style = TextStyle(
                        fontSize = 48.sp,
                        fontWeight = FontWeight.Bold,
                        color = GlanceTheme.colors.onSurface
                    )
                )
            }

            // Label
            val labelText = when {
                status.isOpen -> "until ${status.currentPhase.displayName} ends"
                status.nextPhase != null && status.nextPhase != MealPhase.CLOSED -> "until ${status.nextPhase.displayName}"
                else -> "See you tomorrow!"
            }

            Text(
                text = labelText,
                style = TextStyle(
                    fontSize = 11.sp,
                    color = GlanceTheme.colors.onSurfaceVariant
                )
            )

            Spacer(modifier = GlanceModifier.defaultWeight())
        }
    }
}
