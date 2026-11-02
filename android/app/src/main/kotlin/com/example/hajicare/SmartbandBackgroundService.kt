package com.example.hajicare

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * Android Foreground Service untuk menjaga koneksi Bluetooth Low Energy (BLE)
 * dengan Smartband HajiCare (ESP32-S3) tetap aktif 24/7 di latar belakang,
 * bahkan saat layar HP dimatikan, di dalam saku, maupun aplikasi di-minimize.
 */
class SmartbandBackgroundService : Service() {

    companion object {
        private const val TAG = "SmartbandBgService"
        const val CHANNEL_ID = "hajicare_smartband_channel"
        const val CHANNEL_NAME = "HajiCare Smartband 24/7 Monitor"
        const val NOTIFICATION_ID = 992002

        const val ACTION_START = "com.hajicare.ACTION_START_SMARTBAND_SERVICE"
        const val ACTION_UPDATE = "com.hajicare.ACTION_UPDATE_SMARTBAND_NOTIFICATION"
        const val ACTION_STOP = "com.hajicare.ACTION_STOP_SMARTBAND_SERVICE"

        const val EXTRA_TITLE = "extra_title"
        const val EXTRA_MESSAGE = "extra_message"

        @Volatile
        var isRunning = false
            private set
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private var lastTitle: String = "HajiCare Smartband Terhubung"
    private var lastMessage: String = "Monitor Sensor & AI Siaga 24/7"

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        acquireWakeLock()
        isRunning = true
        Log.i(TAG, "SmartbandBackgroundService dibuat dan wakeLock diperoleh.")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: ACTION_START

        when (action) {
            ACTION_STOP -> {
                Log.i(TAG, "Menerima perintah STOP. Menghentikan service...")
                stopServiceSafely()
                return START_NOT_STICKY
            }
            ACTION_UPDATE -> {
                val newTitle = intent?.getStringExtra(EXTRA_TITLE)
                val newMessage = intent?.getStringExtra(EXTRA_MESSAGE)
                if (!newTitle.isNullOrBlank()) lastTitle = newTitle
                if (!newMessage.isNullOrBlank()) lastMessage = newMessage

                updateNotification(lastTitle, lastMessage)
                return START_STICKY
            }
            ACTION_START -> {
                val title = intent?.getStringExtra(EXTRA_TITLE)
                val message = intent?.getStringExtra(EXTRA_MESSAGE)
                if (!title.isNullOrBlank()) lastTitle = title
                if (!message.isNullOrBlank()) lastMessage = message

                startInForeground(lastTitle, lastMessage)
                return START_STICKY
            }
            else -> {
                startInForeground(lastTitle, lastMessage)
                return START_STICKY
            }
        }
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        Log.i(TAG, "Aplikasi dibersihkan dari recent apps. Layanan tetap hidup via START_STICKY.")
    }

    override fun onDestroy() {
        Log.i(TAG, "SmartbandBackgroundService dihentikan.")
        isRunning = false
        releaseWakeLock()
        super.onDestroy()
    }

    private fun startInForeground(title: String, message: String) {
        val notification = buildNotification(title, message)

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
            isRunning = true
            Log.i(TAG, "Foreground service aktif: $title - $message")
        } catch (e: Exception) {
            Log.e(TAG, "Gagal memulai startForeground: ${e.message}", e)
        }
    }

    private fun updateNotification(title: String, message: String) {
        if (!isRunning) return
        val notification = buildNotification(title, message)
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        manager?.notify(NOTIFICATION_ID, notification)
    }

    private fun buildNotification(title: String, message: String): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName) ?: Intent(this, MainActivity::class.java)
        launchIntent.flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val smallIcon = applicationInfo.icon.takeIf { it != 0 } ?: android.R.drawable.stat_notify_sync

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(smallIcon)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
            val existing = manager.getNotificationChannel(CHANNEL_ID)
            if (existing == null) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "Mempertahankan koneksi sensor gelang pintar & AI Voice 24/7"
                    setShowBadge(false)
                    enableLights(false)
                    enableVibration(false)
                }
                manager.createNotificationChannel(channel)
            }
        }
    }

    private fun acquireWakeLock() {
        try {
            if (wakeLock == null) {
                val pm = getSystemService(Context.POWER_SERVICE) as? PowerManager
                wakeLock = pm?.newWakeLock(
                    PowerManager.PARTIAL_WAKE_LOCK,
                    "HajiCare:SmartbandKeepAliveWakeLock"
                )?.apply {
                    setReferenceCounted(false)
                    acquire(24 * 60 * 60 * 1000L) // Maksimal 24 jam keep-alive
                }
                Log.d(TAG, "WakeLock berhasil diaktifkan.")
            }
        } catch (e: Exception) {
            Log.w(TAG, "Gagal mengaktifkan WakeLock: ${e.message}")
        }
    }

    private fun releaseWakeLock() {
        try {
            wakeLock?.let {
                if (it.isHeld) {
                    it.release()
                    Log.d(TAG, "WakeLock dilepaskan.")
                }
            }
            wakeLock = null
        } catch (e: Exception) {
            Log.w(TAG, "Gagal melepaskan WakeLock: ${e.message}")
        }
    }

    private fun stopServiceSafely() {
        isRunning = false
        releaseWakeLock()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }
}

