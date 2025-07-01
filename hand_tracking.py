import cv2
import mediapipe as mp
import numpy as np
from PIL import ImageFont, ImageDraw, Image

# ฟอนต์ที่รองรับภาษาไทยในระบบ (เช่น Arial หรือ MS Gothic)
FONT_PATH = "C:\\Windows\\Fonts\\tahoma.ttf"  # ใช้ฟอนต์ Arial หรือฟอนต์ที่รองรับ

# ฟังก์ชันแสดงข้อความภาษาไทย
def draw_text_thai(image, text, position, font_size=48, color=(0, 0, 0)):
    try:
        font = ImageFont.truetype(FONT_PATH, font_size)
    except OSError:
        print(f"ไม่สามารถโหลดฟอนต์ {FONT_PATH} ได้")
        return image  # ถ้าไม่สามารถโหลดฟอนต์ได้จะไม่แสดงข้อความ

    image_pil = Image.fromarray(image)
    draw = ImageDraw.Draw(image_pil)
    draw.text(position, text, font=font, fill=color)
    return np.array(image_pil)

# ฟังก์ชันตรวจจับท่าภาษามือง่าย ๆ
def detect_simple_sign(landmarks):
    thumb_tip, thumb_base = landmarks[4], landmarks[1]
    index_tip, index_base = landmarks[8], landmarks[5]
    middle_tip, middle_base = landmarks[12], landmarks[9]
    ring_tip, ring_base = landmarks[16], landmarks[13]
    pinky_tip, pinky_base = landmarks[20], landmarks[17]
    
    def finger_folded(tip, base):
        return tip[1] > base[1]

    if (thumb_tip[1] < thumb_base[1] and
        all(finger_folded(tip, base) for tip, base in [(index_tip, index_base), (middle_tip, middle_base), (ring_tip, ring_base), (pinky_tip, pinky_base)])):
        return "ชูนิ้วโป้ง 👍"

    if (finger_folded(thumb_tip, thumb_base) and
        index_tip[1] < index_base[1] and
        all(finger_folded(tip, base) for tip, base in [(middle_tip, middle_base), (ring_tip, ring_base), (pinky_tip, pinky_base)])):
        return "ยกนิ้วชี้ 👉"

    if all(finger_folded(tip, base) for tip, base in [
        (thumb_tip, thumb_base), (index_tip, index_base), 
        (middle_tip, middle_base), (ring_tip, ring_base), 
        (pinky_tip, pinky_base)]):
        return "กำมือ ✊"

    return "ยังไม่รู้จักท่านี้ 🤷"

# เริ่มต้นกล้องและ MediaPipe
cap = cv2.VideoCapture(0)
cap.set(3, 1280)
cap.set(4, 720)

mp_hands = mp.solutions.hands
mp_drawing = mp.solutions.drawing_utils

with mp_hands.Hands(min_detection_confidence=0.5, min_tracking_confidence=0.5, max_num_hands=1) as hands:
    while cap.isOpened():
        success, frame = cap.read()
        if not success:
            break

        frame = cv2.flip(frame, 1)
        image = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        image.flags.writeable = False
        results = hands.process(image)

        image.flags.writeable = True
        image = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)

        if results.multi_hand_landmarks:
            for hand_landmarks in results.multi_hand_landmarks:
                mp_drawing.draw_landmarks(image, hand_landmarks, mp_hands.HAND_CONNECTIONS)

                landmarks = [(lm.x, lm.y) for lm in hand_landmarks.landmark]
                sign_text = detect_simple_sign(landmarks)

                image = draw_text_thai(image, sign_text, (50, 50))

        cv2.imshow("Hand Sign Detection", image)
        if cv2.waitKey(10) & 0xFF == ord('q'):
            break

cap.release()
cv2.destroyAllWindows()
