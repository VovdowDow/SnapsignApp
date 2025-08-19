import json, os
import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, callbacks, models
from sklearn.model_selection import train_test_split

JSON_PATH = "hands_landmarks_clean.json"
MODEL_PATH = "hand_gesture_model.keras"  
LABELS_PATH = "labels.json"

def load_dataset(json_path):
    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    X, y, label2id = [], [], {}
    next_id = 0

    for item in data:
        label = item["label"]
        if label not in label2id:
            label2id[label] = next_id
            next_id += 1

        # ในไฟล์ตัวอย่าง item["hands"] เป็น list ของหลายตัวอย่าง (ต่อ gesture)
        for hand in item.get("hands", []):
            if len(hand) != 21:
                continue
            lm = np.array(hand, dtype=np.float32)  # (21,3)

            # --- Normalize ให้สเกล/ตำแหน่งนิ่งขึ้น ---
            # ย้ายฐานที่ข้อมือ (landmark 0)
            lm -= lm[0]
            # สเกลให้ขนาดใกล้เคียงกัน (หารด้วยระยะไกลสุดจาก origin)
            scale = np.linalg.norm(lm, axis=1).max() + 1e-6
            lm /= scale

            X.append(lm.flatten())   # (63,)
            y.append(label2id[label])

    X = np.array(X, dtype=np.float32)
    y = np.array(y, dtype=np.int64)
    return X, y, label2id

def build_mlp(n_classes: int):
    model = tf.keras.Sequential([
        layers.Input(shape=(63,)),
        layers.Dense(128, activation="relu"),
        layers.Dropout(0.2),
        layers.Dense(64, activation="relu"),
        layers.Dropout(0.2),
        layers.Dense(n_classes, activation="softmax"),
    ])
    model.compile(optimizer="adam",
                  loss="sparse_categorical_crossentropy",
                  metrics=["accuracy"])
    return model

def main():
    assert os.path.exists(JSON_PATH), f"ไม่พบไฟล์ {JSON_PATH}"
    X, y, label2id = load_dataset(JSON_PATH)
    n_classes = len(label2id)
    print(f"[INFO] samples={len(X)}, classes={n_classes}, labels={list(label2id.keys())}")

    X_tr, X_val, y_tr, y_val = train_test_split(X, y, test_size=0.15, random_state=42, stratify=y)

    model = build_mlp(n_classes)
    es = callbacks.EarlyStopping(patience=10, restore_best_weights=True, monitor="val_accuracy")
    model.fit(X_tr, y_tr,
              validation_data=(X_val, y_val),
              epochs=200,
              batch_size=32,
              callbacks=[es],
              verbose=1)

    model.save(MODEL_PATH)
    print(f"[INFO] Saved model → {MODEL_PATH}")

    # เซฟ mapping id→label สำหรับใช้ตอนทำนาย
    id2label = {int(v): k for k, v in label2id.items()}
    with open(LABELS_PATH, "w", encoding="utf-8") as f:
        json.dump(id2label, f, ensure_ascii=False, indent=2)
    print(f"[INFO] Saved labels → {LABELS_PATH}")

if __name__ == "__main__":
    main()
