from PIL import ImageFont

# ลองเปิดฟอนต์
try:
    font = ImageFont.truetype("THSarabunNew.ttf", 48)
    print("ฟอนต์เปิดได้")
except OSError:
    print("ไม่สามารถเปิดฟอนต์ได้")