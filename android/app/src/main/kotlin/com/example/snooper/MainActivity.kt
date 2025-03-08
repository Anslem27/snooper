package com.app.snooper

import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity : FlutterActivity() {
    private val channelName = "utilsChannel"


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val utilsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)

        utilsChannel.setMethodCallHandler { call, result ->
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

                else -> {
                    result.notImplemented()
                }
            }
        }

    }
}