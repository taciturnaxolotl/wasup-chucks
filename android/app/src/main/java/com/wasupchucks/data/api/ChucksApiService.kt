package com.wasupchucks.data.api

import com.wasupchucks.data.model.MenuResponse
import retrofit2.http.GET
import retrofit2.http.Query

interface ChucksApiService {
    @GET("menus")
    suspend fun fetchMenu(
        @Query("days") days: Int = 5
    ): MenuResponse
}
