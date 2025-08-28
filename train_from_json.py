# train_from_json.py  (Sequence + Robust Split + Fixed Reporting)
import os, json, math, random, argparse
import numpy as np
import tensorflow as tf

from tensorflow.keras import layers, callbacks, models, optimizers
from sklearn.model_selection import GroupShuffleSplit
from sklearn.metrics import classification_report, confusion_matrix
from sklearn.utils.class_weight import compute_class_weight

# -----------------------
# Reproducibility
# -----------------------
SEED = 42
np.random.seed(SEED)
random.seed(SEED)
tf.keras.utils.set_random_seed(SEED)

# -----------------------
# CLI
# -----------------------
def get_args():
    p = argparse.ArgumentParser("Train sign-language model from landmark JSON (temporal).")
    p.add_argument("--json", default="hands_landmarks.json", help="Path to dataset JSON.")
    p.add_argument("--model", default="hand_gesture_model_seq.keras", help="Output model path.")
    p.add_argument("--labels", default="labels.json", help="Output labels list path.")
    p.add_argument("--epochs", type=int, default=200)
    p.add_argument("--batch", type=int, default=32)
    p.add_argument("--val", type=float, default=0.15, help="Validation ratio (0-1).")
    p.add_argument("--win", type=int, default=16, help="Frames per sample window.")
    p.add_argument("--step", type=int, default=2, help="Sliding step between windows.")
    p.add_argument("--lr", type=float, default=1e-3, help="Initial learning rate.")
    p.add_argument("--augment-times", type=int, default=1, help="Extra augmented copies for train sequences.")
    p.add_argument("--no-augment", action="store_true", help="Disable augmentation.")
    p.add_argument("--max-split-tries", type=int, default=200, help="Max tries to get a val set containing all classes.")
    return p.parse_args()

# -----------------------
# Geometry helpers
# -----------------------
def _normalize_hand(hand21):
    """hand21: list/array (21,3) → normalize (center @ wrist, scale by max radius)."""
    lm = np.array(hand21, dtype=np.float32)
    if lm.shape != (21, 3):
        return None
    lm -= lm[0]
    scale = np.linalg.norm(lm, axis=1).max() + 1e-6
    lm /= scale
    return lm

def _apply_transform_xy(xy, s, theta, mirror):
    """xy: (...,2) apply mirrorX, scale, rotateZ."""
    out = xy.copy()
    if mirror:
        out[..., 0] *= -1.0
    out *= s
    c, si = math.cos(theta), math.sin(theta)
    R = np.array([[c, -si], [si, c]], dtype=np.float32)
    return out @ R.T

def augment_frame(frame63, params):
    """frame63 -> (63,), params=(s,theta,mirror,jitter_std) used consistently across a sequence."""
    pts = frame63.reshape(21, 3).copy()
    s, theta, mirror, jitter_std = params
    pts[:, :2] = _apply_transform_xy(pts[:, :2], s, theta, mirror)
    if jitter_std > 0:
        pts += np.random.normal(0.0, jitter_std, size=pts.shape).astype(np.float32)
    # re-normalize per frame for stability
    pts -= pts[0]
    scale = np.linalg.norm(pts, axis=1).max() + 1e-6
    pts /= scale
    return pts.flatten().astype(np.float32)

def make_seq_augment(Xseq, times=1, jitter_std=0.01, max_deg=12.0, scale_rng=(0.96, 1.04), mirror_p=0.5):
    """Xseq: (N, T, 63) → concat augmented copies using same transform for all frames in a seq."""
    if times <= 0:
        return Xseq
    outs = [Xseq]
    N, T, _ = Xseq.shape
    for _ in range(times):
        s = random.uniform(*scale_rng)
        theta = math.radians(random.uniform(-max_deg, max_deg))
        mirror = random.random() < mirror_p
        params = (s, theta, mirror, jitter_std)
        aug = np.empty_like(Xseq)
        for i in range(N):
            for t in range(T):
                aug[i, t] = augment_frame(Xseq[i, t], params)
        outs.append(aug)
    return np.concatenate(outs, axis=0)

# -----------------------
# Dataset builders
# -----------------------
def load_items(json_path):
    with open(json_path, "r", encoding="utf-8") as f:
        return json.load(f)

def build_sequences(json_path, win=16, step=2):
    """
    Return:
      Xseq: (N, win, 63)
      y:   (N,)
      groups: list of group ids (video name) for GroupSplit
      label2id: dict
    """
    data = load_items(json_path)
    buckets = {}  # key=(label, video) → [(frame, 63)]
    label2id, next_id = {}, 0

    for idx, item in enumerate(data):
        label = item.get("label")
        video = item.get("video", "novideo")
        frame = int(item.get("frame", idx))
        hands = item.get("hands", [])

        if not label or not hands:
            continue
        # pick first hand; customize here if needed
        hand = hands[0]
        lm = _normalize_hand(hand)
        if lm is None:
            continue

        if label not in label2id:
            label2id[label] = next_id
            next_id += 1

        key = (label, video)
        buckets.setdefault(key, []).append((frame, lm.flatten()))

    Xseq, y, groups = [], [], []
    for (label, video), samples in buckets.items():
        samples.sort(key=lambda x: x[0])  # by frame
        feats = [f for _, f in samples]
        if len(feats) < win:
            continue
        for start in range(0, len(feats) - win + 1, step):
            chunk = np.stack(feats[start:start + win], axis=0)  # (win,63)
            Xseq.append(chunk)
            y.append(label2id[label])
            groups.append(video)

    Xseq = np.array(Xseq, dtype=np.float32)
    y = np.array(y, dtype=np.int64)
    return Xseq, y, groups, label2id

def group_stratified_split_all_classes(X, y, groups, test_size=0.15, max_tries=200, seed=42):
    """Try multiple seeds until val contains all classes; fallback to last split if not possible."""
    n_classes = len(np.unique(y))
    last = None
    for i in range(max_tries):
        gss = GroupShuffleSplit(n_splits=1, test_size=test_size, random_state=seed + i)
        tr_idx, val_idx = next(gss.split(X, y, groups=groups))
        last = (tr_idx, val_idx)
        if len(np.unique(y[val_idx])) == n_classes:
            return tr_idx, val_idx
    return last

# -----------------------
# Model
# -----------------------
def build_seq_model(n_classes, T, lr=1e-3):
    inp = layers.Input(shape=(T, 63))
    # frame embedding
    x = layers.TimeDistributed(layers.Dense(128, use_bias=False))(inp)
    x = layers.TimeDistributed(layers.BatchNormalization())(x)
    x = layers.Activation("relu")(x)
    x = layers.Dropout(0.2)(x)

    # temporal encoder
    x = layers.Bidirectional(layers.LSTM(128, return_sequences=True))(x)
    x = layers.Bidirectional(layers.LSTM(64))(x)

    # head
    x = layers.Dense(128, activation="relu")(x)
    x = layers.Dropout(0.3)(x)
    out = layers.Dense(n_classes, activation="softmax")(x)

    model = models.Model(inp, out)
    model.compile(
        optimizer=optimizers.Adam(learning_rate=lr),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"]
    )
    return model

# -----------------------
# Main
# -----------------------
def main():
    args = get_args()
    assert os.path.exists(args.json), f"ไม่พบไฟล์ {args.json}"

    # Build sequence dataset
    Xseq, y, groups, label2id = build_sequences(args.json, win=args.win, step=args.step)
    if len(Xseq) == 0:
        raise ValueError(f"ไม่มีตัวอย่างซีเควนซ์เลย (Xseq==0). ลองลด --win (ตอนนี้ {args.win}) หรือเช็กโครงสร้าง JSON")
    n_classes = len(label2id)
    print(f"[INFO] seq_samples={len(Xseq)}, classes={n_classes}, window={args.win}, step={args.step}")

    # Group-wise split by video; try to include all classes in val
    tr_idx, val_idx = group_stratified_split_all_classes(
        Xseq, y, groups, test_size=args.val, max_tries=args.max_split_tries, seed=SEED
    )
    X_tr, y_tr = Xseq[tr_idx], y[tr_idx]
    X_val, y_val = Xseq[val_idx], y[val_idx]
    print(f"[INFO] train={len(X_tr)}  val={len(X_val)}  groups(train)={len(set([groups[i] for i in tr_idx]))}")
    print(f"[INFO] classes in val = {np.unique(y_val)}")

    # Augmentation (optional)
    if not args.no_augment and len(X_tr) > 0:
        X_tr = make_seq_augment(X_tr, times=args.augment_times)
        y_tr = np.tile(y_tr, reps=(args.augment_times + 1))
        print(f"[INFO] after augmentation: train={len(X_tr)}")

    # Class weights for imbalance
    cls_w = compute_class_weight("balanced", classes=np.arange(n_classes), y=y_tr)
    class_weight = {i: float(w) for i, w in enumerate(cls_w)}
    print(f"[INFO] class_weight={class_weight}")

    # tf.data pipelines
    ds_tr = tf.data.Dataset.from_tensor_slices((X_tr, y_tr)).shuffle(len(X_tr), seed=SEED).batch(args.batch).prefetch(tf.data.AUTOTUNE)
    ds_val = tf.data.Dataset.from_tensor_slices((X_val, y_val)).batch(args.batch).prefetch(tf.data.AUTOTUNE)

    # Model & callbacks
    model = build_seq_model(n_classes=n_classes, T=args.win, lr=args.lr)
    model.summary()
    cbs = [
        callbacks.EarlyStopping(monitor="val_accuracy", patience=20, restore_best_weights=True),
        callbacks.ReduceLROnPlateau(monitor="val_loss", factor=0.5, patience=6, min_lr=1e-6, verbose=1),
        callbacks.ModelCheckpoint("best_model.keras", monitor="val_accuracy", save_best_only=True, verbose=1),
    ]

    # Train
    _ = model.fit(ds_tr, validation_data=ds_val, epochs=args.epochs, class_weight=class_weight, callbacks=cbs, verbose=1)

    # Evaluate & report (force full label set to avoid mismatch)
    print("\n[INFO] Evaluating on validation set ...")
    y_pred = np.argmax(model.predict(ds_val), axis=1)

    id2label = {v: k for k, v in label2id.items()}
    labels_list = [id2label[i] for i in range(n_classes)]
    labels_idx = np.arange(n_classes)

    print("\n[REPORT]")
    print(classification_report(
        y_val, y_pred,
        labels=labels_idx,
        target_names=labels_list,
        digits=4,
        zero_division=0
    ))

    print("[CONFUSION MATRIX]")
    print(confusion_matrix(
        y_val, y_pred,
        labels=labels_idx
    ))

    # Save model + labels
    model.save(args.model)
    with open(args.labels, "w", encoding="utf-8") as f:
        json.dump(labels_list, f, ensure_ascii=False, indent=2)

    print(f"\n[INFO] Saved model  -> {args.model}")
    print(f"[INFO] Saved labels -> {args.labels}")
    print("[INFO] Best checkpoint at best_model.keras")

if __name__ == "__main__":
    main()

    print("\n[INFO] Done")