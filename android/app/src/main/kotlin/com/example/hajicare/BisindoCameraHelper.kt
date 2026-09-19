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
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarkerResult
import androidx.camera.view.PreviewView
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Manages CameraX live video stream and Google MediaPipe Vision Tasks (Pose & Hands)
 * to output strict 543-landmark vectors [543, 3] for BISINDO sign language inference.
 *
 * Landmark Index Structure (OpenHands Compatible):
 * 0..32     : Pose Landmarks (33 points)
 * 33..500   : Face Mesh (468 points, zero-filled as unused in minimal_27)
 * 501..521  : Left Hand (21 points)
 * 522..542  : Right Hand (21 points)
 */
class BisindoCameraHelper(
    private val context: Context,
    private val lifecycleOwner: LifecycleOwner,
    private val onLandmarksReady: (List<List<Double>>) -> Unit,
    private val onError: (String) -> Unit
) {
    companion object {
        private const val TAG = "BISINDO_CAMERA"
        private const val MIN_FRAME_INTERVAL_MS = 50L // Cap at ~20 FPS to prevent channel saturation
    }

    private var cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private var cameraProvider: ProcessCameraProvider? = null
    private var imageAnalysis: ImageAnalysis? = null
    private var poseLandmarker: PoseLandmarker? = null
    private var handLandmarker: HandLandmarker? = null

    @Volatile
    private var previewView: PreviewView? = null

    private var isRunning = false
    private var lastProcessedTimestamp = 0L

    // Frame synchronization cache
    @Volatile
    private var latestPoseLandmarks: List<List<Double>>? = null
    @Volatile
    private var latestLeftHandLandmarks: List<List<Double>>? = null
    @Volatile
    private var latestRightHandLandmarks: List<List<Double>>? = null

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
            // 1. Initialize Pose Landmarker
            val poseBaseOptions = BaseOptions.builder()
                .setModelAssetPath("pose_landmarker_lite.task")
                .build()

            val poseOptions = PoseLandmarker.PoseLandmarkerOptions.builder()
                .setBaseOptions(poseBaseOptions)
                .setRunningMode(RunningMode.LIVE_STREAM)
                .setResultListener { result: PoseLandmarkerResult, _: MPImage ->
                    onPoseResult(result)
                }
                .setErrorListener { error ->
                    Log.e(TAG, "PoseLandmarker error: ${error.message}")
                }
                .build()

            poseLandmarker = PoseLandmarker.createFromOptions(context, poseOptions)

            // 2. Initialize Hand Landmarker (tracks up to 2 hands)
            val handBaseOptions = BaseOptions.builder()
                .setModelAssetPath("hand_landmarker.task")
                .build()

            val handOptions = HandLandmarker.HandLandmarkerOptions.builder()
                .setBaseOptions(handBaseOptions)
                .setRunningMode(RunningMode.LIVE_STREAM)
                .setNumHands(2)
                .setResultListener { result: HandLandmarkerResult, _: MPImage ->
                    onHandResult(result)
                }
                .setErrorListener { error ->
                    Log.e(TAG, "HandLandmarker error: ${error.message}")
                }
                .build()

            handLandmarker = HandLandmarker.createFromOptions(context, handOptions)
            Log.d(TAG, "MediaPipe Tasks Vision initialized successfully")
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
        var cameraSelector = CameraSelector.DEFAULT_FRONT_CAMERA
        if (!provider.hasCamera(cameraSelector)) {
            cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA
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

            val rotatedBitmap = if (rotationDegrees != 0) {
                val matrix = Matrix()
                matrix.postRotate(rotationDegrees.toFloat())
                Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
            } else {
                bitmap
            }

            val mpImage = BitmapImageBuilder(rotatedBitmap).build()

            // Run asynchronous live stream inference
            poseLandmarker?.detectAsync(mpImage, currentTime)
            handLandmarker?.detectAsync(mpImage, currentTime)
        } catch (e: Exception) {
            Log.e(TAG, "Error processing camera frame: ${e.message}", e)
        } finally {
            imageProxy.close()
        }
    }

    private fun onPoseResult(result: PoseLandmarkerResult) {
        val landmarks = result.landmarks()
        if (landmarks.isNotEmpty()) {
            val poseList = mutableListOf<List<Double>>()
            val firstPose = landmarks[0]
            for (lm in firstPose) {
                poseList.add(listOf(lm.x().toDouble(), lm.y().toDouble(), lm.z().toDouble()))
            }
            latestPoseLandmarks = poseList
        } else {
            latestPoseLandmarks = null
        }

        assembleAndEmitLandmarks()
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

            // MediaPipe mirrors handedness for front camera
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

        latestLeftHandLandmarks = leftHand
        latestRightHandLandmarks = rightHand

        assembleAndEmitLandmarks()
    }

    /**
     * Assembles exactly 543 landmarks in the strictly required sequence:
     * - 0..32    : Pose 33
     * - 33..500  : Face 468 (zero-filled placeholder)
     * - 501..521 : Left Hand 21
     * - 522..542 : Right Hand 21
     */
    @Synchronized
    private fun assembleAndEmitLandmarks() {
        val pose = latestPoseLandmarks
        val left = latestLeftHandLandmarks
        val right = latestRightHandLandmarks

        // Only emit if at least pose OR a hand is detected
        if (pose == null && left == null && right == null) {
            return
        }

        val zeroPoint = listOf(0.0, 0.0, 0.0)
        val totalLandmarks = ArrayList<List<Double>>(543)

        // 1. Pose 33 points (0..32)
        val poseCount = if (pose != null) pose.size else 0
        for (i in 0 until 33) {
            if (pose != null && i < pose.size) {
                totalLandmarks.add(pose[i])
            } else {
                totalLandmarks.add(zeroPoint)
            }
        }

        // 2. Face 468 points (33..500) -> zero-filled placeholder
        for (i in 33..500) {
            totalLandmarks.add(zeroPoint)
        }

        // 3. Left Hand 21 points (501..521)
        val leftHandCount = if (left != null) left.size else 0
        for (i in 0 until 21) {
            if (left != null && i < left.size) {
                totalLandmarks.add(left[i])
            } else {
                totalLandmarks.add(zeroPoint)
            }
        }

        // 4. Right Hand 21 points (522..542)
        val rightHandCount = if (right != null) right.size else 0
        for (i in 0 until 21) {
            if (right != null && i < right.size) {
                totalLandmarks.add(right[i])
            } else {
                totalLandmarks.add(zeroPoint)
            }
        }

        if (totalLandmarks.size == 543) {
            Log.d(TAG, "pose=$poseCount")
            Log.d(TAG, "leftHand=$leftHandCount")
            Log.d(TAG, "rightHand=$rightHandCount")
            Log.d(TAG, "landmarks=543")
            onLandmarksReady(totalLandmarks)
        }
    }

    fun stopCamera() {
        if (!isRunning) return
        isRunning = false

        try {
            cameraProvider?.unbindAll()
            imageAnalysis?.clearAnalyzer()
            Log.d(TAG, "camera stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping camera: ${e.message}", e)
        }
    }

    fun dispose() {
        stopCamera()
        try {
            poseLandmarker?.close()
            handLandmarker?.close()
            cameraExecutor.shutdown()
        } catch (e: Exception) {
            Log.e(TAG, "Error disposing camera helper: ${e.message}", e)
        }
    }
}
