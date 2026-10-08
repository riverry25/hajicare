package com.example.hajicare

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.SystemClock
import android.util.Log
import android.util.Size
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.google.mediapipe.framework.image.BitmapImageBuilder
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
        private val TARGET_ANALYSIS_SIZE = Size(640, 480)
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
            } catch (t: Throwable) {
                Log.e(TAG, "Failed to initialize HandLandmarker: ${t.message}", t)
                handLandmarker = null
                onError("MediaPipe HandLandmarker gagal dimuat: ${t.message}")
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
            } catch (t: Throwable) {
                Log.w(TAG, "PoseLandmarker not loaded (continuing with hands): ${t.message}")
                poseLandmarker = null
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
            } catch (t: Throwable) {
                Log.w(TAG, "FaceLandmarker not loaded (continuing with hands/pose): ${t.message}")
                faceLandmarker = null
            }

        } catch (t: Throwable) {
            Log.e(TAG, "Failed to initialize MediaPipe pipeline: ${t.message}", t)
            onError("MediaPipe gagal diinisialisasi: ${t.message}")
        }
    }

    fun startCamera() {
        if (isRunning) return
        isRunning = true

        try {
            val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
            cameraProviderFuture.addListener({
                try {
                    cameraProvider = cameraProviderFuture.get()
                    bindCameraUseCases()
                } catch (t: Throwable) {
                    Log.e(TAG, "Failed to start camera: ${t.message}", t)
                    onError("Kamera gagal dimulai: ${t.message}")
                }
            }, ContextCompat.getMainExecutor(context))
        } catch (t: Throwable) {
            Log.e(TAG, "Failed to get ProcessCameraProvider: ${t.message}", t)
            onError("Gagal mendapatkan camera provider: ${t.message}")
        }
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

        try {
            imageAnalysis?.clearAnalyzer()
        } catch (_: Throwable) {}

        @Suppress("DEPRECATION")
        imageAnalysis = ImageAnalysis.Builder()
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setTargetResolution(TARGET_ANALYSIS_SIZE)
            .build()

        imageAnalysis?.setAnalyzer(cameraExecutor) { imageProxy ->
            processImageProxy(imageProxy)
        }

        try {
            provider.unbindAll()
            val pv = previewView
            val analysis = imageAnalysis

            if (pv != null && pv.surfaceProvider != null) {
                try {
                    val preview = Preview.Builder().build().also {
                        it.setSurfaceProvider(pv.surfaceProvider)
                    }
                    if (analysis != null) {
                        provider.bindToLifecycle(lifecycleOwner, cameraSelector, preview, analysis)
                    } else {
                        provider.bindToLifecycle(lifecycleOwner, cameraSelector, preview)
                    }
                } catch (t: Throwable) {
                    Log.w(TAG, "Combined Preview+Analysis binding failed, falling back to Analysis only: ${t.message}")
                    if (analysis != null) {
                        provider.unbindAll()
                        provider.bindToLifecycle(lifecycleOwner, cameraSelector, analysis)
                    }
                }
            } else if (analysis != null) {
                provider.bindToLifecycle(lifecycleOwner, cameraSelector, analysis)
            }
            Log.d(TAG, "Camera use cases bound successfully")
        } catch (t: Throwable) {
            Log.e(TAG, "Use case binding failed: ${t.message}", t)
            onError("Gagal menghubungkan camera usecase: ${t.message}")
        }
    }

    private fun processImageProxy(imageProxy: ImageProxy) {
        val currentTime = SystemClock.uptimeMillis()
        if (currentTime - lastProcessedTimestamp < MIN_FRAME_INTERVAL_MS ||
            !isProcessingFrame.compareAndSet(false, true)) {
            try {
                imageProxy.close()
            } catch (_: Throwable) {}
            return
        }
        lastProcessedTimestamp = currentTime

        var originalBitmap: Bitmap? = null
        var rotatedBitmap: Bitmap? = null
        var processedBitmap: Bitmap? = null

        try {
            // If no landmarkers available, do not waste CPU/memory allocating bitmaps
            if (handLandmarker == null && poseLandmarker == null && faceLandmarker == null) {
                return
            }

            originalBitmap = imageProxy.toBitmap()
            val rotationDegrees = imageProxy.imageInfo.rotationDegrees

            if (rotationDegrees != 0) {
                val matrix = Matrix().apply {
                    postRotate(rotationDegrees.toFloat())
                }
                rotatedBitmap = Bitmap.createBitmap(
                    originalBitmap,
                    0,
                    0,
                    originalBitmap.width,
                    originalBitmap.height,
                    matrix,
                    true
                )
            } else {
                rotatedBitmap = originalBitmap
            }

            // Downscale to longest side <= 640px preserving aspect ratio
            val maxDim = Math.max(rotatedBitmap.width, rotatedBitmap.height)
            if (maxDim > MAX_PROCESSING_DIM && maxDim > 0) {
                val scale = MAX_PROCESSING_DIM.toFloat() / maxDim.toFloat()
                val targetW = Math.max(1, (rotatedBitmap.width * scale).toInt())
                val targetH = Math.max(1, (rotatedBitmap.height * scale).toInt())
                processedBitmap = Bitmap.createScaledBitmap(rotatedBitmap, targetW, targetH, true)
            } else {
                processedBitmap = rotatedBitmap
            }

            val mpImage = BitmapImageBuilder(processedBitmap).build()

            // 1. Hands detection
            var leftHand: List<List<Double>>? = null
            var rightHand: List<List<Double>>? = null

            val currentHandLandmarker = handLandmarker
            if (currentHandLandmarker != null) {
                try {
                    val handResult = currentHandLandmarker.detect(mpImage)
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
                } catch (t: Throwable) {
                    Log.w(TAG, "HandLandmarker detect error: ${t.message}", t)
                }
            }

            // 2. Pose detection
            var poseList: List<List<Double>>? = null
            val currentPoseLandmarker = poseLandmarker
            if (currentPoseLandmarker != null) {
                try {
                    val poseResult = currentPoseLandmarker.detect(mpImage)
                    if (poseResult != null && poseResult.landmarks().isNotEmpty()) {
                        val posePoints = poseResult.landmarks()[0]
                        val pList = ArrayList<List<Double>>(posePoints.size)
                        for (lm in posePoints) {
                            pList.add(listOf(lm.x().toDouble(), lm.y().toDouble(), lm.z().toDouble()))
                        }
                        poseList = pList
                    }
                } catch (t: Throwable) {
                    Log.w(TAG, "PoseLandmarker detect error: ${t.message}", t)
                }
            }

            // 3. Face Blendshapes detection
            var blendshapesMap: Map<String, Double>? = null
            val currentFaceLandmarker = faceLandmarker
            if (currentFaceLandmarker != null) {
                try {
                    val faceResult = currentFaceLandmarker.detect(mpImage)
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
                } catch (t: Throwable) {
                    Log.w(TAG, "FaceLandmarker detect error: ${t.message}", t)
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

        } catch (t: Throwable) {
            Log.e(TAG, "Error processing camera frame: ${t.message}", t)
        } finally {
            // Recycle bitmaps to avoid native GraphicBuffer OOM
            try {
                if (originalBitmap != null && originalBitmap != rotatedBitmap && !originalBitmap.isRecycled) {
                    originalBitmap.recycle()
                }
                if (rotatedBitmap != null && rotatedBitmap != processedBitmap && rotatedBitmap != originalBitmap && !rotatedBitmap.isRecycled) {
                    rotatedBitmap.recycle()
                }
                if (processedBitmap != null && processedBitmap != rotatedBitmap && processedBitmap != originalBitmap && !processedBitmap.isRecycled) {
                    processedBitmap.recycle()
                }
            } catch (_: Throwable) {}

            isProcessingFrame.set(false)
            try {
                imageProxy.close()
            } catch (_: Throwable) {}
        }
    }

    fun stopCamera() {
        if (!isRunning) return
        isRunning = false

        try {
            cameraProvider?.unbindAll()
            imageAnalysis?.clearAnalyzer()
            Log.d(TAG, "Camera stopped")
        } catch (t: Throwable) {
            Log.e(TAG, "Error stopping camera: ${t.message}", t)
        }
    }

    fun dispose() {
        stopCamera()
        try {
            handLandmarker?.close()
        } catch (_: Throwable) {}
        try {
            poseLandmarker?.close()
        } catch (_: Throwable) {}
        try {
            faceLandmarker?.close()
        } catch (_: Throwable) {}
        try {
            cameraExecutor.shutdown()
        } catch (_: Throwable) {}
        handLandmarker = null
        poseLandmarker = null
        faceLandmarker = null
    }
}
