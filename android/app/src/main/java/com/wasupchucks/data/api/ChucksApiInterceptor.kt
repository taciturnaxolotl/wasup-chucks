package com.wasupchucks.data.api

import okhttp3.Interceptor
import okhttp3.Response
import javax.inject.Inject

class ChucksApiInterceptor @Inject constructor() : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val originalRequest = chain.request()

        val builder = originalRequest.newBuilder()
            .header("Accept", "*/*")

        // Only the Cedarville menu API expects to be called from cedarville.edu.
        // The service-hours feed is Pioneer's, and iOS sends it a bare request;
        // stamping someone else's Origin on it invites a rejection.
        if (originalRequest.url.host.endsWith("cedarville.edu")) {
            builder
                .header("Origin", "https://www.cedarville.edu")
                .header("Referer", "https://www.cedarville.edu/offices/the-commons")
        }

        return chain.proceed(builder.build())
    }
}
