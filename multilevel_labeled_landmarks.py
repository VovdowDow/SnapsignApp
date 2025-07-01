import cv2
import mediapipe as mp
import json
import os
from tqdm import tqdm

# ---------- CONFIG ----------
DATASET_DIR = 'dataset'  # โฟลเดอร์หลัก
OUTPUT_JSON = 'multilevel_labeled_landmarks.json'

# ---------- Init MediaPipe ----------
mp_hands = mp.solutions.hands
mp_pose = mp.solutions.pose

hands = mp_hands.Hands(static_image_mode=False,
                       max_num_hands=2,
                       min_detection_confidence=0.5,
                       min_tracking_confidence=0.5)

pose = mp_pose.Pose(static_image_mode=False,
                    min_detection_confidence=0.5,
                    min_tracking_confidence=0.5)

all_data = []

# ---------- Walk through sub-categories and labels ----------
for category_name in os.listdir(DATASET_DIR):
    category_path = os.path.join(DATASET_DIR, category_name)
    if not os.path.isdir(category_path):
        continue

    for label_name in os.listdir(category_path):
        label_path = os.path.join(category_path, label_name)
        if not os.path.isdir(label_path):
            continue

        for video_file in os.listdir(label_path):
            if not video_file.endswith(('.mp4', '.mov', '.avi')):
                continue

            video_path = os.path.join(label_path, video_file)
            print(f"\n📹 กำลังประมวลผล: {video_path} (label: {label_name}, category: {category_name})")

            cap = cv2.VideoCapture(video_path)
            frame_idx = 0
            total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

            for _ in tqdm(range(total_frames), desc=f"{category_name}/{label_name}/{video_file}"):
                success, frame = cap.read()
                if not success:
                    break

                image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                hand_results = hands.process(image)
                pose_results = pose.process(image)

                frame_data = {
                    "category": category_name,
                    "label": label_name,
                    "video": video_file,
                    "frame": frame_idx,
                    "hands": [],
                    "pose": []
                }

                if hand_results.multi_hand_landmarks:
                    for hand_landmark in hand_results.multi_hand_landmarks:
                        frame_data["hands"].append([
                            [lm.x, lm.y, lm.z] for lm in hand_landmark.landmark
                        ])

                if pose_results.pose_landmarks:
                    frame_data["pose"] = [
                        [lm.x, lm.y, lm.z] for lm in pose_results.pose_landmarks.landmark
                    ]

                all_data.append(frame_data)
                frame_idx += 1

            cap.release()

# ---------- Save JSON ----------
with open(OUTPUT_JSON, 'w', encoding='utf-8') as f:
    json.dump(all_data, f, indent=2, ensure_ascii=False)

hands.close()
pose.close()

print(f"\n✅ เสร็จสมบูรณ์! JSON ถูกบันทึกไว้ที่ '{OUTPUT_JSON}'")
