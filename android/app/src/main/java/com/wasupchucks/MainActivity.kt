package com.wasupchucks

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.material3.windowsizeclass.ExperimentalMaterial3WindowSizeClassApi
import androidx.compose.material3.windowsizeclass.calculateWindowSizeClass
import com.wasupchucks.ui.screens.home.HomeScreen
import com.wasupchucks.ui.theme.WasupChucksTheme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    @OptIn(ExperimentalMaterial3WindowSizeClassApi::class)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        setContent {
            WasupChucksTheme {
                val windowSizeClass = calculateWindowSizeClass(this)
                HomeScreen(widthSizeClass = windowSizeClass.widthSizeClass)
            }
        }
    }
}
