package com.example.hajicare

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Log
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
                        private val previewView = androidx.camera.view.PreviewView(context).also { pv ->
                            activePreviewView = pv
                            cameraHelper?.attachPreviewView(pv)
                        }

                        override fun getView(): View = previewView

                        override fun dispose() {
                            if (activePreviewView == previewView) {
                                cameraHelper?.detachPreviewView()
                                activePreviewView = null
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
            activePreviewView?.let { cameraHelper?.attachPreviewView(it) }
        }
        return cameraHelper!!
    }

    private fun startBisindoCamera(result: MethodChannel.Result) {
        try {
            val helper = getOrCreateCameraHelper()
            helper.startCamera()
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
