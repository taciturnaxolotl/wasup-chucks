package com.wasupchucks.ui.components

import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.wasupchucks.R
import com.wasupchucks.data.model.ChucksStatus
import com.wasupchucks.data.model.MealPhase
import com.wasupchucks.data.model.toExpandedCountdown
import com.wasupchucks.ui.theme.CountdownTypography
import com.wasupchucks.ui.theme.StatusClosed
import com.wasupchucks.ui.theme.StatusOpen

@Composable
fun StatusCard(
    status: ChucksStatus,
    modifier: Modifier = Modifier
) {
    val statusColor = if (status.isOpen) StatusOpen else StatusClosed
    val statusIcon = if (status.isOpen) {
        status.currentPhase.icon
    } else {
        status.nextPhase?.icon ?: MealPhase.CLOSED.icon
    }
    val statusText = if (status.isOpen) {
        stringResource(R.string.status_open)
    } else {
        stringResource(R.string.status_closed)
    }
    val mealText = if (status.isOpen) {
        status.currentPhase.displayName
    } else {
        status.nextPhase?.displayName ?: ""
    }

    val accessibilityLabel = if (status.isOpen) {
        stringResource(R.string.open_for_meal, status.currentPhase.displayName)
    } else {
        stringResource(R.string.closed_next_meal, status.nextPhase?.displayName ?: "")
    }

    ElevatedCard(
        modifier = modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
                .animateContentSize()
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .semantics { contentDescription = accessibilityLabel },
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Icon(
                    imageVector = statusIcon,
                    contentDescription = null,
                    tint = statusColor
                )
                Column {
                    Text(
                        text = statusText,
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.SemiBold,
                        color = statusColor
                    )
                    Text(
                        text = mealText,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            status.timeRemaining?.let { remaining ->
                Spacer(modifier = Modifier.height(8.dp))

                Text(
                    text = remaining.toExpandedCountdown(),
                    style = CountdownTypography.large,
                    color = MaterialTheme.colorScheme.onSurface,
                    modifier = Modifier.align(Alignment.CenterHorizontally)
                )

                val untilText = if (status.isOpen) {
                    stringResource(R.string.until_ends, status.currentPhase.displayName)
                } else {
                    stringResource(R.string.until_opens, status.nextPhase?.displayName ?: "open")
                }

                Text(
                    text = untilText,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.align(Alignment.CenterHorizontally)
                )
            }
        }
    }
}
