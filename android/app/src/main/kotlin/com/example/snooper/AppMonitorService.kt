package com.app.snooper

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.app.usage.UsageStatsManager
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import android.content.pm.ServiceInfo


class AppMonitorService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private val executor = Executors.newSingleThreadScheduledExecutor()
    private val TAG = "AppMonitorService"
    private val CHANNEL_ID = "AppMonitorChannel"
    private val NOTIFICATION_ID = 1001

    companion object {
        private var methodChannel: MethodChannel? = null
        
        fun setMethodChannel(channel: MethodChannel) {
            methodChannel = channel
        }
    }

    override fun onCreate() {
    super.onCreate()
    createNotificationChannel()
    
    // For Android 12+ (API 31+)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        startForeground(NOTIFICATION_ID, createNotification(), ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
    } else {
        startForeground(NOTIFICATION_ID, createNotification())
    }
}

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startMonitoring()
        return START_STICKY
    }

    private fun startMonitoring() {
        executor.scheduleAtFixedRate({
            try {
                val currentApp = getCurrentForegroundApp()
                currentApp?.let {
                    Log.d(TAG, "Current foreground app: $it")
                    sendAppInfoToFlutter(it)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error monitoring apps: ${e.message}")
            }
        }, 0, 5, TimeUnit.SECONDS)
    }

    private fun getCurrentForegroundApp(): String? {
        try {
            val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val endTime = System.currentTimeMillis()
            val beginTime = endTime - 10000 // Look at last 10 seconds
            
            val usageStats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY, beginTime, endTime
            )
            
            if (usageStats.isNotEmpty()) {
                // Find the most recently used app
                return usageStats.maxByOrNull { it.lastTimeUsed }?.packageName
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting current app: ${e.message}")
        }
        return null
    }

    private fun sendAppInfoToFlutter(packageName: String) {
        try {
            // Get app name
            val packageManager = applicationContext.packageManager
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            val appName = packageManager.getApplicationLabel(appInfo).toString()
            
            handler.post {
                methodChannel?.invokeMethod("onAppDetected", mapOf(
                    "packageName" to packageName,
                    "appName" to appName,
                    "timestamp" to System.currentTimeMillis()
                ))
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error sending app info to Flutter: ${e.message}")
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "App Monitor Service"
            val descriptionText = "Monitors currently active applications"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("App Monitor Active")
            .setContentText("Monitoring active applications")
            .setSmallIcon(android.R.drawable.ic_menu_info_details)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        executor.shutdown()
        super.onDestroy()
    }
}