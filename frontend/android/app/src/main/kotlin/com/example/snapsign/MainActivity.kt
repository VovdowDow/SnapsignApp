package com.example.snapsign

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.YuvImage
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.tensorflow.lite.Interpreter
import org.tensorflow.lite.support.common.FileUtil

import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarker
import com.google.mediapipe.tasks.vision.handlandmarker.HandLandmarkerResult
import com.google.mediapipe.framework.image.BitmapImageBuilder

import java.io.ByteArrayOutputStream
import kotlin.math.abs
import kotlin.math.max

class MainActivity : FlutterActivity() {

    private val METHOD = "snapsign/native"
    private val EVENTS = "snapsign/native/events"

    private var eventSink: EventChannel.EventSink? = null

    // Engines / Models
    private lateinit var landmarker: HandLandmarker
    private lateinit var tflite: Interpreter
    private lateinit var labels: List<String>

    private var lastLabel: String = ""
    // ชั่วคราวให้ต่ำหน่อยเพื่อดูผลง่าย ๆ (ขึ้นจริงแล้วค่อยปรับเป็น 0.60)
    private val minConfidence = 0.30f

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.d("Snapsign", "configureFlutterEngine called")
        initEngines()

        // EventChannel: ส่งผลกลับ Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENTS)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    eventSink = events
                    events.success("พร้อมทำงาน")
                }
                override fun onCancel(arguments: Any?) { eventSink = null }
            })

        // MethodChannel: รับเฟรมภาพจาก Flutter
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "analyze" -> {
                        val args = call.arguments as Map<*, *>
                        try {
                            analyzeFrame(args)
                            result.success(null)
                        } catch (e: Exception) {
                            Log.e("Snapsign", "analyze error", e)
                            eventSink?.success("error: ${e.message}")
                            result.error("ERR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** โหลด MediaPipe HandLandmarker + TFLite + labels */
    private fun initEngines() {
        // MediaPipe Hand Landmarker
        val base = BaseOptions.builder()
            .setModelAssetPath("models/hand_landmarker.task")
            .build()
        val options = HandLandmarker.HandLandmarkerOptions.builder()
            .setBaseOptions(base)
            .setRunningMode(RunningMode.IMAGE)
            .setNumHands(1)
            .build()
        landmarker = HandLandmarker.createFromOptions(this, options)

        // TFLite gesture classifier
        val mapped = FileUtil.loadMappedFile(this, "models/gesture_model.tflite")
        tflite = Interpreter(mapped)

        // labels.json ต้องเป็นลิสต์ ["สวัสดี","ขอบคุณ",...]
        labels = loadLabelsFromJsonAsset("models/labels.json")
        Log.d("Snapsign", "Loaded models. labels=${labels.size}")
    }

    private fun loadLabelsFromJsonAsset(assetPath: String): List<String> {
        assets.open(assetPath).use { ins ->
            val json = ins.bufferedReader(Charsets.UTF_8).readText()
            val arr = JSONArray(json)
            return List(arr.length()) { i -> arr.getString(i) }
        }
    }

    /** วิเคราะห์เฟรมที่ได้จาก Flutter */
    private fun analyzeFrame(args: Map<*, *>) {
        val width  = args["width"] as Int
        val height = args["height"] as Int
        val planes = args["planes"] as List<*>

        // 1) YUV_420_888 → NV21 (รองรับ stride/pixelStride) → Bitmap
        val nv21 = yuv420ToNv21StrideAware(planes, width, height)
        val bmp = nv21ToBitmap(nv21, width, height)

        // 2) หา landmarks ด้วย MediaPipe
        val mpImage = BitmapImageBuilder(bmp).build()
        val result: HandLandmarkerResult = landmarker.detect(mpImage)

        if (result.landmarks().isEmpty()) {
            eventSink?.success("ไม่พบมือ")
            return
        }

        // 3) ดึง 21 จุด → ทำ normalize ให้เหมือนตอนเทรน → รัน TFLite
        val lms = result.landmarks()[0]
        val feature = FloatArray(63)
        for (i in 0 until 21) {
            feature[i*3    ] = lms[i].x()
            feature[i*3 + 1] = lms[i].y()
            feature[i*3 + 2] = lms[i].z()
        }
        normalizeInPlace(feature)

        val output = Array(1) { FloatArray(labels.size) }
        tflite.run(arrayOf(feature), output)

        val probs = output[0]
        var bestIdx = 0
        var bestProb = -1f
        for (i in probs.indices) if (probs[i] > bestProb) { bestProb = probs[i]; bestIdx = i }

        if (bestProb >= minConfidence) {
            val label = labels[bestIdx]
            if (label != lastLabel) {
                lastLabel = label
                eventSink?.success("$label (${String.format("%.2f", bestProb)})")
            }
        } else {
            eventSink?.success("ไม่มั่นใจ (${String.format("%.2f", bestProb)})")
        }
    }

    /** === Utils === */

    // Normalize แบบเดียวกับตอนเทรน: ลบจุด 0 ออก แล้วหารด้วย max norm
    private fun normalizeInPlace(f: FloatArray) {
        val cx = f[0]; val cy = f[1]; val cz = f[2]
        var maxAbs = 1e-6f
        for (i in 0 until 63 step 3) {
            f[i]   -= cx
            f[i+1] -= cy
            f[i+2] -= cz
            maxAbs = max(maxAbs, abs(f[i]))
            maxAbs = max(maxAbs, abs(f[i+1]))
            maxAbs = max(maxAbs, abs(f[i+2]))
        }
        for (i in 0 until 63) f[i] /= maxAbs
    }

    /** แปลง YUV_420_888 → NV21 รองรับ rowStride/pixelStride ทุก plane */
    private fun yuv420ToNv21StrideAware(planes: List<*>, width: Int, height: Int): ByteArray {
        fun m(i: Int) = planes[i] as Map<*, *>

        val yBytes = m(0)["bytes"] as ByteArray
        val yRowStride = (m(0)["bytesPerRow"] as Int)
        val yPixStride = ((m(0)["bytesPerPixel"] as Int?) ?: 1)

        val uBytes = m(1)["bytes"] as ByteArray
        val uRowStride = (m(1)["bytesPerRow"] as Int)
        val uPixStride = ((m(1)["bytesPerPixel"] as Int?) ?: 2)

        val vBytes = m(2)["bytes"] as ByteArray
        val vRowStride = (m(2)["bytesPerRow"] as Int)
        val vPixStride = ((m(2)["bytesPerPixel"] as Int?) ?: 2)

        val ySize = width * height
        val out = ByteArray(ySize + ySize / 2)

        // copy Y ทีละแถว
        var dst = 0
        var src = 0
        for (row in 0 until height) {
            if (yPixStride == 1) {
                System.arraycopy(yBytes, src, out, dst, width)
            } else {
                var s = src
                var d = dst
                for (col in 0 until width) {
                    out[d++] = yBytes[s]
                    s += yPixStride
                }
            }
            src += yRowStride
            dst += width
        }

        // interleave VU (NV21)
        var uvDst = ySize
        for (row in 0 until height / 2) {
            var uSrc = row * uRowStride
            var vSrc = row * vRowStride
            for (col in 0 until width / 2) {
                out[uvDst++] = vBytes[vSrc]
                out[uvDst++] = uBytes[uSrc]
                uSrc += uPixStride
                vSrc += vPixStride
            }
        }
        return out
    }

    private fun nv21ToBitmap(nv21: ByteArray, width: Int, height: Int): Bitmap {
        val yuv = YuvImage(nv21, ImageFormat.NV21, width, height, null)
        val out = ByteArrayOutputStream()
        yuv.compressToJpeg(Rect(0, 0, width, height), 90, out)
        val bytes = out.toByteArray()
        return BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
    }
}