package com.wasupchucks.data.model

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class Allergen(
    val url: String,
    val alt: String
) {
    val symbol: String
        get() = when (alt) {
            "gluten" -> "G"
            "dairy" -> "D"
            "egg" -> "E"
            "soy" -> "S"
            "fish" -> "F"
            "hasPeanut" -> "P"
            "tree nut" -> "N"
            "hasShellfish" -> "SF"
            "vegetarian" -> "V"
            "gluten-free" -> "GF"
            else -> "?"
        }

    val displayName: String
        get() = when (alt) {
            "gluten" -> "gluten"
            "dairy" -> "dairy"
            "egg" -> "egg"
            "soy" -> "soy"
            "fish" -> "fish"
            "hasPeanut" -> "peanuts"
            "tree nut" -> "tree nuts"
            "hasShellfish" -> "shellfish"
            "vegetarian" -> "vegetarian"
            "gluten-free" -> "gluten-free"
            else -> alt
        }

    val isDietary: Boolean
        get() = alt == "vegetarian" || alt == "gluten-free"
}
