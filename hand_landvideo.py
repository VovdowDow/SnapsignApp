import cv2
import mediapipe as mp
import json
import os

# === ตั้งค่า ===
video_folder = 'videos/'  # โฟลเดอร์ที่มีวิดีโอ
output_json = 'hand_landmarks_from_videos.json'

# เรียกใช้งาน MediaPipe Hands
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(static_image_mode=False,
                       max_num_hands=1,
                       min_detection_confidence=0.5,
                       min_tracking_confidence=0.5)

# เตรียมเก็บข้อมูลทั้งหมด
all_hand_data = {}

# วนลูปไฟล์วิดีโอทุกไฟล์ในโฟลเดอร์
for filename in os.listdir(video_folder):
    if filename.lower().endswith(('.mp4', '.avi', '.mov')):
        video_path = os.path.join(video_folder, filename)
        cap = cv2.VideoCapture(video_path)
        label = os.path.splitext(filename)[0]  # ใช้ชื่อไฟล์เป็น label

        frame_index = 0
        while cap.isOpened():
            ret, frame = cap.read()
            if not ret:
                break

            image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = hands.process(image_rgb)

            if results.multi_hand_landmarks:
                for hand_idx, hand_landmarks in enumerate(results.multi_hand_landmarks):
                    landmarks = []
                    for id, lm in enumerate(hand_landmarks.landmark):
                        landmarks.append({
                            'id': id,
                            'x': lm.x,
                            'y': lm.y,
                            'z': lm.z
                        })

                    key = f"{filename}_frame_{frame_index}_hand_{hand_idx}"
                    all_hand_data[key] = {
                        "label": label,
                        "landmarks": landmarks
                    }

            frame_index += 1

        cap.release()

# เซฟข้อมูลทั้งหมดลง JSON
with open(output_json, 'w', encoding='utf-8') as f:
    json.dump(all_hand_data, f, indent=4, ensure_ascii=False)

print(f"บันทึกข้อมูลเสร็จแล้ว: {output_json}")

# ปิดใช้งาน MediaPipe Hands
hands.close()
