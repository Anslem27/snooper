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
    private lateinit var methodChannel: MethodChannel

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

                else -> {
                    result.notImplemented()
                }
            }
        }

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
    }

    private fun stopBackgroundService() {
        val serviceIntent = Intent(this, BackgroundNotificationService::class.java)
        stopService(serviceIntent)
    }
}
