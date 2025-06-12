import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import com.google.mediapipe.tasks.vision.core.BaseOptions
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.framework.image.MPImage
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import com.google.mediapipe.tasks.vision.core.RunningMode

class MainActivity : FlutterActivity() {
    private val CHANNEL = "mediapipe_channel"
    private lateinit var handLandmarker: HandLandmarker

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "getLandmarks") {
                val imageBytes = call.arguments as ByteArray
                val bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)

                val landmarks = processImageAndGetLandmarks(bitmap)
                result.success(landmarks)
            } else {
                result.notImplemented()
            }
        }

        val baseOptions = BaseOptions.builder()
            .setModelAssetPath("hand_landmarker.task")
            .build()

        val options = HandLandmarker.HandLandmarkerOptions.builder()
            .setBaseOptions(baseOptions)
            .setRunningMode(RunningMode.IMAGE)
            .build()

        handLandmarker = HandLandmarker.createFromOptions(this, options)
    }

    private fun processImageAndGetLandmarks(bitmap: Bitmap): List<List<Float>> {
        val mpImage: MPImage = BitmapImageBuilder(bitmap).build()
        val result: HandLandmarkerResult = handLandmarker.detect(mpImage)

        val landmarks = mutableListOf<List<Float>>()
        for (hand in result.landmarks()) {
            val handLandmarks = hand.map { listOf(it.x(), it.y(), it.z()) }
            landmarks.addAll(handLandmarks)
        }

        return landmarks
    }
}
