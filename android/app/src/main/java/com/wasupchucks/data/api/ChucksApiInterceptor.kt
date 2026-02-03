package com.wasupchucks.data.api

import okhttp3.Interceptor
import okhttp3.Response
import javax.inject.Inject

class ChucksApiInterceptor @Inject constructor() : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val originalRequest = chain.request()

        val modifiedRequest = originalRequest.newBuilder()
            .header("Accept", "*/*")
            .header("Origin", "https://www.cedarville.edu")
            .header("Referer", "https://www.cedarville.edu/offices/the-commons")
            .build()

        return chain.proceed(modifiedRequest)
    }
}
