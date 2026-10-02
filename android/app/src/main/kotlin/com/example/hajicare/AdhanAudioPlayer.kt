package com.example.hajicare

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.PowerManager
import android.util.Log

object AdhanAudioPlayer {
    private const val TAG = "AdhanAudioPlayer"

    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null

    @Volatile
    var isPlaying: Boolean = false
        private set

    fun play(
        context: Context,
        isSubuh: Boolean,
        onComplete: (() -> Unit)? = null
    ) {
        stop()

        try {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
            wakeLock = powerManager?.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "HajiCare::AdhanWakeLock"
            )?.apply {
                acquire(5 * 60 * 1000L) // 5 minutes max
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to acquire wake lock: ${e.message}")
        }

        val rawResId = if (isSubuh) R.raw.adzan_subuh else R.raw.adzan_regular
        val audioAttributes = AudioAttributes.Builder()
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .setUsage(AudioAttributes.USAGE_ALARM)
            .build()

        try {
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(audioAttributes)
                val afd = context.resources.openRawResourceFd(rawResId)
                if (afd != null) {
                    setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                    afd.close()
                    prepare()
                    setOnCompletionListener {
                        Log.d(TAG, "Adhan audio playback completed naturally.")
                        stop()
                        onComplete?.invoke()
                    }
                    setOnErrorListener { _, what, extra ->
                        Log.e(TAG, "MediaPlayer error: what=$what, extra=$extra")
                        stop()
                        onComplete?.invoke()
                        true
                    }
                    start()
                    this@AdhanAudioPlayer.isPlaying = true
                    Log.d(TAG, "Adhan audio player started successfully on USAGE_ALARM stream.")
                } else {
                    Log.e(TAG, "Could not open raw resource fd for: $rawResId")
                    stop()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize and start MediaPlayer: ${e.message}", e)
            stop()
        }
    }

    fun stop() {
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

        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error releasing wake lock: ${e.message}")
        } finally {
            wakeLock = null
        }

        isPlaying = false
    }
}
