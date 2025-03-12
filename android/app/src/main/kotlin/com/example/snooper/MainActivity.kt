package com.app.snooper

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.os.Process
import android.provider.Settings
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL_NAME = "utilsChannel"
    private lateinit var methodChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        
        // Set the method channel for the service to use
        AppMonitorService.setMethodChannel(methodChannel)

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
                "startAppMonitorService" -> {
                    if (hasUsageStatsPermission()) {
                        startAppMonitorService()
                        result.success(true)
                    } else {
                        requestUsageStatsPermission()
                        result.success(false)
                    }
                }
                "stopAppMonitorService" -> {
                    stopAppMonitorService()
                    result.success(true)
                }
                "checkUsageStatsPermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "requestUsageStatsPermission" -> {
                    requestUsageStatsPermission()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        } else {
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun requestUsageStatsPermission() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        startActivity(intent)
    }

    private fun startAppMonitorService() {
        val serviceIntent = Intent(this, AppMonitorService::class.java)
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }

    private fun stopAppMonitorService() {
        val serviceIntent = Intent(this, AppMonitorService::class.java)
        stopService(serviceIntent)
    }
}