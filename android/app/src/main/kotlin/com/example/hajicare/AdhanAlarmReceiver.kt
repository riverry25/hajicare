package com.example.hajicare

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat

class AdhanAlarmReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "AdhanAlarmReceiver"
        const val ACTION_PLAY_ADHAN_ALARM = "com.hajicare.ACTION_PLAY_ADHAN_ALARM"
        const val ACTION_STOP_ADHAN = "com.hajicare.ACTION_STOP_ADHAN"
        const val EXTRA_PRAYER_NAME = "extra_prayer_name"
        const val EXTRA_IS_SUBUH = "extra_is_subuh"
        const val EXTRA_NOTIFICATION_ID = "extra_notification_id"

        const val CHANNEL_ID = "adhan_alarm_channel_regular"
        const val NOTIFICATION_ID = 991001
    }

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action
        Log.d(TAG, "Adhan alarm broadcast received with action: $action")

        if (action == ACTION_STOP_ADHAN) {
            AdhanAudioPlayer.stop()
            try {
                val stopServiceIntent = Intent(context, AdhanPlaybackService::class.java).apply {
                    this.action = AdhanPlaybackService.ACTION_STOP
                }
                context.startService(stopServiceIntent)
            } catch (e: Exception) {
                Log.w(TAG, "Error stopping AdhanPlaybackService: ${e.message}")
            }
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            nm?.cancel(NOTIFICATION_ID)
            val notifIdExtra = intent.getIntExtra(EXTRA_NOTIFICATION_ID, 0)
            if (notifIdExtra != 0 && notifIdExtra != NOTIFICATION_ID) {
                nm?.cancel(notifIdExtra)
            }
            return
        }

        val prayerName = intent?.getStringExtra(EXTRA_PRAYER_NAME) ?: "Waktu Salat"
        val isSubuh = intent?.getBooleanExtra(EXTRA_IS_SUBUH, false) ?: false
        val notifIdExtra = intent?.getIntExtra(EXTRA_NOTIFICATION_ID, 0) ?: 0

        createNotificationChannel(context)

        // 1. Try starting AdhanPlaybackService as Foreground Service
        var serviceStarted = false
        try {
            val serviceIntent = Intent(context, AdhanPlaybackService::class.java).apply {
                this.action = AdhanPlaybackService.ACTION_START
                putExtra(AdhanPlaybackService.EXTRA_PRAYER_NAME, prayerName)
                putExtra(AdhanPlaybackService.EXTRA_IS_SUBUH, isSubuh)
                putExtra(AdhanPlaybackService.EXTRA_NOTIFICATION_ID, notifIdExtra)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
            serviceStarted = true
        } catch (e: Exception) {
            Log.w(TAG, "Failed to start AdhanPlaybackService as foreground service: ${e.message}")
        }

        // 2. Fallback to standalone AdhanAudioPlayer if foreground service cannot start
        if (!serviceStarted) {
            if (notifIdExtra != 0) {
                val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                nm?.cancel(notifIdExtra)
            }
            AdhanAudioPlayer.play(context, isSubuh) {
                val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                nm?.cancel(NOTIFICATION_ID)
                if (notifIdExtra != 0) {
                    nm?.cancel(notifIdExtra)
                }
            }
            showAdhanNotification(context, prayerName, notifIdExtra)
        }
    }

    private fun showAdhanNotification(context: Context, prayerName: String, notifIdExtra: Int = 0) {
        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            context,
            0,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val stopIntent = Intent(context, AdhanAlarmReceiver::class.java).apply {
            action = ACTION_STOP_ADHAN
            putExtra(EXTRA_NOTIFICATION_ID, if (notifIdExtra != 0) notifIdExtra else NOTIFICATION_ID)
        }
        val stopPendingIntent = PendingIntent.getBroadcast(
            context,
            1,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle("Waktu Salat $prayerName Telah Tiba")
            .setContentText("Mari tunaikan salat $prayerName. Suara adzan sedang berkumandang.")
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .setBigContentTitle("Waktu Salat $prayerName Telah Tiba")
                    .bigText("Mari tunaikan salat $prayerName. Suara adzan sedang berkumandang. Ketuk 'Matikan Adzan' untuk mematikan suara.")
            )
            .setSmallIcon(R.mipmap.launcher_icon)
            .setOngoing(true)
            .setAutoCancel(false)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(openAppPendingIntent)
            .setFullScreenIntent(openAppPendingIntent, true)
            .addAction(
                android.R.drawable.ic_media_pause,
                "Matikan Adzan",
                stopPendingIntent
            )
            .build()

        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        notificationManager?.notify(NOTIFICATION_ID, notification)
        Log.d(TAG, "Adhan notification posted (id=$NOTIFICATION_ID) for $prayerName")
    }

    private fun createNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
            if (manager.getNotificationChannel(CHANNEL_ID) == null) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "Panggilan Adzan",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Notifikasi panggilan adzan waktu salat"
                    setSound(null, null) // Audio is actively handled by AdhanAudioPlayer on USAGE_ALARM stream
                    enableVibration(true)
                }
                manager.createNotificationChannel(channel)
            }
        }
    }
}
