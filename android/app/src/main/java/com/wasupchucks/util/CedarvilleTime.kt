package com.wasupchucks.util

import java.time.ZoneId
import java.time.ZonedDateTime

object CedarvilleTime {
    val zoneId: ZoneId = ZoneId.of("America/New_York")

    fun now(): ZonedDateTime = ZonedDateTime.now(zoneId)
}
