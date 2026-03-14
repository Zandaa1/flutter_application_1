package com.example.flutter_application_1

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Create notification channel for background service
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "fleet_driver_channel",
                "Fleet Driver Background Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows when Fleet Driver is running in the background"
                // Make channel non-blockable to prevent users from turning it off
                setBlockable(false)
                // Prevent notification sound and vibration
                setSound(null, null)
                enableVibration(false)
                // Lock screen visibility
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
                // Show badge
                setShowBadge(true)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
        
        // Request battery optimization exclusion to ensure background service runs
        requestBatteryOptimizationExclusion()
    }
    
    private fun requestBatteryOptimizationExclusion() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent()
            val packageName = packageName
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            
            // Check if battery optimization is already disabled
            if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                // Request to disable battery optimization
                intent.action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                intent.data = Uri.parse("package:$packageName")
                try {
                    startActivity(intent)
                } catch (e: Exception) {
                    // If the intent fails, open battery optimization settings
                    val settingsIntent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                    startActivity(settingsIntent)
                }
            }
        }
    }
}

