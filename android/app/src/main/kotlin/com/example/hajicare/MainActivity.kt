package com.example.hajicare

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Log
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.view.View
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val TAG = "BISINDO_MAIN"
        private const val METHOD_CHANNEL_NAME = "com.hajicare.bisindo/camera_control"
        private const val EVENT_CHANNEL_NAME = "com.hajicare.bisindo/landmarks"
        private const val PREVIEW_VIEW_TYPE = "com.hajicare.bisindo/camera_preview"
        private const val CAMERA_PERMISSION_REQUEST_CODE = 1001
        private const val BLE_PERMISSION_REQUEST_CODE = 1002
        private const val TTS_INSTALLER_CHANNEL = "com.hajicare.tts/voice_installer"
        private const val SMARTBAND_SERVICE_CHANNEL = "com.hajicare/smartband_background_service"
    }

    private var cameraHelper: BisindoCameraHelper? = null
    private var activePreviewView: androidx.camera.view.PreviewView? = null
    private var landmarkEventSink: EventChannel.EventSink? = null
    private var isCameraRequested = false
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingBlePermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Setup PlatformView for Camera Preview
        flutterEngine.platformViewsController.registry.registerViewFactory(
            PREVIEW_VIEW_TYPE,
            object : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
                override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
                    return object : PlatformView {
                        private val previewView = try {
                            androidx.camera.view.PreviewView(context).also { pv ->
                                pv.implementationMode = androidx.camera.view.PreviewView.ImplementationMode.COMPATIBLE
                                activePreviewView = pv
                                cameraHelper?.attachPreviewView(pv)
                            }
                        } catch (t: Throwable) {
                            Log.e(TAG, "Failed creating PreviewView: ${t.message}", t)
                            View(context)
                        }

                        override fun getView(): View = previewView

                        override fun dispose() {
                            try {
                                if (activePreviewView == previewView) {
                                    cameraHelper?.detachPreviewView()
                                    activePreviewView = null
                                }
                            } catch (t: Throwable) {
                                Log.e(TAG, "Error disposing PreviewView: ${t.message}", t)
                            }
                        }
                    }
                }
            }
        )

        // 2. Setup EventChannel for streaming 543 landmarks to Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL_NAME)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    landmarkEventSink = events
                    Log.d(TAG, "Landmark EventChannel subscribed")
                }

                override fun onCancel(arguments: Any?) {
                    landmarkEventSink = null
                    Log.d(TAG, "Landmark EventChannel unsubscribed")
                }
            })

        // 3. Setup MethodChannel for camera controls & permissions
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkPermission" -> {
                        val status = if (ContextCompat.checkSelfPermission(
                                this,
                                Manifest.permission.CAMERA
                            ) == PackageManager.PERMISSION_GRANTED
                        ) {
                            "granted"
                        } else {
                            "denied"
                        }
                        result.success(status)
                    }
                    "requestPermission" -> {
                        if (ContextCompat.checkSelfPermission(
                                this,
                                Manifest.permission.CAMERA
                            ) == PackageManager.PERMISSION_GRANTED
                        ) {
                            result.success("granted")
                        } else {
                            pendingPermissionResult = result
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(Manifest.permission.CAMERA),
                                CAMERA_PERMISSION_REQUEST_CODE
                            )
                        }
                    }
                    "startCamera" -> {
                        isCameraRequested = true
                        startBisindoCamera(result)
                    }
                    "stopCamera" -> {
                        isCameraRequested = false
                        stopBisindoCamera(result)
                    }
                    "switchCamera" -> {
                        try {
                            val helper = getOrCreateCameraHelper()
                            val isFront = helper.switchCamera()
                            result.success(if (isFront) "front" else "back")
                        } catch (t: Throwable) {
                            Log.e(TAG, "Error switching camera: ${t.message}", t)
                            result.error("SWITCH_FAILED", t.message, null)
                        }
                    }
                    "setLensFacing" -> {
                        try {
                            val facing = call.argument<String>("facing") ?: "front"
                            val helper = getOrCreateCameraHelper()
                            helper.setLensFacing(facing == "front")
                            result.success(true)
                        } catch (t: Throwable) {
                            Log.e(TAG, "Error setting lens facing: ${t.message}", t)
                            result.error("SET_FACING_FAILED", t.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // 4. Setup MethodChannel for TTS Voice Pack installation and settings
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TTS_INSTALLER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "installVoiceData" -> {
                        try {
                            val installIntent = Intent(android.speech.tts.TextToSpeech.Engine.ACTION_INSTALL_TTS_DATA).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(installIntent)
                            result.success(true)
                        } catch (e: Exception) {
                            try {
                                val settingsIntent = Intent("com.android.settings.TTS_SETTINGS").apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(settingsIntent)
                                result.success(true)
                            } catch (e2: Exception) {
                                result.error("TTS_INSTALL_FAILED", e2.message, null)
                            }
                        }
                    }
                    "openTtsSettings" -> {
                        try {
                            val settingsIntent = Intent("com.android.settings.TTS_SETTINGS").apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(settingsIntent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("TTS_SETTINGS_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // 5. Setup MethodChannel for Native Adhan Foreground Service & Alarms
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.hajicare/adhan_native_service")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startAdhanService" -> {
                        try {
                            val prayerName = call.argument<String>("prayerName") ?: "Waktu Salat"
                            val isSubuh = call.argument<Boolean>("isSubuh") ?: false
                            val serviceIntent = Intent(this, AdhanPlaybackService::class.java).apply {
                                action = AdhanPlaybackService.ACTION_START
                                putExtra(AdhanPlaybackService.EXTRA_PRAYER_NAME, prayerName)
                                putExtra(AdhanPlaybackService.EXTRA_IS_SUBUH, isSubuh)
                            }
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                startForegroundService(serviceIntent)
                            } else {
                                startService(serviceIntent)
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e("ADHAN_MAIN", "Error starting Adhan service: ${e.message}", e)
                            result.error("START_FAILED", e.message, null)
                        }
                    }
                    "stopAdhanService" -> {
                        try {
                            val stopIntent = Intent(this, AdhanPlaybackService::class.java).apply {
                                action = AdhanPlaybackService.ACTION_STOP
                            }
                            startService(stopIntent)
                            AdhanAudioPlayer.stop()
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e("ADHAN_MAIN", "Error stopping Adhan service: ${e.message}", e)
                            result.error("STOP_FAILED", e.message, null)
                        }
                    }
                    "isServiceRunning" -> {
                        result.success(AdhanPlaybackService.isRunning || AdhanAudioPlayer.isPlaying)
                    }
                    "scheduleNativeAdhan" -> {
                        try {
                            val id = call.argument<Int>("id") ?: 0
                            val prayerName = call.argument<String>("prayerName") ?: "Waktu Salat"
                            val isSubuh = call.argument<Boolean>("isSubuh") ?: false
                            val triggerTimestampMs = call.argument<Number>("triggerTimestampMs")?.toLong() ?: 0L

                            val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                            val intent = Intent(this, AdhanAlarmReceiver::class.java).apply {
                                action = AdhanAlarmReceiver.ACTION_PLAY_ADHAN_ALARM
                                putExtra(AdhanAlarmReceiver.EXTRA_PRAYER_NAME, prayerName)
                                putExtra(AdhanAlarmReceiver.EXTRA_IS_SUBUH, isSubuh)
                                putExtra(AdhanAlarmReceiver.EXTRA_NOTIFICATION_ID, id)
                            }
                            val pendingIntent = PendingIntent.getBroadcast(
                                this,
                                id,
                                intent,
                                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                            )
                            if (alarmManager != null && triggerTimestampMs > System.currentTimeMillis()) {
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerTimestampMs, pendingIntent)
                                } else {
                                    alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerTimestampMs, pendingIntent)
                                }
                                result.success(true)
                            } else {
                                result.success(false)
                            }
                        } catch (e: Exception) {
                            Log.e("ADHAN_MAIN", "Error scheduling native adhan: ${e.message}", e)
                            result.error("SCHEDULE_FAILED", e.message, null)
                        }
                    }
                    "cancelNativeAdhan" -> {
                        try {
                            val id = call.argument<Int>("id") ?: 0
                            val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                            val intent = Intent(this, AdhanAlarmReceiver::class.java).apply {
                                action = AdhanAlarmReceiver.ACTION_PLAY_ADHAN_ALARM
                            }
                            val pendingIntent = PendingIntent.getBroadcast(
                                this,
                                id,
                                intent,
                                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                            )
                            if (alarmManager != null) {
                                alarmManager.cancel(pendingIntent)
                            }
                            pendingIntent.cancel()
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e("ADHAN_MAIN", "Error cancelling native adhan: ${e.message}", e)
                            result.error("CANCEL_FAILED", e.message, null)
                        }
                    }
                    "cancelAllNativeAdhans" -> {
                        try {
                            val alarmManager = getSystemService(Context.ALARM_SERVICE) as? AlarmManager
                            if (alarmManager != null) {
                                for (day in 0..14) {
                                    for (p in 0..9) {
                                        val notifId = 91000 + (day * 10) + p
                                        val reminderId = 92000 + (day * 10) + p

                                        val intent1 = Intent(this, AdhanAlarmReceiver::class.java).apply {
                                            action = AdhanAlarmReceiver.ACTION_PLAY_ADHAN_ALARM
                                        }
                                        val pi1 = PendingIntent.getBroadcast(
                                            this,
                                            notifId,
                                            intent1,
                                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                                        )
                                        alarmManager.cancel(pi1)
                                        pi1.cancel()

                                        val pi2 = PendingIntent.getBroadcast(
                                            this,
                                            reminderId,
                                            intent1,
                                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                                        )
                                        alarmManager.cancel(pi2)
                                        pi2.cancel()
                                    }
                                }
                                val testIntent = Intent(this, AdhanAlarmReceiver::class.java).apply {
                                    action = AdhanAlarmReceiver.ACTION_PLAY_ADHAN_ALARM
                                }
                                val piTest = PendingIntent.getBroadcast(
                                    this,
                                    99999,
                                    testIntent,
                                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                                )
                                alarmManager.cancel(piTest)
                                piTest.cancel()
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e("ADHAN_MAIN", "Error cancelling all native adhans: ${e.message}", e)
                            result.error("CANCEL_ALL_FAILED", e.message, null)
                        }

                    }
                    else -> result.notImplemented()
                }
            }

        // 6. Setup MethodChannel for Smartband 24/7 Foreground Service & Battery Optimization
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMARTBAND_SERVICE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> {
                        try {
                            val title = call.argument<String>("title") ?: "HajiCare Smartband Terhubung"
                            val message = call.argument<String>("message") ?: "Monitor Sensor & AI Siaga 24/7"
                            val intent = Intent(this, SmartbandBackgroundService::class.java).apply {
                                action = SmartbandBackgroundService.ACTION_START
                                putExtra(SmartbandBackgroundService.EXTRA_TITLE, title)
                                putExtra(SmartbandBackgroundService.EXTRA_MESSAGE, message)
                            }
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                ContextCompat.startForegroundService(this, intent)
                            } else {
                                startService(intent)
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e("SmartbandBg", "Error starting SmartbandBackgroundService: ${e.message}", e)
                            result.error("START_FAILED", e.message, null)
                        }
                    }
                    "updateNotification" -> {
                        try {
                            val title = call.argument<String>("title") ?: "HajiCare Smartband Terhubung"
                            val message = call.argument<String>("message") ?: "Monitor Sensor & AI Siaga 24/7"
                            val intent = Intent(this, SmartbandBackgroundService::class.java).apply {
                                action = SmartbandBackgroundService.ACTION_UPDATE
                                putExtra(SmartbandBackgroundService.EXTRA_TITLE, title)
                                putExtra(SmartbandBackgroundService.EXTRA_MESSAGE, message)
                            }
                            startService(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("UPDATE_FAILED", e.message, null)
                        }
                    }
                    "stopService" -> {
                        try {
                            val intent = Intent(this, SmartbandBackgroundService::class.java).apply {
                                action = SmartbandBackgroundService.ACTION_STOP
                            }
                            startService(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("STOP_FAILED", e.message, null)
                        }
                    }
                    "isServiceRunning" -> {
                        result.success(SmartbandBackgroundService.isRunning)
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                val pm = getSystemService(Context.POWER_SERVICE) as? android.os.PowerManager
                                val isIgnoring = pm?.isIgnoringBatteryOptimizations(packageName) ?: false
                                if (!isIgnoring) {
                                    val intent = Intent(android.provider.Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                        data = android.net.Uri.parse("package:$packageName")
                                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    }
                                    startActivity(intent)
                                }
                                result.success(true)
                            } else {
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            try {
                                val intent = Intent(android.provider.Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                result.success(true)
                            } catch (e2: Exception) {
                                result.error("BATTERY_OPT_FAILED", e2.message, null)
                            }
                        }
                    }
                    "isBatteryOptimizationIgnored" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val pm = getSystemService(Context.POWER_SERVICE) as? android.os.PowerManager
                            result.success(pm?.isIgnoringBatteryOptimizations(packageName) ?: false)
                        } else {
                            result.success(true)
                        }
                    }
                    "ensureBlePermissions" -> {
                        val needed = mutableListOf<String>()
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN) != PackageManager.PERMISSION_GRANTED) {
                                needed.add(Manifest.permission.BLUETOOTH_SCAN)
                            }
                            if (ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) != PackageManager.PERMISSION_GRANTED) {
                                needed.add(Manifest.permission.BLUETOOTH_CONNECT)
                            }
                        } else {
                            if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                                needed.add(Manifest.permission.ACCESS_FINE_LOCATION)
                            }
                        }
                        if (needed.isEmpty()) {
                            result.success(true)
                        } else {
                            pendingBlePermissionResult = result
                            ActivityCompat.requestPermissions(this, needed.toTypedArray(), BLE_PERMISSION_REQUEST_CODE)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == CAMERA_PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(if (granted) "granted" else "denied")
            pendingPermissionResult = null
        } else if (requestCode == BLE_PERMISSION_REQUEST_CODE) {
            val allGranted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            pendingBlePermissionResult?.success(allGranted)
            pendingBlePermissionResult = null
        }
    }

    private fun getOrCreateCameraHelper(): BisindoCameraHelper {
        if (cameraHelper == null) {
            cameraHelper = BisindoCameraHelper(
                context = applicationContext,
                lifecycleOwner = this,
                onFrameReady = { frameMap ->
                    runOnUiThread {
                        try {
                            landmarkEventSink?.success(frameMap)
                        } catch (t: Throwable) {
                            Log.w(TAG, "Error emitting landmark frame: ${t.message}")
                        }
                    }
                },
                onError = { errorMessage ->
                    runOnUiThread {
                        try {
                            landmarkEventSink?.error("CAMERA_ERROR", errorMessage, null)
                        } catch (t: Throwable) {
                            Log.w(TAG, "Error emitting camera error: ${t.message}")
                        }
                    }
                }
            )
            try {
                cameraHelper?.initialize()
            } catch (t: Throwable) {
                Log.e(TAG, "Error initializing camera helper: ${t.message}", t)
            }
            activePreviewView?.let { pv ->
                try {
                    cameraHelper?.attachPreviewView(pv)
                } catch (t: Throwable) {
                    Log.e(TAG, "Error attaching initial preview view: ${t.message}", t)
                }
            }
        }
        return cameraHelper!!
    }

    private fun startBisindoCamera(result: MethodChannel.Result) {
        try {
            val helper = getOrCreateCameraHelper()
            helper.startCamera()
            result.success(true)
        } catch (t: Throwable) {
            Log.e(TAG, "Error starting BISINDO camera: ${t.message}", t)
            result.error("START_FAILED", t.message, null)
        }
    }

    private fun stopBisindoCamera(result: MethodChannel.Result) {
        try {
            cameraHelper?.stopCamera()
            result.success(true)
        } catch (t: Throwable) {
            Log.e(TAG, "Error stopping BISINDO camera: ${t.message}", t)
            result.error("STOP_FAILED", t.message, null)
        }
    }

    override fun onPause() {
        super.onPause()
        if (isCameraRequested) {
            cameraHelper?.stopCamera()
        }
    }

    override fun onResume() {
        super.onResume()
        if (isCameraRequested) {
            cameraHelper?.startCamera()
        }
    }

    override fun onDestroy() {
        cameraHelper?.dispose()
        cameraHelper = null
        super.onDestroy()
    }
}
