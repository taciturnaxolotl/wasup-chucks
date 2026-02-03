package com.wasupchucks.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
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
import com.wasupchucks.ui.theme.AllergenDietary
import com.wasupchucks.ui.theme.AllergenDietaryContainer
import com.wasupchucks.ui.theme.AllergenWarning
import com.wasupchucks.ui.theme.AllergenWarningContainer

@Composable
fun AllergenBadge(
    allergen: Allergen,
    modifier: Modifier = Modifier
) {
    val backgroundColor = if (allergen.isDietary) AllergenDietaryContainer else AllergenWarningContainer
    val textColor = if (allergen.isDietary) AllergenDietary else AllergenWarning

    Surface(
        modifier = modifier,
        shape = RoundedCornerShape(4.dp),
        color = backgroundColor
    ) {
        Text(
            text = allergen.symbol,
            fontSize = 9.sp,
            fontWeight = FontWeight.Bold,
            color = textColor,
            modifier = Modifier.padding(horizontal = 5.dp, vertical = 3.dp)
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
