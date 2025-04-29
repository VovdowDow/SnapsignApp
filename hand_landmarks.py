import cv2
import mediapipe as mp
import json
import os

# === ตั้งค่า ===
image_folder = 'images/'  # โฟลเดอร์ที่มีรูปภาพ
output_json = 'hand_landmarks_data.json'

# เรียกใช้งาน MediaPipe Hands
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(static_image_mode=True, max_num_hands=1, min_detection_confidence=0.5)

# เตรียมเก็บข้อมูลทั้งหมด
hand_data = {}

# ฟังก์ชันตรวจจับข้อนิ้วมือ
def get_finger_joints(hand_landmarks):
    # ข้อที่ 0 ถึง 4 คือข้อมือถึงปลายนิ้ว
    finger_joints = {}
    for finger_id in range(5):
        # กำหนดตำแหน่งของข้อนิ้วตาม MediaPipe Index (จากข้อมือถึงปลายนิ้ว)
        finger_joints[finger_id] = {
            'x': hand_landmarks.landmark[finger_id].x,
            'y': hand_landmarks.landmark[finger_id].y,
            'z': hand_landmarks.landmark[finger_id].z
        }
    return finger_joints

# วนลูปรูปภาพทุกไฟล์ในโฟลเดอร์
for filename in os.listdir(image_folder):
    if filename.lower().endswith(('.png', '.jpg', '.jpeg')):  # รับเฉพาะไฟล์รูป
        image_path = os.path.join(image_folder, filename)
        image = cv2.imread(image_path)
        
        if image is None:
            print(f"ไม่สามารถเปิดภาพ: {filename}")
            continue
        
        print(f"กำลังตรวจจับมือในภาพ: {filename}")
        image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        
        # ตรวจจับมือ
        results = hands.process(image_rgb)
        
        if results.multi_hand_landmarks:
            for hand_idx, hand_landmarks in enumerate(results.multi_hand_landmarks):
                # เรียกฟังก์ชันเพื่อดึงข้อมูลข้อนิ้วมือ
                finger_joints = get_finger_joints(hand_landmarks)
                hand_data[f'{filename}_hand_{hand_idx}'] = finger_joints
        else:
            print(f"ไม่พบมือในภาพ: {filename}")

# บันทึกข้อมูลลงในไฟล์ JSON
with open(output_json, 'w') as f:
    json.dump(hand_data, f, indent=4)

print(f"บันทึกข้อมูลข้อนิ้วมือเสร็จแล้วในไฟล์ {output_json}")

# ปิดใช้งาน Hands
hands.close()
