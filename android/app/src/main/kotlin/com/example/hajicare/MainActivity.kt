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
        private const val TTS_INSTALLER_CHANNEL = "com.hajicare.tts/voice_installer"
    }

    private var cameraHelper: BisindoCameraHelper? = null
    private var activePreviewView: androidx.camera.view.PreviewView? = null
    private var landmarkEventSink: EventChannel.EventSink? = null
    private var isCameraRequested = false
    private var pendingPermissionResult: MethodChannel.Result? = null

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
