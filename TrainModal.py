import json
import numpy as np
import tensorflow as tf
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
import os

# ========== STEP 1: LOAD JSON ==========
with open('multilevel_labeled_landmarks.json', encoding='utf-8') as f:
    data = json.load(f)

X, y = [], []

for sample in data:
    label = sample["label"]
    hands = sample.get("hands", [])
    pose = sample.get("pose", [])

    # ========== STEP 2: FLATTEN LANDMARKS ==========

    if len(hands) == 2:
        lh = [c for point in hands[0] for c in point]  # Left hand
        rh = [c for point in hands[1] for c in point]  # Right hand
    else:
        lh = rh = [0.0] * 63  # fallback

    pose_flat = [c for point in pose for c in point]  # 33 pose points
    features = lh + rh + pose_flat  # total ~63+63+99 = 225 values

    X.append(features)
    y.append(label)

X = np.array(X, dtype=np.float32)

# ========== STEP 3: LABEL ENCODING ==========
encoder = LabelEncoder()
y_encoded = encoder.fit_transform(y)
y_encoded = tf.keras.utils.to_categorical(y_encoded)

# ========== STEP 4: TRAIN / TEST SPLIT ==========
X_train, X_test, y_train, y_test = train_test_split(
    X, y_encoded, test_size=0.2, random_state=42)

# ========== STEP 5: BUILD MODEL ==========
model = tf.keras.Sequential([
    tf.keras.layers.Input(shape=(X.shape[1],)),
    tf.keras.layers.Dense(128, activation='relu'),
    tf.keras.layers.Dropout(0.3),
    tf.keras.layers.Dense(64, activation='relu'),
    tf.keras.layers.Dense(len(y_encoded[0]), activation='softmax')
])

model.compile(optimizer='adam',
              loss='categorical_crossentropy',
              metrics=['accuracy'])

# ========== STEP 6: TRAIN ==========
model.fit(X_train, y_train, epochs=50, batch_size=16,
          validation_data=(X_test, y_test))

# ========== STEP 7: EXPORT TFLITE ==========
model.save("gesture_model.keras")

converter = tf.lite.TFLiteConverter.from_keras_model(model)
tflite_model = converter.convert()

with open("gesture_model.tflite", "wb") as f:
    f.write(tflite_model)

# ========== STEP 8: SAVE LABEL MAP ==========
with open("labels.txt", "w", encoding='utf-8') as f:
    for label in encoder.classes_:
        f.write(label + "\n")

print("✅ สำเร็จ: บันทึก gesture_model.tflite และ labels.txt แล้ว")
