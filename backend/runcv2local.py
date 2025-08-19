import cv2, json, numpy as np
from pathlib import Path
from tensorflow.keras.models import load_model
import mediapipe as mp
from PIL import ImageFont, ImageDraw, Image

FONT_PATH = r"C:\Windows\Fonts\tahoma.ttf"  # เปลี่ยนได้ตามฟอนต์ที่มี

def put_thai(img_bgr, text, pos=(10, 50), size=36):
    font = ImageFont.truetype(FONT_PATH, size)
    img_pil = Image.fromarray(cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB))
    draw = ImageDraw.Draw(img_pil)
    draw.text(pos, text, font=font, fill=(0, 255, 0))  # เขียวเหมือน cv2.putText
    return cv2.cvtColor(np.array(img_pil), cv2.COLOR_RGB2BGR)


SCRIPT_DIR = Path(__file__).resolve().parent
model = load_model(SCRIPT_DIR / 'hand_gesture_model.keras')
LABELS = json.loads((SCRIPT_DIR / 'labels.json').read_text(encoding='utf-8'))

mp_hands = mp.solutions.hands
hands = mp_hands.Hands(max_num_hands=1, min_detection_confidence=0.7)
mp_draw = mp.solutions.drawing_utils

cap = cv2.VideoCapture(0)
while True:
    ok, frame = cap.read()
    if not ok: break
    frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    result = hands.process(frame_rgb)

    if result.multi_hand_landmarks:
        for hand_lms in result.multi_hand_landmarks:
            data = []
            for lm in hand_lms.landmark:
                data.extend([lm.x, lm.y, lm.z])  # ต้อง preprocess ให้เหมือนตอนเทรน
            x = np.array(data, dtype=np.float32)[None, :]
            prob = model.predict(x, verbose=0)[0]
            idx = int(np.argmax(prob))
            name = LABELS[idx] if isinstance(LABELS, list) else LABELS[str(idx)]
            conf = float(prob[idx])

            mp_draw.draw_landmarks(frame, hand_lms, mp_hands.HAND_CONNECTIONS)
            frame = put_thai(frame, f"{name} ({conf:.2f})")

    cv2.imshow("Hand Gesture", frame)
    if cv2.waitKey(1) & 0xFF == 27: break
cap.release(); cv2.destroyAllWindows()
