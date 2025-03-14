package com.app.snooper

import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.work.Worker
import androidx.work.WorkerParameters
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

class BackgroundNotificationWorker(context: Context, params: WorkerParameters) :
    Worker(context, params) {

    override fun doWork(): Result {
        // Start the foreground service if it's not running
        startForegroundService()

        triggerFlutterStatusCheck()

        return Result.success()
    }

    private fun startForegroundService() {
        val serviceIntent = Intent(applicationContext, BackgroundNotificationService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            applicationContext.startForegroundService(serviceIntent)
        } else {
            applicationContext.startService(serviceIntent)
        }
    }

    private fun triggerFlutterStatusCheck() {
        // This will be implemented to communicate with Flutter
        FlutterBackgroundHelper.checkStatusNow(applicationContext)
    }

    companion object {
        private const val WORK_NAME = "com.app.snooper.background_notification_work"

        fun schedule(context: Context) {
            val periodicWorkRequest = PeriodicWorkRequestBuilder<BackgroundNotificationWorker>(
                15, TimeUnit.MINUTES
            ) // Minimum interval for periodic work is 15 minutes
                .build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                WORK_NAME,
                ExistingPeriodicWorkPolicy.KEEP,
                periodicWorkRequest
            )
        }

        fun cancel(context: Context) {
            WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
        }
    }
}