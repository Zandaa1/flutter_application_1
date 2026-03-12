package com.example.flutter_application_1

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
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
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
}

