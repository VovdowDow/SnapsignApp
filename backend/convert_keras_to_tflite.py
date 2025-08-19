# backend/convert_keras_to_tflite.py
import tensorflow as tf
from pathlib import Path

# หาตำแหน่ง root ของโปรเจกต์ จากไฟล์นี้
ROOT = Path(__file__).resolve().parents[1]  # .../SnapsignApp
MODEL_PATH = ROOT / "backend" / "hand_gesture_model.keras"
OUT_DIR    = ROOT / "frontend" / "assets" / "models"
OUT_DIR.mkdir(parents=True, exist_ok=True)
OUT_PATH   = OUT_DIR / "gesture_model.tflite"

assert MODEL_PATH.exists(), f"ไม่พบไฟล์โมเดล: {MODEL_PATH}"

print(f"Loading model: {MODEL_PATH}")
model = tf.keras.models.load_model(MODEL_PATH)  # ถ้าใช้ Keras3 จะโหลด .keras ได้

converter = tf.lite.TFLiteConverter.from_keras_model(model)
# (ทางเลือก) บีบขนาด:
# converter.optimizations = [tf.lite.Optimize.DEFAULT]
# converter.target_spec.supported_types = [tf.float16]

print("Converting to TFLite...")
tflite_model = converter.convert()
OUT_PATH.write_bytes(tflite_model)
print(f"✅ Saved: {OUT_PATH}")
