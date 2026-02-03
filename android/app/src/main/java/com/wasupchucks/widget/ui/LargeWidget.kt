package com.wasupchucks.widget.ui

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.ColorFilter
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.appwidget.appWidgetBackground
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import com.wasupchucks.R
import com.wasupchucks.data.model.ChucksStatus
import com.wasupchucks.data.model.MealPhase
import com.wasupchucks.data.model.MenuItem
import com.wasupchucks.data.model.toCompactCountdown

@Composable
fun LargeWidgetContent(
    status: ChucksStatus,
    specials: List<MenuItem>,
    venueName: String
) {
    val statusColor = if (status.isOpen) {
        GlanceTheme.colors.primary
    } else {
        GlanceTheme.colors.onSurfaceVariant
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

    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .appWidgetBackground()
            .background(GlanceTheme.colors.widgetBackground)
            .cornerRadius(24.dp)
            .padding(16.dp)
    ) {
        // Header row
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Status info
            Row(
                modifier = GlanceModifier.defaultWeight(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Image(
                    provider = ImageProvider(iconRes),
                    contentDescription = null,
                    modifier = GlanceModifier.size(32.dp),
                    colorFilter = ColorFilter.tint(GlanceTheme.colors.onSurface)
                )
                Spacer(modifier = GlanceModifier.width(10.dp))
                Column {
                    Text(
                        text = if (status.isOpen) "Open" else "Closed",
                        style = TextStyle(
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Bold,
                            color = statusColor
                        )
                    )
                    val mealName = if (status.isOpen) {
                        status.currentPhase.displayName
                    } else {
                        status.nextPhase?.displayName ?: ""
                    }
                    Text(
                        text = mealName,
                        style = TextStyle(
                            fontSize = 20.sp,
                            fontWeight = FontWeight.Bold,
                            color = GlanceTheme.colors.onSurface
                        )
                    )
                }
            }

            // Countdown
            status.timeRemaining?.let { remaining ->
                Column(
                    horizontalAlignment = Alignment.End
                ) {
                    Text(
                        text = remaining.toCompactCountdown(),
                        style = TextStyle(
                            fontSize = 48.sp,
                            fontWeight = FontWeight.Bold,
                            color = GlanceTheme.colors.onSurface,
                            textAlign = TextAlign.End
                        )
                    )
                    val labelText = when {
                        status.isOpen -> "until ${status.currentPhase.displayName} ends"
                        else -> "until open"
                    }
                    Text(
                        text = labelText,
                        style = TextStyle(
                            fontSize = 13.sp,
                            color = GlanceTheme.colors.onSurfaceVariant,
                            textAlign = TextAlign.End
                        )
                    )
                }
            }
        }

        Spacer(modifier = GlanceModifier.height(16.dp))

        // Specials section
        Text(
            text = venueName,
            style = TextStyle(
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
                color = GlanceTheme.colors.onSurfaceVariant
            )
        )

        Spacer(modifier = GlanceModifier.height(10.dp))

        if (specials.isEmpty()) {
            Spacer(modifier = GlanceModifier.defaultWeight())
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "No specials available",
                    style = TextStyle(
                        fontSize = 16.sp,
                        color = GlanceTheme.colors.onSurfaceVariant
                    )
                )
            }
            Spacer(modifier = GlanceModifier.defaultWeight())
        } else {
            Column(
                modifier = GlanceModifier.fillMaxWidth()
            ) {
                specials.take(6).forEach { item ->
                    Text(
                        text = "\u2022 ${item.name}",
                        style = TextStyle(
                            fontSize = 16.sp,
                            color = GlanceTheme.colors.onSurface
                        ),
                        maxLines = 1
                    )
                    Spacer(modifier = GlanceModifier.height(6.dp))
                }
            }
        }
    }
}
