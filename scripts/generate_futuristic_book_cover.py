import os
os.environ['MPLCONFIGDIR'] = '/tmp/mpl_config'
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageEnhance

# Canvas Dimensions: A4 at 300 DPI for ultra crisp print quality (2000 x 2828 px)
W, H = 2000, 2828
cover = Image.new('RGBA', (W, H), (8, 14, 26, 255))
draw = ImageDraw.Draw(cover)

# 1. Background Gradient (Deep Midnight Navy to Dark Emerald - NO Grid Lines!)
# Smooth, clean vertical gradient
for y in range(H):
    ratio = y / H
    r = int(8 * (1 - ratio) + 4 * ratio)
    g = int(14 * (1 - ratio) + 24 * ratio)
    b = int(26 * (1 - ratio) + 18 * ratio)
    draw.line([(0, y), (W, y)], fill=(r, g, b, 255))

# 2. Process Translucent Spectra Watermark Background ("ภาพแบบโปร่งใสจางๆ เติมปกอยู่เป็นพื้นหลังภาพจางๆ เห็นรางๆ")
spectra_path = 'docs/manual/figures/soil_nutrient_absorption_spectra.png'
img_spectra_raw = Image.open(spectra_path).convert('RGB')

# Extract curves and convert white background to transparent glowing watermark
arr_spec = np.array(img_spectra_raw, dtype=np.float32)
lum = 0.299 * arr_spec[:,:,0] + 0.587 * arr_spec[:,:,1] + 0.114 * arr_spec[:,:,2]
darkness = 255.0 - lum

h_s, w_s = lum.shape
watermark_arr = np.zeros((h_s, w_s, 4), dtype=np.uint8)

# Tint curves with luminous cyan/emerald/gold
watermark_arr[:,:,0] = np.clip(arr_spec[:,:,0] * 0.4 + 0 * 0.6, 0, 255).astype(np.uint8)
watermark_arr[:,:,1] = np.clip(arr_spec[:,:,1] * 0.5 + 220 * 0.5, 0, 255).astype(np.uint8)
watermark_arr[:,:,2] = np.clip(arr_spec[:,:,2] * 0.5 + 255 * 0.5, 0, 255).astype(np.uint8)

# Alpha: white background (darkness < 12) becomes completely transparent,
# curves and text appear faintly and translucently ("เห็นรางๆ") with max alpha ~ 65 (~25% opacity)
alpha_channel = np.clip((darkness - 10) * 0.55, 0, 65).astype(np.uint8)
watermark_arr[:,:,3] = alpha_channel

watermark_img = Image.fromarray(watermark_arr, 'RGBA')

# Scale watermark to span nicely across the background (width = 1900 px)
wm_w = 1920
wm_h = int(watermark_img.height * (wm_w / watermark_img.width))
watermark_resized = watermark_img.resize((wm_w, wm_h), Image.Resampling.LANCZOS)

# Paste watermark twice: upper section and middle-lower section for rich coverage
# 1. Subtle watermark in the upper-mid region
cover.paste(watermark_resized, ((W - wm_w) // 2, 490), watermark_resized)
# 2. Subtle watermark in the lower region
cover.paste(watermark_resized, ((W - wm_w) // 2, 1380), watermark_resized)

# 3. Process Spectra Foreground Card (Crisp, High-Contrast Card on Upper-Right)
img_spectra = Image.open(spectra_path).convert('RGBA')
spectra_w = 1240
spectra_h = int(img_spectra.height * (spectra_w / img_spectra.width))
img_spectra_resized = img_spectra.resize((spectra_w, spectra_h), Image.Resampling.LANCZOS)

def create_rounded_card(img, radius=20, border_color=(0, 210, 255, 180), border_width=2):
    w, h = img.size
    mask = Image.new('L', (w, h), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([(0, 0), (w, h)], radius=radius, fill=255)
    
    card = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    card.paste(img, (0, 0), mask=mask)
    
    card_draw = ImageDraw.Draw(card)
    card_draw.rounded_rectangle([(border_width//2, border_width//2), (w - border_width//2, h - border_width//2)],
                                 radius=radius, outline=border_color, width=border_width)
    return card

def add_dropshadow(bg, fg, pos, offset=(16, 22), blur_radius=35, shadow_alpha=170):
    fw, fh = fg.size
    shadow = Image.new('RGBA', (fw + blur_radius * 4, fh + blur_radius * 4), (0, 0, 0, 0))
    sh_draw = ImageDraw.Draw(shadow)
    sh_draw.rounded_rectangle([(blur_radius*2, blur_radius*2), (blur_radius*2 + fw, blur_radius*2 + fh)],
                              radius=28, fill=(0, 0, 0, shadow_alpha))
    shadow_blurred = shadow.filter(ImageFilter.GaussianBlur(blur_radius))
    bg.paste(shadow_blurred, (pos[0] + offset[0] - blur_radius*2, pos[1] + offset[1] - blur_radius*2), shadow_blurred)
    bg.paste(fg, pos, fg)

# Place Spectra Card on Upper Right
spectra_card = create_rounded_card(img_spectra_resized, radius=20, border_color=(0, 210, 255, 160), border_width=2)
spectra_pos = (W - spectra_w - 70, 720)
add_dropshadow(cover, spectra_card, spectra_pos, offset=(14, 20), blur_radius=30, shadow_alpha=160)

# 4. Process Phone Image (Hero Mockup on Left - Authentic NPxAI N-P Analysis Screen)
phone_path = 'docs/manual/figures/npxai_app_np_analysis_screen.jpg'
img_phone = Image.open(phone_path).convert('RGBA')

phone_w = 670
phone_h = int(img_phone.height * (phone_w / img_phone.width))
img_phone_resized = img_phone.resize((phone_w, phone_h), Image.Resampling.LANCZOS)

bezel_padding_x = 22
bezel_padding_top = 34
bezel_padding_bottom = 34
phone_shell_w = phone_w + bezel_padding_x * 2
phone_shell_h = phone_h + bezel_padding_top + bezel_padding_bottom

phone_shell = Image.new('RGBA', (phone_shell_w, phone_shell_h), (0, 0, 0, 0))
shell_draw = ImageDraw.Draw(phone_shell)

# Outer phone bezel with emerald/cyan accent
shell_draw.rounded_rectangle([(0, 0), (phone_shell_w, phone_shell_h)], radius=38, fill=(15, 23, 40, 250), outline=(0, 230, 153, 200), width=3)
# Speaker slit
shell_draw.rounded_rectangle([(phone_shell_w//2 - 40, 14), (phone_shell_w//2 + 40, 19)], radius=3, fill=(100, 116, 139, 180))

# Phone screen mask
screen_mask = Image.new('L', (phone_w, phone_h), 0)
screen_mask_draw = ImageDraw.Draw(screen_mask)
screen_mask_draw.rounded_rectangle([(0, 0), (phone_w, phone_h)], radius=20, fill=255)
phone_shell.paste(img_phone_resized, (bezel_padding_x, bezel_padding_top), mask=screen_mask)

# Screen inner border
shell_draw.rounded_rectangle([(bezel_padding_x, bezel_padding_top), (bezel_padding_x + phone_w, bezel_padding_top + phone_h)],
                             radius=20, outline=(0, 230, 153, 140), width=1)

# Place Phone Mockup on Left
phone_pos = (90, 780)
add_dropshadow(cover, phone_shell, phone_pos, offset=(18, 26), blur_radius=38, shadow_alpha=190)

# 5. Clean HUD Cards below Spectra (No messy laser lines!)
hud_draw = ImageDraw.Draw(cover)

badge_y = spectra_pos[1] + spectra_h + 35
badge_box = [(spectra_pos[0], badge_y), (spectra_pos[0] + spectra_w, badge_y + 115)]
hud_draw.rounded_rectangle(badge_box, radius=14, fill=(13, 22, 38, 230), outline=(0, 230, 153, 130), width=2)

# Card 1: Soil-ViT & Edge AI
card1_box = [(spectra_pos[0] + 15, badge_y + 155), (spectra_pos[0] + 590, badge_y + 305)]
hud_draw.rounded_rectangle(card1_box, radius=12, fill=(11, 20, 36, 230), outline=(0, 210, 255, 110), width=1)

# Card 2: 0-Lux Optics & 7 Spectral Channels
card2_box = [(spectra_pos[0] + 625, badge_y + 155), (spectra_pos[0] + spectra_w - 15, badge_y + 305)]
hud_draw.rounded_rectangle(card2_box, radius=12, fill=(11, 20, 36, 230), outline=(255, 183, 77, 120), width=1)

# 6. Typography with System Fonts
font_path = '/System/Library/Fonts/Supplemental/Thonburi.ttc'
font_badge = ImageFont.truetype(font_path, 24, index=1)
font_faculty = ImageFont.truetype(font_path, 22, index=0)
font_main_super = ImageFont.truetype(font_path, 36, index=1)
font_main_th = ImageFont.truetype(font_path, 42, index=1)
font_main_sub = ImageFont.truetype(font_path, 25, index=0)
font_hud_title = ImageFont.truetype(font_path, 26, index=1)
font_hud_desc = ImageFont.truetype(font_path, 21, index=0)
font_authors = ImageFont.truetype(font_path, 42, index=1)
font_univ = ImageFont.truetype(font_path, 28, index=1)
font_year = ImageFont.truetype(font_path, 24, index=2)

# Top Bar Header (RBRU Unit)
hud_draw.text((90, 75), "หน่วยวิจัยปัญญาประดิษฐ์เพื่อเกษตรดิจิทัล", font=font_badge, fill=(245, 197, 66, 255))
hud_draw.text((90, 110), "คณะวิทยาศาสตร์และเทคโนโลยี มหาวิทยาลัยราชภัฏรำไพพรรณี", font=font_faculty, fill=(203, 213, 225, 220))

# Tech Pill Tag on Top Right
pill_box = [(W - 480, 75), (W - 90, 125)]
hud_draw.rounded_rectangle(pill_box, radius=25, fill=(0, 230, 153, 30), outline=(0, 230, 153, 180), width=1)
hud_draw.text((W - 440, 88), "AIoT • VIS-NIR • 0-LUX", font=font_badge, fill=(0, 230, 153, 255))

# Main Book Title Section
hud_draw.text((90, 195), "คู่มือระบบและเอกสารวิจัยฉบับสมบูรณ์", font=font_main_super, fill=(255, 255, 255, 255))

title_th_line1 = "การพัฒนาชุดวิเคราะห์ปริมาณไนโตรเจนและฟอสฟอรัสในดินแบบพกพา"
title_th_line2 = "ด้วยหลักการสะท้อนแสงร่วมกับปัญญาประดิษฐ์ (NPxAI)"
hud_draw.text((90, 255), title_th_line1, font=font_main_th, fill=(245, 197, 66, 255))
hud_draw.text((90, 320), title_th_line2, font=font_main_th, fill=(245, 197, 66, 255))

title_en = "Development of a Portable Soil Nitrogen and Phosphorus Analyzer using Reflectance Principle Integrated with AI"
hud_draw.text((90, 388), title_en, font=font_main_sub, fill=(148, 163, 184, 255))

# Golden & Emerald Accent Divider
hud_draw.line([(90, 440), (W - 90, 440)], fill=(245, 197, 66, 210), width=2)
hud_draw.line([(90, 445), (W - 90, 445)], fill=(0, 230, 153, 150), width=1)

# Badge Texts in HUD area
hud_draw.text((spectra_pos[0] + 30, badge_y + 20), "การวิเคราะห์ผลสัมฤทธิ์ธาตุอาหารพืช N-P และลายพิมพ์สเปกตรัม Vis-NIR", font=font_hud_title, fill=(0, 230, 153, 255))
hud_draw.text((spectra_pos[0] + 30, badge_y + 65), "Total N (Kjeldahl): 3.20 g/kg • Available P (Bray II): 30.29 mg/kg • ความเชื่อมั่น R²: 0.96", font=font_hud_desc, fill=(226, 232, 240, 240))

# Card 1 Content (Soil-ViT & Edge AI)
hud_draw.text((card1_box[0][0] + 25, card1_box[0][1] + 20), "โมเดลปัญญาประดิษฐ์ Soil-ViT & AI", font=font_hud_title, fill=(0, 210, 255, 255))
hud_draw.text((card1_box[0][0] + 25, card1_box[0][1] + 65), "Vision Transformer • CNN ResNet-18 • RF\nความแม่นยำสูงระดับแปลงเกษตรกรรมแบบเวลาจริง", font=font_hud_desc, fill=(203, 213, 225, 220))

# Card 2 Content (Optics)
hud_draw.text((card2_box[0][0] + 25, card2_box[0][1] + 20), "ลายพิมพ์สเปกตรัมและกล่องมืด 0-Lux", font=font_hud_title, fill=(255, 183, 77, 255))
hud_draw.text((card2_box[0][0] + 25, card2_box[0][1] + 65), "เรขาคณิต CIE 45°/0° • LED 7 แชนเนล\nตรวจวัดช่วงคลื่น 405, 465, 525, 630, 850, 940 nm", font=font_hud_desc, fill=(203, 213, 225, 220))

# Bottom Authors Section (Clean Minimalist Academic)
author_box_top = H - 280
hud_draw.line([(90, author_box_top - 30), (W - 90, author_box_top - 30)], fill=(0, 230, 153, 60), width=1)

authors_text = "ชีวะ ทัศนา          จิรภัทร จันทมาลี"
bbox_authors = hud_draw.textbbox((0, 0), authors_text, font=font_authors)
hud_draw.text(((W - (bbox_authors[2] - bbox_authors[0])) // 2, author_box_top), authors_text, font=font_authors, fill=(255, 255, 255, 255))

univ_text = "มหาวิทยาลัยราชภัฏรำไพพรรณี"
bbox_univ = hud_draw.textbbox((0, 0), univ_text, font=font_univ)
hud_draw.text(((W - (bbox_univ[2] - bbox_univ[0])) // 2, author_box_top + 65), univ_text, font=font_univ, fill=(245, 197, 66, 255))

year_text = "2569"
bbox_year = hud_draw.textbbox((0, 0), year_text, font=font_year)
hud_draw.text(((W - (bbox_year[2] - bbox_year[0])) // 2, author_box_top + 115), year_text, font=font_year, fill=(148, 163, 184, 180))

# Convert to RGB and save
final_cover = cover.convert('RGB')
output_cover_path = 'docs/manual/figures/npxai_futuristic_book_cover.jpg'
final_cover.save(output_cover_path, quality=95, dpi=(300, 300))
print(f"Successfully generated clean translucent watermark book cover: {output_cover_path}")
