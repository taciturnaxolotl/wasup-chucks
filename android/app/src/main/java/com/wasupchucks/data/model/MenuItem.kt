package com.wasupchucks.data.model

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class MenuItem(
    val name: String,
    val allergens: List<Allergen>
) {
    val id: String
        get() = "$name-${allergens.joinToString("") { it.alt }}"
}
