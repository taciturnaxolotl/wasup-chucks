package com.wasupchucks

import android.app.Application
import androidx.hilt.work.HiltWorkerFactory
import androidx.work.Configuration
import com.wasupchucks.data.repository.ScheduleRepository
import com.wasupchucks.widget.WidgetRefreshWorker
import dagger.hilt.android.HiltAndroidApp
import javax.inject.Inject

@HiltAndroidApp
class WasupChucksApplication : Application(), Configuration.Provider {

    @Inject
    lateinit var workerFactory: HiltWorkerFactory

    @Inject
    lateinit var scheduleRepository: ScheduleRepository

    override val workManagerConfiguration: Configuration
        get() = Configuration.Builder()
            .setWorkerFactory(workerFactory)
            .build()

    override fun onCreate() {
        super.onCreate()
        // Apply the last known dining hours before anything does meal math
        scheduleRepository.loadCached()
        // Start periodic widget updates
        WidgetRefreshWorker.enqueue(this)
    }
}
