package com.example.hajicare

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat

class AdhanPlaybackService : Service() {
    companion object {
        private const val TAG = "AdhanPlaybackService"
        const val CHANNEL_ID = "adhan_foreground_playback_channel"
        const val CHANNEL_NAME = "Lantunan Adzan (Media Playback)"
        const val NOTIFICATION_ID = 991001

        const val ACTION_START = "com.hajicare.ACTION_START_ADHAN"
        const val ACTION_STOP = "com.hajicare.ACTION_STOP_ADHAN"

        const val EXTRA_PRAYER_NAME = "extra_prayer_name"
        const val EXTRA_IS_SUBUH = "extra_is_subuh"
        const val EXTRA_NOTIFICATION_ID = "extra_notification_id"

        @Volatile
        var isRunning = false
            private set
    }

    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var activeFallbackNotifId: Int = 0

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: ACTION_START
        if (action == ACTION_STOP) {
            Log.d(TAG, "Stop action received, halting adhan playback.")
            stopAdhanPlayback()
            return START_NOT_STICKY
        }

        val prayerName = intent?.getStringExtra(EXTRA_PRAYER_NAME) ?: "Waktu Salat"
        val isSubuh = intent?.getBooleanExtra(EXTRA_IS_SUBUH, false) ?: false
        val notificationId = intent?.getIntExtra(EXTRA_NOTIFICATION_ID, 0) ?: 0
        activeFallbackNotifId = notificationId

        Log.d(TAG, "Starting adhan foreground playback for: $prayerName, isSubuh: $isSubuh")
        startAdhanPlayback(prayerName, isSubuh, notificationId)

        return START_NOT_STICKY
    }

    private fun startAdhanPlayback(prayerName: String, isSubuh: Boolean, notificationId: Int) {
        // Stop any existing playback first
        stopMediaPlayerOnly()

        // Cancel any fallback local notification to guarantee only 1 notification is displayed
        if (notificationId != 0) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            notificationManager?.cancel(notificationId)
        }
        stopMediaPlayerOnly()

        // Acquire WakeLock (max 6 minutes) to ensure continuous playback when screen is locked
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager
            wakeLock = powerManager?.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "HajiCare::AdhanWakeLock"
            )?.apply {
                acquire(6 * 60 * 1000L)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to acquire wake lock: ${e.message}")
        }

        // Build and display foreground notification with "Matikan Adzan" button
        val notification = buildForegroundNotification(prayerName)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
        isRunning = true

        // Play the authentic recording
        val rawResId = if (isSubuh) R.raw.adzan_subuh else R.raw.adzan_regular
        try {
            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .build()

            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(audioAttributes)
                val afd = resources.openRawResourceFd(rawResId)
                if (afd != null) {
                    setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                    afd.close()
                    prepare()
                    setOnCompletionListener {
                        Log.d(TAG, "Adhan audio playback completed naturally.")
                        stopAdhanPlayback()
                    }
                    setOnErrorListener { _, what, extra ->
                        Log.e(TAG, "MediaPlayer error: what=$what, extra=$extra")
                        stopAdhanPlayback()
                        true
                    }
                    start()
                    Log.d(TAG, "Adhan MediaPlayer started successfully.")
                } else {
                    Log.e(TAG, "Could not open raw resource fd for: $rawResId")
                    stopAdhanPlayback()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize and start MediaPlayer: ${e.message}", e)
            stopAdhanPlayback()
        }
    }

    private fun buildForegroundNotification(prayerName: String): Notification {
        // Tap on notification opens the app MainActivity
        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Action button to stop adhan immediately
        val stopIntent = Intent(this, AdhanPlaybackService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this,
            1,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Waktu Salat $prayerName Telah Tiba")
            .setContentText("Lantunan suara adzan sedang berkumandang")
            .setSmallIcon(R.mipmap.launcher_icon)
            .setOngoing(true)
            .setAutoCancel(false)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(openAppPendingIntent)
            .addAction(
                android.R.drawable.ic_media_pause,
                "Matikan Adzan",
                stopPendingIntent
            )
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifikasi pemutar lantunan suara adzan di background"
                setSound(null, null) // Audio is actively played by MediaPlayer
                enableVibration(true)
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            manager?.createNotificationChannel(channel)
        }
    }

    private fun stopMediaPlayerOnly() {
        try {
            if (mediaPlayer?.isPlaying == true) {
                mediaPlayer?.stop()
            }
            mediaPlayer?.reset()
            mediaPlayer?.release()
        } catch (e: Exception) {
            Log.w(TAG, "Error stopping media player: ${e.message}")
        } finally {
            mediaPlayer = null
        }
    }

    private fun stopAdhanPlayback() {
        stopMediaPlayerOnly()
        try {
            if (activeFallbackNotifId != 0) {
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                notificationManager?.cancel(activeFallbackNotifId)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error cancelling fallback notification: ${e.message}")
        }
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error releasing wake lock: ${e.message}")
        } finally {
            wakeLock = null
        }

        isRunning = false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    override fun onDestroy() {
        stopMediaPlayerOnly()
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error releasing wake lock in onDestroy: ${e.message}")
        }
        isRunning = false
        super.onDestroy()
    }
}
