package com.example.hajicare

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.SystemClock
import android.util.Log
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import androidx.camera.view.PreviewView
import java.util.LinkedHashMap
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Manages CameraX live video stream and Google MediaPipe HandLandmarker only
 * to output 135-d feature vectors [2, 21, 3] for BISINDO sign language inference.
 *
 * Optimized version: PoseLandmarker removed (not used in BISINDO 135-d pipeline).
 * Frame rate capped at ~15 FPS. HandLandmarker only processes actual hand frames.
 *
 * Landmark Index Structure (minimal_hands_only):
 *   Left Hand  : 21 points  (index 0..20)
 *   Right Hand : 21 points  (index 21..41)
 *   Total      : 42 points → preprocessed to 135 floats in Dart preprocessor
 */
class BisindoCameraHelper(
    private val context: Context,
    private val lifecycleOwner: LifecycleOwner,
    private val onLandmarksReady: (List<List<Double>>) -> Unit,
    private val onError: (String) -> Unit
) {
    companion object {
        private const val TAG = "BISINDO_CAMERA"
        private const val MIN_FRAME_INTERVAL_MS = 66L // ~15 FPS max
        private const val MAX_PENDING_FRAMES = 8
    }

    private data class HandFrame(
        val left: List<List<Double>>?,
        val right: List<List<Double>>?
    )

    private var cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private var cameraProvider: ProcessCameraProvider? = null
    private var imageAnalysis: ImageAnalysis? = null
    private var handLandmarker: HandLandmarker? = null

    @Volatile
    private var previewView: PreviewView? = null

    private var isRunning = false
    private var lastProcessedTimestamp = 0L

    // Pending hand frames by source-frame timestamp
    private val pendingHandFrames = LinkedHashMap<Long, HandFrame>()
    private var lastEmittedTimestamp = -1L

    fun attachPreviewView(view: PreviewView) {
        previewView = view
        if (isRunning && cameraProvider != null) {
            bindCameraUseCases()
        }
    }

    fun detachPreviewView() {
        previewView = null
        if (isRunning && cameraProvider != null) {
            bindCameraUseCases()
        }
    }

    fun initialize() {
        try {
            // Initialize Hand Landmarker only (tracks up to 2 hands)
            val handBaseOptions = BaseOptions.builder()
                .setModelAssetPath("hand_landmarker.task")
                .build()

            val handOptions = HandLandmarker.HandLandmarkerOptions.builder()
                .setBaseOptions(handBaseOptions)
                .setRunningMode(RunningMode.LIVE_STREAM)
                .setNumHands(2)
                .setMinHandDetectionConfidence(0.50f)
                .setMinHandPresenceConfidence(0.50f)
                .setMinTrackingConfidence(0.50f)
                .setResultListener { result: HandLandmarkerResult, _: MPImage ->
                    onHandResult(result)
                }
                .setErrorListener { error ->
                    Log.e(TAG, "HandLandmarker error: ${error.message}")
                }
                .build()

            handLandmarker = HandLandmarker.createFromOptions(context, handOptions)
            Log.d(TAG, "MediaPipe HandLandmarker initialized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize MediaPipe: ${e.message}", e)
            onError("MediaPipe gagal diinisialisasi: ${e.message}")
        }
    }

    fun startCamera() {
        if (isRunning) return
        isRunning = true

        val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
        cameraProviderFuture.addListener({
            try {
                cameraProvider = cameraProviderFuture.get()
                bindCameraUseCases()
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start camera: ${e.message}", e)
                onError("Kamera gagal dimulai: ${e.message}")
            }
        }, ContextCompat.getMainExecutor(context))
    }

    private fun bindCameraUseCases() {
        val provider = cameraProvider ?: return

        // Default to front camera for selfie-style sign language capture
        val hasFrontCamera = provider.hasCamera(CameraSelector.DEFAULT_FRONT_CAMERA)
        val cameraSelector = if (hasFrontCamera) {
            CameraSelector.DEFAULT_FRONT_CAMERA
        } else {
            CameraSelector.DEFAULT_BACK_CAMERA
        }

        imageAnalysis = ImageAnalysis.Builder()
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
            .build()

        imageAnalysis?.setAnalyzer(cameraExecutor) { imageProxy ->
            processImageProxy(imageProxy)
        }

        try {
            provider.unbindAll()
            val pv = previewView
            if (pv != null) {
                val preview = Preview.Builder().build().also {
                    it.setSurfaceProvider(pv.surfaceProvider)
                }
                provider.bindToLifecycle(lifecycleOwner, cameraSelector, preview, imageAnalysis)
            } else {
                provider.bindToLifecycle(lifecycleOwner, cameraSelector, imageAnalysis)
            }
            Log.d(TAG, "started")
        } catch (e: Exception) {
            Log.e(TAG, "Use case binding failed: ${e.message}", e)
            onError("Gagal menghubungkan camera usecase: ${e.message}")
        }
    }

    private fun processImageProxy(imageProxy: ImageProxy) {
        val currentTime = SystemClock.uptimeMillis()
        if (currentTime - lastProcessedTimestamp < MIN_FRAME_INTERVAL_MS) {
            imageProxy.close()
            return
        }
        lastProcessedTimestamp = currentTime

        try {
            val bitmap = imageProxy.toBitmap()
            val rotationDegrees = imageProxy.imageInfo.rotationDegrees

            val matrix = Matrix().apply {
                postRotate(rotationDegrees.toFloat())
            }
            val rotatedBitmap = Bitmap.createBitmap(
                bitmap,
                0,
                0,
                bitmap.width,
                bitmap.height,
                matrix,
                true
            )

            val mpImage = BitmapImageBuilder(rotatedBitmap).build()

            // Run asynchronous live stream inference (hands only)
            handLandmarker?.detectAsync(mpImage, currentTime)
        } catch (e: Exception) {
            Log.e(TAG, "Error processing camera frame: ${e.message}", e)
        } finally {
            imageProxy.close()
        }
    }

    private fun onHandResult(result: HandLandmarkerResult) {
        val landmarks = result.landmarks()
        val handednesses = result.handednesses()

        var leftHand: List<List<Double>>? = null
        var rightHand: List<List<Double>>? = null

        for (i in landmarks.indices) {
            val handPoints = landmarks[i]
            val handList = mutableListOf<List<Double>>()
            for (lm in handPoints) {
                handList.add(listOf(lm.x().toDouble(), lm.y().toDouble(), lm.z().toDouble()))
            }

            val label = if (i < handednesses.size && handednesses[i].isNotEmpty()) {
                handednesses[i][0].categoryName()
            } else {
                if (i == 0) "Left" else "Right"
            }

            if (label.equals("Left", ignoreCase = true)) {
                leftHand = handList
            } else {
                rightHand = handList
            }
        }

        storeHandResult(result.timestampMs(), leftHand, rightHand)
    }

    @Synchronized
    private fun storeHandResult(
        timestamp: Long,
        left: List<List<Double>>?,
        right: List<List<Double>>?
    ) {
        pendingHandFrames[timestamp] = HandFrame(left, right)
        emitHandFrame(timestamp)
        trimPendingFrames()
    }

    /** Emits landmark packet for a camera frame if at least one hand is visible. */
    private fun emitHandFrame(timestamp: Long) {
        if (timestamp <= lastEmittedTimestamp) return

        val handFrame = pendingHandFrames.remove(timestamp) ?: return

        val left = handFrame.left
        val right = handFrame.right

        // Require at least one hand to be visible for sign language recognition.
        if (left == null && right == null) return

        lastEmittedTimestamp = timestamp
        assembleAndEmitLandmarks(left, right)
    }

    private fun trimPendingFrames() {
        while (pendingHandFrames.size > MAX_PENDING_FRAMES) {
            pendingHandFrames.remove(pendingHandFrames.keys.first())
        }
    }

    /**
     * Assembles 42 hand landmarks [42, 3] in the required sequence:
     *   Left Hand  : 21 points (0..20)
     *   Right Hand : 21 points (21..41)
     *
     * The Dart BisindoPreprocessor then extracts the 135-d feature vector
     * from these 42 points. No pose or face landmarks needed.
     */
    private fun assembleAndEmitLandmarks(
        left: List<List<Double>>?,
        right: List<List<Double>>?
    ) {
        val zeroPoint = listOf(0.0, 0.0, 0.0)
        val totalLandmarks = ArrayList<List<Double>>(42)

        // 1. Left Hand 21 points (0..20)
        for (i in 0 until 21) {
            totalLandmarks.add(left?.getOrNull(i) ?: zeroPoint)
        }

        // 2. Right Hand 21 points (21..41)
        for (i in 0 until 21) {
            totalLandmarks.add(right?.getOrNull(i) ?: zeroPoint)
        }

        onLandmarksReady(totalLandmarks)
    }

    fun stopCamera() {
        if (!isRunning) return
        isRunning = false

        try {
            cameraProvider?.unbindAll()
            imageAnalysis?.clearAnalyzer()
            clearPendingFrames()
            Log.d(TAG, "camera stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping camera: ${e.message}", e)
        }
    }

    @Synchronized
    private fun clearPendingFrames() {
        pendingHandFrames.clear()
        lastEmittedTimestamp = -1L
    }

    fun dispose() {
        stopCamera()
        try {
            handLandmarker?.close()
            cameraExecutor.shutdown()
        } catch (e: Exception) {
            Log.e(TAG, "Error disposing camera helper: ${e.message}", e)
        }
    }
}
