package com.wasupchucks.data.model

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class VenueMenu(
    val venue: String,
    val meal: String?,
    val slot: String,
    val items: List<MenuItem>
) {
    val id: String
        get() = "$venue-$slot-${meal ?: ""}"
}

typealias MenuResponse = Map<String, List<VenueMenu>>
