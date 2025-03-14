package com.app.snooper

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Process
import android.provider.Settings
import android.widget.Toast
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL_NAME = "utilsChannel"
    private val BACKGROUND_CHANNEL = "com.app.snooper/background"
    private lateinit var methodChannel: MethodChannel
    private lateinit var backgroundChannel: MethodChannel

    @RequiresApi(Build.VERSION_CODES.O)
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "showNativeAndroidToast" -> {
                    val message = call.argument<String>("message")
                    val duration = call.argument<Int?>("duration")
                    if (duration != null) {
                        Toast.makeText(this, message, duration).show()
                    } else {
                        Toast.makeText(this, message, Toast.LENGTH_LONG).show()
                    }
                    result.success("success")
                }

                "startBackgroundService" -> {
                    startBackgroundService()
                    result.success("success")
                }

                "stopBackgroundService" -> {
                    stopBackgroundService()
                    result.success("success")
                }

                "registerBackgroundCallback" -> {
                    val callbackHandle = call.argument<Long>("callbackHandle")
                    if (callbackHandle != null) {
                        FlutterBackgroundHelper.initialize(applicationContext, callbackHandle)
                        BackgroundNotificationWorker.schedule(applicationContext)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "callbackHandle is required", null)
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }

        backgroundChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACKGROUND_CHANNEL)

        startBackgroundService()
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun startBackgroundService() {
        val serviceIntent = Intent(this, BackgroundNotificationService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }

        // Also schedule the WorkManager
        BackgroundNotificationWorker.schedule(applicationContext)
    }

    private fun stopBackgroundService() {
        val serviceIntent = Intent(this, BackgroundNotificationService::class.java)
        stopService(serviceIntent)

        // Also cancel the WorkManager
        BackgroundNotificationWorker.cancel(applicationContext)
    }
}