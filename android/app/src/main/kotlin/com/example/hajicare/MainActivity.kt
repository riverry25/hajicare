package com.example.hajicare

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "BISINDO_MAIN"
        private const val METHOD_CHANNEL_NAME = "com.hajicare.bisindo/camera_control"
        private const val EVENT_CHANNEL_NAME = "com.hajicare.bisindo/landmarks"
    }

    private var cameraHelper: BisindoCameraHelper? = null
    private var landmarkEventSink: EventChannel.EventSink? = null
    private var isCameraRequested = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Setup EventChannel for streaming 543 landmarks to Flutter
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

        // 2. Setup MethodChannel for camera controls (start/stop)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL_NAME)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startCamera" -> {
                        isCameraRequested = true
                        startBisindoCamera(result)
                    }
                    "stopCamera" -> {
                        isCameraRequested = false
                        stopBisindoCamera(result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startBisindoCamera(result: MethodChannel.Result) {
        try {
            if (cameraHelper == null) {
                cameraHelper = BisindoCameraHelper(
                    context = applicationContext,
                    lifecycleOwner = this,
                    onLandmarksReady = { landmarks ->
                        runOnUiThread {
                            landmarkEventSink?.success(mapOf("landmarks" to landmarks))
                        }
                    },
                    onError = { errorMessage ->
                        runOnUiThread {
                            landmarkEventSink?.error("CAMERA_ERROR", errorMessage, null)
                        }
                    }
                )
                cameraHelper?.initialize()
            }
            cameraHelper?.startCamera()
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error starting BISINDO camera: ${e.message}", e)
            result.error("START_FAILED", e.message, null)
        }
    }

    private fun stopBisindoCamera(result: MethodChannel.Result) {
        try {
            cameraHelper?.stopCamera()
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping BISINDO camera: ${e.message}", e)
            result.error("STOP_FAILED", e.message, null)
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
