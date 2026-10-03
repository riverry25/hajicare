package com.hajicare.adhan

import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class AdhanForegroundPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private var channel: MethodChannel? = null
    private var context: Context? = null

    companion object {
        private const val TAG = "AdhanForegroundPlugin"
        private const val CHANNEL_NAME = "com.hajicare/adhan_native_service"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel?.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        context = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val appContext = context
        if (appContext == null) {
            result.error("NO_CONTEXT", "Application context is null", null)
            return
        }

        when (call.method) {
            "startAdhanService" -> {
                try {
                    val prayerName = call.argument<String>("prayerName") ?: "Waktu Salat"
                    val isSubuh = call.argument<Boolean>("isSubuh") ?: false

                    val intent = Intent().apply {
                        setClassName(appContext.packageName, "com.example.hajicare.AdhanPlaybackService")
                        action = "com.hajicare.ACTION_START_ADHAN"
                        putExtra("extra_prayer_name", prayerName)
                        putExtra("extra_is_subuh", isSubuh)
                    }

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        ContextCompat.startForegroundService(appContext, intent)
                    } else {
                        appContext.startService(intent)
                    }
                    result.success(true)
                } catch (e: Exception) {
                    Log.e("SERVICE", "[SERVICE] ERROR: Failed to start foreground service: ${e.message}", e)
                    println("[SERVICE] ERROR: Failed to start foreground service: ${e.message}")
                    result.error("SERVICE_START_FAILED", e.message, null)
                }
            }
            "stopAdhanService" -> {
                try {
                    val intent = Intent().apply {
                        setClassName(appContext.packageName, "com.example.hajicare.AdhanPlaybackService")
                        action = "com.hajicare.ACTION_STOP_ADHAN"
                    }
                    appContext.startService(intent)
                    result.success(true)
                } catch (e: Exception) {
                    Log.e("SERVICE", "[SERVICE] ERROR: Failed to stop service: ${e.message}", e)
                    println("[SERVICE] ERROR: Failed to stop service: ${e.message}")
                    result.error("SERVICE_STOP_FAILED", e.message, null)
                }
            }
            "isServiceRunning" -> {
                try {
                    val serviceClass = Class.forName("com.example.hajicare.AdhanPlaybackService")
                    val field = serviceClass.getDeclaredField("isRunning")
                    field.isAccessible = true
                    val running = field.get(null) as? Boolean ?: false
                    result.success(running)
                } catch (e: Exception) {
                    result.success(false)
                }
            }
            else -> result.notImplemented()
        }
    }
}
