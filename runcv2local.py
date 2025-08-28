# runcv2local.py — เวอร์ชันอัปเดต (รองรับเฟรมเดี่ยว/ซีเควนซ์ + ไทย)
import cv2, json, numpy as np
from pathlib import Path
from collections import deque
import tensorflow as tf
import mediapipe as mp
from PIL import ImageFont, ImageDraw, Image

# ========= ตั้งค่า =========
FONT_PATH = r"C:\Windows\Fonts\tahoma.ttf"  # เปลี่ยนได้ตามฟอนต์ที่มี
MODEL_FILE = 'hand_gesture_model_seq.keras'             # ถ้าใช้ชื่ออื่น แก้ตรงนี้ เช่น 'hand_gesture_model_seq.keras'
LABELS_FILE = 'labels.json'
CONF_THRESH = 0.65                          # ธรณีความมั่นใจ
VOTE_WINDOW = 7                             # ความยาวหน้าต่างโหวต (5–11 กำลังดี)

# ========= วาดตัวหนังสือไทย =========
def put_thai(img_bgr, text, pos=(10, 50), size=36, color=(0, 255, 0)):
    font = ImageFont.truetype(FONT_PATH, size)
    img_pil = Image.fromarray(cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB))
    draw = ImageDraw.Draw(img_pil)
    draw.text(pos, text, font=font, fill=color)
    return cv2.cvtColor(np.array(img_pil), cv2.COLOR_RGB2BGR)

# ========= โหลดโมเดล/เลเบล =========
SCRIPT_DIR = Path(__file__).resolve().parent
model = tf.keras.models.load_model(SCRIPT_DIR / MODEL_FILE)

# input_shape: (None, 63) หรือ (None, T, 63)
in_shape = model.input_shape
is_sequence_model = (len(in_shape) == 3)
T = int(in_shape[1]) if is_sequence_model and in_shape[1] is not None else (16 if is_sequence_model else None)

labels_path = SCRIPT_DIR / LABELS_FILE
LABELS = json.loads(labels_path.read_text(encoding='utf-8'))
def label_name_by_idx(idx:int):
    if isinstance(LABELS, list):
        return LABELS[idx] if 0 <= idx < len(LABELS) else f"cls_{idx}"
    # dict กรณี key เป็น str ของ index
    key = str(idx)
    return LABELS.get(key, f"cls_{idx}")

# ========= MediaPipe Hands =========
mp_hands = mp.solutions.hands
mp_draw = mp.solutions.drawing_utils
hands = mp_hands.Hands(
    static_image_mode=False,
    max_num_hands=1,
    model_complexity=1,
    min_detection_confidence=0.7,
    min_tracking_confidence=0.5
)

# ========= Preprocess ให้ตรงตอนเทรน =========
def lms_to_norm_vec63(hand_lms):
    """
    hand_lms: mp.framework_landmark_list ของมือ 21 จุด
    คืนค่าเวกเตอร์ (63,) โดย
    - ย้ายฐานไปจุด 0 (ข้อมือ)
    - สเกลด้วยรัศมีสูงสุดของเวกเตอร์ (max L2 norm)
    """
    pts = np.array([[lm.x, lm.y, lm.z] for lm in hand_lms.landmark], dtype=np.float32)  # (21,3) normalized coords
    if pts.shape != (21, 3):
        return None
    pts -= pts[0]  # center ที่ landmark 0
    scale = np.linalg.norm(pts, axis=1).max() + 1e-6
    pts /= scale
    return pts.flatten().astype(np.float32)  # (63,)

# ========= ตัวช่วยพยากรณ์ (โหวต + threshold) =========
vote = deque(maxlen=VOTE_WINDOW)
seq_buffer = deque(maxlen=T) if is_sequence_model else None

def predict_with_adapter(feat63):
    """
    feat63: np.ndarray (63,)
    คืนค่า: (ชื่อเลเบล, ความมั่นใจ, prob_vector) หรือ (None,None,None) ถ้ายังสะสมซีเควนซ์ไม่ครบ
    """
    if not is_sequence_model:
        x = feat63.reshape(1, 63)
        prob = model.predict(x, verbose=0)[0]
    else:
        seq_buffer.append(feat63)
        if len(seq_buffer) < T:
            return None, None, None
        x = np.array(seq_buffer, dtype=np.float32).reshape(1, T, 63)
        prob = model.predict(x, verbose=0)[0]

    cls = int(np.argmax(prob))
    conf = float(prob[cls])

    vote.append(cls)
    voted_cls = max(set(vote), key=vote.count)

    name = "ไม่มั่นใจ" if conf < CONF_THRESH else label_name_by_idx(voted_cls)
    return name, conf, prob

# ========= กล้อง =========
cap = cv2.VideoCapture(0)
if not cap.isOpened():
    raise RuntimeError("เปิดกล้องไม่ได้ (index=0)")

print("กด ESC เพื่อออก")
while True:
    ok, frame = cap.read()
    if not ok:
        break

    frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    result = hands.process(frame_rgb)

    if result.multi_hand_landmarks:
        hand_lms = result.multi_hand_landmarks[0]  # ใช้มือแรก
        # วาดโครงมือ (ถ้าอยากปิดให้คอมเมนต์สองบรรทัดต่อไป)
        mp_draw.draw_landmarks(frame, hand_lms, mp_hands.HAND_CONNECTIONS)

        feat63 = lms_to_norm_vec63(hand_lms)
        if feat63 is None:
            frame = put_thai(frame, "Bad landmarks", (10, 50), size=32, color=(0, 0, 255))
        else:
            name, conf, prob = predict_with_adapter(feat63)
            if name is None:
                # กรณีเป็นโมเดลซีเควนซ์และยังสะสมเฟรมไม่ครบ
                frame = put_thai(frame, f"กำลังสะสมเฟรม {len(seq_buffer)}/{T}", (10, 50), size=32, color=(255, 200, 0))
            else:
                color = (0, 165, 255) if name == "ไม่มั่นใจ" else (0, 255, 0)
                frame = put_thai(frame, f"{name} ({conf:.2f})", (10, 50), size=36, color=color)
    else:
        frame = put_thai(frame, "ไม่พบมือ", (10, 50), size=32, color=(0, 0, 255))

    cv2.imshow("Hand Gesture", frame)
    if cv2.waitKey(1) & 0xFF == 27:  # ESC
        break

cap.release()
cv2.destroyAllWindows()
