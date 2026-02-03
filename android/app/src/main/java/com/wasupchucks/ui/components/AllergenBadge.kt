package com.wasupchucks.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.wasupchucks.R
import com.wasupchucks.data.model.Allergen

@Composable
fun AllergenBadge(
    allergen: Allergen,
    modifier: Modifier = Modifier
) {
    // Dietary badges use primary colors, warning badges use tertiary
    val backgroundColor = if (allergen.isDietary) {
        MaterialTheme.colorScheme.primaryContainer
    } else {
        MaterialTheme.colorScheme.tertiaryContainer
    }
    val textColor = if (allergen.isDietary) {
        MaterialTheme.colorScheme.onPrimaryContainer
    } else {
        MaterialTheme.colorScheme.onTertiaryContainer
    }

    Surface(
        modifier = modifier,
        shape = MaterialTheme.shapes.extraSmall,
        color = backgroundColor
    ) {
        Text(
            text = allergen.symbol,
            fontSize = 10.sp,
            fontWeight = FontWeight.Bold,
            color = textColor,
            modifier = Modifier.padding(horizontal = 6.dp, vertical = 4.dp)
        )
    }
}

@Composable
fun AllergenRow(
    allergens: List<Allergen>,
    modifier: Modifier = Modifier
) {
    if (allergens.isEmpty()) return

    val accessibilityLabel = stringResource(
        R.string.contains_allergens,
        allergens.joinToString(", ") { it.displayName }
    )

    Row(
        modifier = modifier.semantics { contentDescription = accessibilityLabel },
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        allergens.forEach { allergen ->
            AllergenBadge(allergen = allergen)
        }
    }
}
