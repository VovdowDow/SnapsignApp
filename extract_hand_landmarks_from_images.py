import os
import cv2
import json
import hand_tracking as mp

# กำหนด path ของโฟลเดอร์ dataset
dataset_path = "dataset/"  # <-- แก้เป็น path ที่เก็บภาพ
output_json = "hand_landmarks_output.json"

mp_hands = mp.solutions.hands
hands = mp_hands.Hands(static_image_mode=True, max_num_hands=1, min_detection_confidence=0.5)
mp_drawing = mp.solutions.drawing_utils

data = {}

for label in os.listdir(dataset_path):
    label_folder = os.path.join(dataset_path, label)
    if not os.path.isdir(label_folder):
        continue

    for idx, image_file in enumerate(os.listdir(label_folder)):
        if not image_file.lower().endswith((".png", ".jpg", ".jpeg")):
            continue

        image_path = os.path.join(label_folder, image_file)
        image = cv2.imread(image_path)
        if image is None:
            print(f"ไม่สามารถโหลดภาพ: {image_path}")
            continue

        image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        results = hands.process(image_rgb)

        if results.multi_hand_landmarks:
            for hand_index, hand_landmarks in enumerate(results.multi_hand_landmarks):
                landmark_list = []
                for i, landmark in enumerate(hand_landmarks.landmark):
                    landmark_list.append({
                        "id": i,
                        "x": landmark.x,
                        "y": landmark.y,
                        "z": landmark.z
                    })

                key = f"{label}_frame_{idx}_hand_{hand_index}"
                data[key] = {
                    "label": label,
                    "landmarks": landmark_list
                }

# บันทึกไฟล์ JSON
with open(output_json, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=4)

print(f"บันทึกข้อมูลเสร็จสิ้น: {output_json}")
