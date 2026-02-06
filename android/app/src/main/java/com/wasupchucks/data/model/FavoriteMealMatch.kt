package com.wasupchucks.data.model

data class FavoriteMealMatch(
    val dateKey: String,
    val meal: MealPhase,
    val matchedItems: List<String>
)

fun findFavoriteMatches(
    menus: Map<String, List<VenueMenu>>,
    favoriteItems: Set<String>,
    favoriteKeywords: Set<String>
): List<FavoriteMealMatch> {
    if (favoriteItems.isEmpty() && favoriteKeywords.isEmpty()) return emptyList()

    val results = mutableListOf<FavoriteMealMatch>()

    for ((dateKey, venues) in menus) {
        val slots = venues.groupBy { it.slot }

        for ((slot, slotVenues) in slots) {
            val meal = mealPhaseForSlot(slot) ?: continue

            val matched = mutableListOf<String>()
            for (venue in slotVenues) {
                for (item in venue.items) {
                    if (favoriteItems.contains(item.name)) {
                        matched.add(item.name)
                        continue
                    }
                    val lowered = item.name.lowercase()
                    if (favoriteKeywords.any { lowered.contains(it.lowercase()) }) {
                        matched.add(item.name)
                    }
                }
            }

            if (matched.isNotEmpty()) {
                results.add(FavoriteMealMatch(dateKey, meal, matched))
            }
        }
    }

    return results
}

private fun mealPhaseForSlot(slot: String): MealPhase? {
    return when (slot) {
        "breakfast" -> MealPhase.BREAKFAST
        "lunch" -> MealPhase.LUNCH
        "dinner" -> MealPhase.DINNER
        else -> null
    }
}
