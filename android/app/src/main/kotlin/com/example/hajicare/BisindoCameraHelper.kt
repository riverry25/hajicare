package com.example.hajicare

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.SystemClock
import android.util.Log
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.poselandmarker.PoseLandmarker
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Manages CameraX live stream and MediaPipe Tasks pipeline (HandLandmarker,
 * PoseLandmarker, FaceLandmarker with blendshapes) for BISINDO MotionGRU sign language recognition.
 *
 * Emits unified frame payload to Flutter containing:
 * - left_hand: 21 points [x, y, z] or null
 * - right_hand: 21 points [x, y, z] or null
 * - pose: 33 points [x, y, z] or null
 * - face_blendshapes: Map<String, Double> of 52 blendshape scores or null
 * - landmarks: 42 points for backward compatibility
 * - timestamp: frame uptime timestamp
 *
 * Camera & Coordinate Orientation Strategy:
 * - Camera rotation is applied once via Matrix.postRotate.
 * - Image bitmaps are NOT mirrored prior to MediaPipe analysis.
 * - This guarantees anatomical parity: person's left hand is detected as "Left",
 *   person's right hand as "Right", pose[11] as Left Shoulder, pose[12] as Right Shoulder.
 * - PreviewView handles UX mirroring automatically for front camera without altering analysis coordinates.
 */
class BisindoCameraHelper(
    private val context: Context,
    private val lifecycleOwner: LifecycleOwner,
    private val onFrameReady: (Map<String, Any?>) -> Unit,
    private val onError: (String) -> Unit
) {
    companion object {
        private const val TAG = "BISINDO_CAMERA"
        private const val MIN_FRAME_INTERVAL_MS = 50L // ~20 FPS max for optimal latency and thermals
        private const val MAX_PROCESSING_DIM = 640
    }

    private var cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private var cameraProvider: ProcessCameraProvider? = null
    private var imageAnalysis: ImageAnalysis? = null

    private var handLandmarker: HandLandmarker? = null
    private var poseLandmarker: PoseLandmarker? = null
    private var faceLandmarker: FaceLandmarker? = null

    @Volatile
    private var previewView: PreviewView? = null

    private var isRunning = false
    private var lastProcessedTimestamp = 0L
    private val isProcessingFrame = AtomicBoolean(false)

    private var isFrontCamera: Boolean = true

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

    fun switchCamera(): Boolean {
        isFrontCamera = !isFrontCamera
        if (isRunning && cameraProvider != null) {
            bindCameraUseCases()
        }
        return isFrontCamera
    }

    fun setLensFacing(front: Boolean) {
        if (isFrontCamera != front) {
            isFrontCamera = front
            if (isRunning && cameraProvider != null) {
                bindCameraUseCases()
            }
        }
    }

    fun isFrontCamera(): Boolean = isFrontCamera

    fun initialize() {
        try {
            // 1. Hand Landmarker (up to 2 hands)
            try {
                val handBaseOptions = BaseOptions.builder()
                    .setModelAssetPath("hand_landmarker.task")
                    .build()

                val handOptions = HandLandmarker.HandLandmarkerOptions.builder()
                    .setBaseOptions(handBaseOptions)
                    .setRunningMode(RunningMode.IMAGE)
                    .setNumHands(2)
                    .setMinHandDetectionConfidence(0.45f)
                    .setMinHandPresenceConfidence(0.45f)
                    .setMinTrackingConfidence(0.45f)
                    .build()

                handLandmarker = HandLandmarker.createFromOptions(context, handOptions)
                Log.d(TAG, "MediaPipe HandLandmarker initialized successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to initialize HandLandmarker: ${e.message}", e)
            }

            // 2. Pose Landmarker
            try {
                val poseBaseOptions = BaseOptions.builder()
                    .setModelAssetPath("pose_landmarker.task")
                    .build()

                val poseOptions = PoseLandmarker.PoseLandmarkerOptions.builder()
                    .setBaseOptions(poseBaseOptions)
                    .setRunningMode(RunningMode.IMAGE)
                    .setMinPoseDetectionConfidence(0.45f)
                    .setMinPosePresenceConfidence(0.45f)
                    .setMinTrackingConfidence(0.45f)
                    .build()

                poseLandmarker = PoseLandmarker.createFromOptions(context, poseOptions)
                Log.d(TAG, "MediaPipe PoseLandmarker initialized successfully")
            } catch (e: Exception) {
                Log.w(TAG, "PoseLandmarker not loaded (continuing with hands): ${e.message}")
            }

            // 3. Face Landmarker with Blendshapes enabled
            try {
                val faceBaseOptions = BaseOptions.builder()
                    .setModelAssetPath("face_landmarker.task")
                    .build()

                val faceOptions = FaceLandmarker.FaceLandmarkerOptions.builder()
                    .setBaseOptions(faceBaseOptions)
                    .setRunningMode(RunningMode.IMAGE)
                    .setOutputFaceBlendshapes(true)
                    .setMinFaceDetectionConfidence(0.45f)
                    .setMinFacePresenceConfidence(0.45f)
                    .setMinTrackingConfidence(0.45f)
                    .build()

                faceLandmarker = FaceLandmarker.createFromOptions(context, faceOptions)
                Log.d(TAG, "MediaPipe FaceLandmarker with blendshapes initialized successfully")
            } catch (e: Exception) {
                Log.w(TAG, "FaceLandmarker not loaded (continuing with hands/pose): ${e.message}")
            }

        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize MediaPipe pipeline: ${e.message}", e)
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

        val hasFrontCamera = provider.hasCamera(CameraSelector.DEFAULT_FRONT_CAMERA)
        val hasBackCamera = provider.hasCamera(CameraSelector.DEFAULT_BACK_CAMERA)
        val cameraSelector = if (isFrontCamera && hasFrontCamera) {
            CameraSelector.DEFAULT_FRONT_CAMERA
        } else if (!isFrontCamera && hasBackCamera) {
            CameraSelector.DEFAULT_BACK_CAMERA
        } else if (hasFrontCamera) {
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
            Log.d(TAG, "Camera started successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Use case binding failed: ${e.message}", e)
            onError("Gagal menghubungkan camera usecase: ${e.message}")
        }
    }

    private fun processImageProxy(imageProxy: ImageProxy) {
        val currentTime = SystemClock.uptimeMillis()
        if (currentTime - lastProcessedTimestamp < MIN_FRAME_INTERVAL_MS ||
            !isProcessingFrame.compareAndSet(false, true)) {
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

            // Downscale to longest side <= 640px preserving aspect ratio for mobile inference performance
            val maxDim = Math.max(rotatedBitmap.width, rotatedBitmap.height)
            val processedBitmap = if (maxDim > MAX_PROCESSING_DIM) {
                val scale = MAX_PROCESSING_DIM.toFloat() / maxDim.toFloat()
                val targetW = (rotatedBitmap.width * scale).toInt()
                val targetH = (rotatedBitmap.height * scale).toInt()
                Bitmap.createScaledBitmap(rotatedBitmap, targetW, targetH, true)
            } else {
                rotatedBitmap
            }

            val mpImage = BitmapImageBuilder(processedBitmap).build()

            // 1. Hands detection
            var leftHand: List<List<Double>>? = null
            var rightHand: List<List<Double>>? = null

            val handResult = handLandmarker?.detect(mpImage)
            if (handResult != null) {
                val landmarks = handResult.landmarks()
                val handednesses = handResult.handednesses()
                for (i in landmarks.indices) {
                    val handPoints = landmarks[i]
                    val handList = ArrayList<List<Double>>(21)
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
            }

            // 2. Pose detection
            var poseList: List<List<Double>>? = null
            val poseResult = poseLandmarker?.detect(mpImage)
            if (poseResult != null && poseResult.landmarks().isNotEmpty()) {
                val posePoints = poseResult.landmarks()[0]
                val pList = ArrayList<List<Double>>(posePoints.size)
                for (lm in posePoints) {
                    pList.add(listOf(lm.x().toDouble(), lm.y().toDouble(), lm.z().toDouble()))
                }
                poseList = pList
            }

            // 3. Face Blendshapes detection
            var blendshapesMap: Map<String, Double>? = null
            val faceResult = faceLandmarker?.detect(mpImage)
            if (faceResult != null) {
                val blendshapesOpt = faceResult.faceBlendshapes()
                val blendshapesList = if (blendshapesOpt.isPresent) blendshapesOpt.get() else null
                if (blendshapesList != null && blendshapesList.isNotEmpty()) {
                    val bMap = HashMap<String, Double>(52)
                    val categories = blendshapesList[0]
                    for (cat in categories) {
                        bMap[cat.categoryName()] = cat.score().toDouble()
                    }
                    blendshapesMap = bMap
                }
            }

            // 4. Assemble payload
            val payload = HashMap<String, Any?>()
            payload["left_hand"] = leftHand
            payload["right_hand"] = rightHand
            payload["pose"] = poseList
            payload["face_blendshapes"] = blendshapesMap
            payload["timestamp"] = currentTime

            // Backward compatibility 42-point landmarks
            val zeroPoint = listOf(0.0, 0.0, 0.0)
            val legacyLandmarks = ArrayList<List<Double>>(42)
            for (i in 0 until 21) {
                legacyLandmarks.add(leftHand?.getOrNull(i) ?: zeroPoint)
            }
            for (i in 0 until 21) {
                legacyLandmarks.add(rightHand?.getOrNull(i) ?: zeroPoint)
            }
            payload["landmarks"] = legacyLandmarks

            onFrameReady(payload)

        } catch (e: Exception) {
            Log.e(TAG, "Error processing camera frame: ${e.message}", e)
        } finally {
            isProcessingFrame.set(false)
            imageProxy.close()
        }
    }

    fun stopCamera() {
        if (!isRunning) return
        isRunning = false

        try {
            cameraProvider?.unbindAll()
            imageAnalysis?.clearAnalyzer()
            Log.d(TAG, "Camera stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping camera: ${e.message}", e)
        }
    }

    fun dispose() {
        stopCamera()
        try {
            handLandmarker?.close()
            poseLandmarker?.close()
            faceLandmarker?.close()
            cameraExecutor.shutdown()
        } catch (e: Exception) {
            Log.e(TAG, "Error disposing camera helper: ${e.message}", e)
        }
    }
}
