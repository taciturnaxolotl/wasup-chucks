package com.wasupchucks.widget.ui

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxHeight
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import com.wasupchucks.R
import com.wasupchucks.data.model.ChucksStatus
import com.wasupchucks.data.model.MealPhase
import com.wasupchucks.data.model.MenuItem
import com.wasupchucks.data.model.toCompactCountdown

@Composable
fun MediumWidgetContent(
    status: ChucksStatus,
    specials: List<MenuItem>,
    venueName: String
) {
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

    Row(
        modifier = GlanceModifier
            .fillMaxSize()
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Left side - Status
        Column(
            modifier = GlanceModifier
                .defaultWeight()
                .fillMaxHeight(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Image(
                    provider = ImageProvider(iconRes),
                    contentDescription = null,
                    modifier = GlanceModifier.size(16.dp)
                )
                Spacer(modifier = GlanceModifier.width(4.dp))
                Text(
                    text = if (status.isOpen) "Open" else "Closed",
                    style = TextStyle(
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = statusColor
                    )
                )
            }

            status.timeRemaining?.let { remaining ->
                Text(
                    text = remaining.toCompactCountdown(),
                    style = TextStyle(
                        fontSize = 40.sp,
                        fontWeight = FontWeight.Bold,
                        color = GlanceTheme.colors.onSurface
                    )
                )
            }

            val labelText = when {
                status.isOpen -> "until ${status.currentPhase.displayName} ends"
                status.nextPhase != null && status.nextPhase != MealPhase.CLOSED -> "until ${status.nextPhase.displayName}"
                else -> ""
            }

            if (labelText.isNotEmpty()) {
                Text(
                    text = labelText,
                    style = TextStyle(
                        fontSize = 10.sp,
                        color = GlanceTheme.colors.onSurfaceVariant
                    )
                )
            }
        }

        // Divider
        Spacer(
            modifier = GlanceModifier
                .width(1.dp)
                .fillMaxHeight()
                .padding(vertical = 8.dp)
        )

        Spacer(modifier = GlanceModifier.width(12.dp))

        // Right side - Specials
        Column(
            modifier = GlanceModifier
                .defaultWeight()
                .fillMaxHeight(),
            verticalAlignment = Alignment.Top
        ) {
            Text(
                text = venueName,
                style = TextStyle(
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    color = GlanceTheme.colors.onSurfaceVariant
                )
            )

            Spacer(modifier = GlanceModifier.height(4.dp))

            if (specials.isEmpty()) {
                Spacer(modifier = GlanceModifier.defaultWeight())
                Text(
                    text = "No specials available",
                    style = TextStyle(
                        fontSize = 11.sp,
                        color = GlanceTheme.colors.onSurfaceVariant
                    )
                )
                Spacer(modifier = GlanceModifier.defaultWeight())
            } else {
                specials.take(4).forEach { item ->
                    Text(
                        text = "\u2022 ${item.name}",
                        style = TextStyle(
                            fontSize = 11.sp,
                            color = GlanceTheme.colors.onSurface
                        ),
                        maxLines = 1
                    )
                }
            }
        }
    }
}
