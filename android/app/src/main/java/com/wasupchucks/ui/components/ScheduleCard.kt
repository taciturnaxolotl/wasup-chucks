package com.wasupchucks.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.wasupchucks.R
import com.wasupchucks.data.model.ChucksStatus
import com.wasupchucks.data.model.MealSchedule
import com.wasupchucks.ui.theme.StatusOpen

@Composable
fun ScheduleCard(
    status: ChucksStatus,
    schedule: List<MealSchedule>,
    onMealClick: (MealSchedule) -> Unit,
    modifier: Modifier = Modifier
) {
    ElevatedCard(
        modifier = modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Text(
                text = stringResource(R.string.todays_schedule),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold
            )

            Spacer(modifier = Modifier.height(12.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                schedule.forEach { meal ->
                    val isCurrent = status.isOpen && status.currentPhase == meal.phase

                    ScheduleButton(
                        meal = meal,
                        isCurrent = isCurrent,
                        onClick = { onMealClick(meal) },
                        modifier = Modifier.weight(1f)
                    )
                }
            }
        }
    }
}

@Composable
private fun ScheduleButton(
    meal: MealSchedule,
    isCurrent: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val startTime = formatTime(meal.startHour, meal.startMinute)
    val endTime = formatTime(meal.endHour, meal.endMinute)
    val accessibilityLabel = stringResource(
        R.string.meal_time_range,
        meal.phase.displayName,
        startTime,
        endTime
    ) + if (isCurrent) ", ${stringResource(R.string.current_meal)}" else ""

    val shape = RoundedCornerShape(12.dp)
    val backgroundColor = if (isCurrent) {
        StatusOpen.copy(alpha = 0.12f)
    } else {
        MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f)
    }
    val contentColor = if (isCurrent) {
        StatusOpen
    } else {
        MaterialTheme.colorScheme.onSurface
    }
    val border = if (isCurrent) {
        BorderStroke(2.dp, StatusOpen)
    } else {
        null
    }

    Surface(
        modifier = modifier
            .clip(shape)
            .clickable(onClick = onClick)
            .semantics { contentDescription = accessibilityLabel },
        shape = shape,
        color = backgroundColor,
        border = border
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(4.dp),
            modifier = Modifier.padding(vertical = 12.dp, horizontal = 8.dp)
        ) {
            Icon(
                imageVector = meal.phase.icon,
                contentDescription = null,
                tint = contentColor
            )
            Text(
                text = meal.phase.displayName,
                style = MaterialTheme.typography.labelMedium,
                fontWeight = FontWeight.Medium,
                color = contentColor
            )
            Text(
                text = "$startTime-$endTime",
                style = MaterialTheme.typography.labelSmall,
                color = if (isCurrent) contentColor.copy(alpha = 0.8f) else MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

private fun formatTime(hour: Int, minute: Int): String {
    val period = if (hour >= 12) "PM" else "AM"
    val displayHour = when {
        hour > 12 -> hour - 12
        hour == 0 -> 12
        else -> hour
    }
    return if (minute == 0) {
        "$displayHour$period"
    } else {
        "$displayHour:${minute.toString().padStart(2, '0')}$period"
    }
}
