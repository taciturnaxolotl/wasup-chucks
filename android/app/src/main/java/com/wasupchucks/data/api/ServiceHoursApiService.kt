package com.wasupchucks.data.api

import com.wasupchucks.data.model.ServiceHoursLocation
import retrofit2.http.GET
import retrofit2.http.Query

interface ServiceHoursApiService {
    // Absolute URL: the hours live with Pioneer, not with Cedarville's menu API.
    @GET("https://oncampusdining.com/api/servicehours/js/v3/")
    suspend fun fetchServiceHours(
        @Query("campus") campus: String = "cedarville"
    ): List<ServiceHoursLocation>
}
