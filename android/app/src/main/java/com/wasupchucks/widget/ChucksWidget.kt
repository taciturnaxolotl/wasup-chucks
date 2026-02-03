package com.wasupchucks.widget

import android.content.Context
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.GlanceTheme
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.fillMaxSize
import com.wasupchucks.data.model.ChucksStatus
import com.wasupchucks.widget.ui.LargeWidgetContent
import com.wasupchucks.widget.ui.MediumWidgetContent
import com.wasupchucks.widget.ui.SmallWidgetContent

// Small Widget
class ChucksSmallWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val status = ChucksStatus.calculate()

        provideContent {
            GlanceTheme {
                SmallWidgetContent(
                    status = status
                )
            }
        }
    }
}

class ChucksWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ChucksSmallWidget()

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetRefreshWorker.enqueue(context)
    }
}

// Medium Widget
class ChucksMediumWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val status = ChucksStatus.calculate()
        val widgetData = WidgetState.load(context)

        provideContent {
            GlanceTheme {
                MediumWidgetContent(
                    status = status,
                    specials = widgetData.specials,
                    venueName = widgetData.venueName
                )
            }
        }
    }
}

class ChucksMediumWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ChucksMediumWidget()

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetRefreshWorker.enqueue(context)
    }
}

// Large Widget
class ChucksLargeWidget : GlanceAppWidget() {
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val status = ChucksStatus.calculate()
        val widgetData = WidgetState.load(context)

        provideContent {
            GlanceTheme {
                LargeWidgetContent(
                    status = status,
                    specials = widgetData.specials,
                    venueName = widgetData.venueName
                )
            }
        }
    }
}

class ChucksLargeWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = ChucksLargeWidget()

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetRefreshWorker.enqueue(context)
    }
}
