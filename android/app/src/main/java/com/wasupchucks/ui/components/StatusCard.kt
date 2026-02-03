package com.wasupchucks.ui.components

import androidx.compose.animation.animateContentSize
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
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
@Composable
fun StatusCard(
    status: ChucksStatus,
    modifier: Modifier = Modifier
) {
    val colorScheme = MaterialTheme.colorScheme
    val statusColor = if (status.isOpen) colorScheme.primary else colorScheme.tertiary

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

    Card(
        modifier = modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = colorScheme.surfaceContainerHigh
        ),
        shape = MaterialTheme.shapes.large
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp)
                .animateContentSize(
                    animationSpec = spring(
                        dampingRatio = Spring.DampingRatioLowBouncy,
                        stiffness = Spring.StiffnessLow
                    )
                )
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .semantics { contentDescription = accessibilityLabel },
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                Icon(
                    imageVector = statusIcon,
                    contentDescription = null,
                    tint = statusColor
                )
                Column {
                    Text(
                        text = statusText,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = statusColor
                    )
                    Text(
                        text = mealText,
                        style = MaterialTheme.typography.bodyMedium,
                        color = colorScheme.onSurfaceVariant
                    )
                }
            }

            status.timeRemaining?.let { remaining ->
                Spacer(modifier = Modifier.height(16.dp))

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
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
                    modifier = Modifier.align(Alignment.CenterHorizontally)
                )
            }
        }
    }
}
