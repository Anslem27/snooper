package com.app.snooper

import android.content.Context
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation
import io.flutter.view.FlutterMain
import java.util.concurrent.atomic.AtomicBoolean

object FlutterBackgroundHelper {
    private const val SHARED_PREFERENCES_NAME = "com.app.snooper.background_helper"
    private const val CALLBACK_HANDLE_KEY = "callback_handle"
    private const val CHANNEL_NAME = "com.app.snooper/background"

    private var backgroundFlutterEngine: FlutterEngine? = null
    private var methodChannel: MethodChannel? = null
    private val isInitialized = AtomicBoolean(false)

    fun initialize(context: Context, callbackHandle: Long) {
        // Save the callback handle
        val prefs = context.getSharedPreferences(SHARED_PREFERENCES_NAME, Context.MODE_PRIVATE)
        prefs.edit().putLong(CALLBACK_HANDLE_KEY, callbackHandle).apply()
    }

    fun checkStatusNow(context: Context) {
        ensureInitialized(context)

        methodChannel?.invokeMethod("checkStatusNow", null, object : MethodChannel.Result {
            override fun success(result: Any?) {
            }

            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
            }

            override fun notImplemented() {
            }
        })
    }

    private fun ensureInitialized(context: Context) {
        if (isInitialized.get()) return

        val prefs = context.getSharedPreferences(SHARED_PREFERENCES_NAME, Context.MODE_PRIVATE)
        val callbackHandle = prefs.getLong(CALLBACK_HANDLE_KEY, 0)

        if (callbackHandle == 0L) {
            // No callback handle saved, can't initialize
            return
        }

        FlutterMain.ensureInitializationComplete(context, null)

        val callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(callbackHandle)
            ?: return

        // Create a background FlutterEngine
        backgroundFlutterEngine = FlutterEngine(context)

        val args = Bundle()
        args.putLong("callbackHandle", callbackHandle)
        backgroundFlutterEngine!!.dartExecutor.executeDartCallback(
            DartExecutor.DartCallback(
                context.assets,
                FlutterMain.findAppBundlePath(),
                callbackInfo
            )
        )

        // Create method channel
        methodChannel = MethodChannel(
            backgroundFlutterEngine!!.dartExecutor.binaryMessenger,
            CHANNEL_NAME
        )

        isInitialized.set(true)
    }
}