import os
os.environ['MPLCONFIGDIR'] = '/tmp/mpl_config'
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageEnhance

# Canvas Dimensions: A4 at ~250 DPI for ultra crisp print quality (2000 x 2828 px)
W, H = 2000, 2828
cover = Image.new('RGBA', (W, H), (10, 15, 29, 255))
draw = ImageDraw.Draw(cover)

# 1. Background Gradient & Cyber Grid
# Create vertical gradient from Deep Midnight Navy (#080E1A) to Agri-Emerald Deep Dark (#041A14)
for y in range(H):
    ratio = y / H
    r = int(8 * (1 - ratio) + 4 * ratio)
    g = int(14 * (1 - ratio) + 26 * ratio)
    b = int(26 * (1 - ratio) + 20 * ratio)
    draw.line([(0, y), (W, y)], fill=(r, g, b, 255))

# Draw subtle cybernetic grid
grid_step = 60
for x in range(0, W, grid_step):
    draw.line([(x, 0), (x, H)], fill=(0, 230, 180, 8), width=1)
for y in range(0, H, grid_step):
    draw.line([(0, y), (W, y)], fill=(0, 230, 180, 8), width=1)

# Subtle glowing diagonal beam accents
for i in range(-5, 15):
    x_start = i * 280
    draw.line([(x_start, 0), (x_start + 1200, H)], fill=(0, 210, 255, 12), width=1)

# 2. Load images
spectra_path = 'docs/manual/figures/soil_nutrient_absorption_spectra.png'
phone_path = 'docs/manual/figures/npxai_app_np_analysis_screen.jpg'

img_spectra = Image.open(spectra_path).convert('RGBA')
img_phone = Image.open(phone_path).convert('RGBA')

# 3. Process Spectra Image (Card on Upper-Right / Background)
# Dimensions for spectra card: 1250 x 870 px
spectra_w = 1260
spectra_h = int(img_spectra.height * (spectra_w / img_spectra.width))
img_spectra_resized = img_spectra.resize((spectra_w, spectra_h), Image.Resampling.LANCZOS)

# Create rounded card with glowing border for spectra
def create_rounded_card(img, radius=24, border_color=(0, 229, 255, 220), border_width=3, glow_color=(0, 229, 255, 60)):
    w, h = img.size
    mask = Image.new('L', (w, h), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([(0, 0), (w, h)], radius=radius, fill=255)
    
    card = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    card.paste(img, (0, 0), mask=mask)
    
    # Border
    card_draw = ImageDraw.Draw(card)
    card_draw.rounded_rectangle([(border_width//2, border_width//2), (w - border_width//2, h - border_width//2)],
                                 radius=radius, outline=border_color, width=border_width)
    return card

# 4. Process Phone Image (Hero Mockup on Left / Foreground)
# Phone target size: width ~ 670 px, height ~ 1490 px
phone_w = 670
phone_h = int(img_phone.height * (phone_w / img_phone.width))
img_phone_resized = img_phone.resize((phone_w, phone_h), Image.Resampling.LANCZOS)

# Wrap phone in sleek dark bezel
bezel_padding_x = 24
bezel_padding_top = 36
bezel_padding_bottom = 36
phone_shell_w = phone_w + bezel_padding_x * 2
phone_shell_h = phone_h + bezel_padding_top + bezel_padding_bottom

phone_shell = Image.new('RGBA', (phone_shell_w, phone_shell_h), (0, 0, 0, 0))
shell_draw = ImageDraw.Draw(phone_shell)

# Outer phone bezel with glowing emerald/cyan accent
shell_draw.rounded_rectangle([(0, 0), (phone_shell_w, phone_shell_h)], radius=42, fill=(15, 23, 38, 250), outline=(0, 230, 153, 230), width=4)
# Speaker slit
shell_draw.rounded_rectangle([(phone_shell_w//2 - 45, 14), (phone_shell_w//2 + 45, 20)], radius=3, fill=(100, 116, 139, 200))

# Phone screen mask
screen_mask = Image.new('L', (phone_w, phone_h), 0)
screen_mask_draw = ImageDraw.Draw(screen_mask)
screen_mask_draw.rounded_rectangle([(0, 0), (phone_w, phone_h)], radius=24, fill=255)
phone_shell.paste(img_phone_resized, (bezel_padding_x, bezel_padding_top), mask=screen_mask)

# Screen inner border
shell_draw.rounded_rectangle([(bezel_padding_x, bezel_padding_top), (bezel_padding_x + phone_w, bezel_padding_top + phone_h)],
                             radius=24, outline=(0, 230, 153, 160), width=2)

# Dropshadow generator
def add_dropshadow(bg, fg, pos, offset=(18, 25), blur_radius=35, shadow_alpha=160):
    fw, fh = fg.size
    shadow = Image.new('RGBA', (fw + blur_radius * 4, fh + blur_radius * 4), (0, 0, 0, 0))
    sh_draw = ImageDraw.Draw(shadow)
    sh_draw.rounded_rectangle([(blur_radius*2, blur_radius*2), (blur_radius*2 + fw, blur_radius*2 + fh)],
                              radius=30, fill=(0, 0, 0, shadow_alpha))
    shadow_blurred = shadow.filter(ImageFilter.GaussianBlur(blur_radius))
    bg.paste(shadow_blurred, (pos[0] + offset[0] - blur_radius*2, pos[1] + offset[1] - blur_radius*2), shadow_blurred)
    bg.paste(fg, pos, fg)

# Card positions
# Spectra Card on the Right:
spectra_card = create_rounded_card(img_spectra_resized, radius=20, border_color=(0, 210, 255, 200), border_width=3)
spectra_pos = (W - spectra_w - 70, 720)
add_dropshadow(cover, spectra_card, spectra_pos, offset=(12, 18), blur_radius=30, shadow_alpha=170)

# Phone Mockup on the Left (overlapping the spectra card gracefully):
phone_pos = (90, 780)
add_dropshadow(cover, phone_shell, phone_pos, offset=(20, 30), blur_radius=40, shadow_alpha=190)

# 5. Add Futuristic HUD Elements & Data Overlays connecting Phone and Spectra
hud_draw = ImageDraw.Draw(cover)

# Connection lines from phone actual N, P & Spectral Fingerprint to spectra chart
# 1. Total Nitrogen (around Y_rel = 0.46)
pt_n_x = phone_pos[0] + phone_shell_w - 20
pt_n_y = phone_pos[1] + int(phone_shell_h * 0.45)
target_n = (spectra_pos[0] + 890, spectra_pos[1] + 280) # SWIR Nitrogen absorption peak

# 2. Available Phosphorus (around Y_rel = 0.49)
pt_p_x = phone_pos[0] + phone_shell_w - 20
pt_p_y = phone_pos[1] + int(phone_shell_h * 0.50)
target_p = (spectra_pos[0] + 520, spectra_pos[1] + 340) # Short-NIR Fe-Oxide / Ava P peak

# 3. Vis-NIR Spectral Fingerprint Curve (around Y_rel = 0.68)
pt_spec_x = phone_pos[0] + phone_shell_w - 20
pt_spec_y = phone_pos[1] + int(phone_shell_h * 0.67)
target_spec = (spectra_pos[0] + 330, spectra_pos[1] + spectra_h - 130) # LED 405-940nm stimulation channels

# Draw Glowing Cyber Lines
for (sx, sy), (tx, ty), col in [
    ((pt_n_x, pt_n_y), target_n, (0, 210, 255)),     # Cyan for Nitrogen
    ((pt_p_x, pt_p_y), target_p, (0, 230, 153)),     # Emerald for Phosphorus
    ((pt_spec_x, pt_spec_y), target_spec, (255, 183, 77)) # Amber for Spectral Fingerprint
]:
    # Multi-segment sci-fi line
    mid_x = sx + 80
    hud_draw.line([(sx, sy), (mid_x, sy), (tx - 80, ty), (tx, ty)], fill=col + (180,), width=2)
    # Origin and Target Glowing Nodes
    hud_draw.ellipse([(sx - 5, sy - 5), (sx + 5, sy + 5)], fill=col + (230,), outline=(255, 255, 255, 255), width=2)
    hud_draw.ellipse([(tx - 6, ty - 6), (tx + 6, ty + 6)], fill=col + (230,), outline=(255, 255, 255, 255), width=2)

# High-Tech HUD Badges below the Spectra card
badge_y = spectra_pos[1] + spectra_h + 35
badge_box = [(spectra_pos[0], badge_y), (spectra_pos[0] + spectra_w, badge_y + 115)]
hud_draw.rounded_rectangle(badge_box, radius=16, fill=(15, 23, 42, 220), outline=(0, 230, 153, 140), width=2)

# Floating Micro-Cards around the layout
# Card 1: Edge AI Inference Engine & Soil-ViT
card1_box = [(spectra_pos[0] + 20, badge_y + 160), (spectra_pos[0] + 580, badge_y + 310)]
hud_draw.rounded_rectangle(card1_box, radius=14, fill=(11, 20, 38, 220), outline=(0, 210, 255, 120), width=2)

# Card 2: Optical Dark Chamber CIE 45°/0° & Vis-NIR 7-Channels
card2_box = [(spectra_pos[0] + 620, badge_y + 160), (spectra_pos[0] + spectra_w - 20, badge_y + 310)]
hud_draw.rounded_rectangle(card2_box, radius=14, fill=(11, 20, 38, 220), outline=(255, 183, 77, 130), width=2)

# 6. Typography with PIL Fonts
font_path = '/System/Library/Fonts/Supplemental/Thonburi.ttc'
font_badge = ImageFont.truetype(font_path, 24, index=1)
font_main_super = ImageFont.truetype(font_path, 36, index=1)
font_main_th = ImageFont.truetype(font_path, 42, index=1)
font_main_sub = ImageFont.truetype(font_path, 25, index=0)
font_hud_title = ImageFont.truetype(font_path, 26, index=1)
font_hud_desc = ImageFont.truetype(font_path, 21, index=0)
font_authors = ImageFont.truetype(font_path, 42, index=1)
font_univ = ImageFont.truetype(font_path, 28, index=1)
font_year = ImageFont.truetype(font_path, 24, index=2)

# Top Bar Header (RBRU Unit)
font_faculty = ImageFont.truetype(font_path, 22, index=0)
hud_draw.text((90, 75), "หน่วยวิจัยปัญญาประดิษฐ์เพื่อเกษตรดิจิทัล", font=font_badge, fill=(245, 197, 66, 255))
hud_draw.text((90, 110), "คณะวิทยาศาสตร์และเทคโนโลยี มหาวิทยาลัยราชภัฏรำไพพรรณี", font=font_faculty, fill=(203, 213, 225, 220))

# Tech Pill Tag on Top Right
pill_box = [(W - 480, 75), (W - 90, 125)]
hud_draw.rounded_rectangle(pill_box, radius=25, fill=(0, 230, 153, 35), outline=(0, 230, 153, 200), width=2)
hud_draw.text((W - 440, 88), "AIoT • VIS-NIR • 0-LUX", font=font_badge, fill=(0, 230, 153, 255))

# Main Book Title Section
hud_draw.text((90, 195), "คู่มือระบบและเอกสารวิจัยฉบับสมบูรณ์", font=font_main_super, fill=(255, 255, 255, 255))

title_th_line1 = "การพัฒนาชุดวิเคราะห์ปริมาณไนโตรเจนและฟอสฟอรัสในดินแบบพกพา"
title_th_line2 = "ด้วยหลักการสะท้อนแสงร่วมกับปัญญาประดิษฐ์ (NPxAI)"
hud_draw.text((90, 255), title_th_line1, font=font_main_th, fill=(245, 197, 66, 255))
hud_draw.text((90, 320), title_th_line2, font=font_main_th, fill=(245, 197, 66, 255))

title_en = "Development of a Portable Soil Nitrogen and Phosphorus Analyzer using Reflectance Principle Integrated with AI"
hud_draw.text((90, 388), title_en, font=font_main_sub, fill=(148, 163, 184, 255))

# Golden Accent Divider
hud_draw.line([(90, 440), (W - 90, 440)], fill=(245, 197, 66, 200), width=3)
hud_draw.line([(90, 446), (W - 90, 446)], fill=(0, 230, 153, 160), width=1)

# Badge Texts in HUD area
hud_draw.text((spectra_pos[0] + 30, badge_y + 20), "การวิเคราะห์ผลสัมฤทธิ์ธาตุอาหารพืช N-P และลายพิมพ์สเปกตรัม Vis-NIR", font=font_hud_title, fill=(0, 230, 153, 255))
hud_draw.text((spectra_pos[0] + 30, badge_y + 65), "Total N (Kjeldahl): 3.20 g/kg • Available P (Bray II): 30.29 mg/kg • ความเชื่อมั่น R²: 0.96", font=font_hud_desc, fill=(226, 232, 240, 240))

# Card 1 Content (Soil-ViT & Edge AI)
hud_draw.text((card1_box[0][0] + 25, card1_box[0][1] + 20), "โมเดลปัญญาประดิษฐ์ Soil-ViT & AI", font=font_hud_title, fill=(0, 210, 255, 255))
hud_draw.text((card1_box[0][0] + 25, card1_box[0][1] + 65), "Vision Transformer • CNN ResNet-18 • RF\nความแม่นยำสูงระดับแปลงเกษตรกรรมแบบเวลาจริง", font=font_hud_desc, fill=(203, 213, 225, 220))

# Card 2 Content (Optics)
hud_draw.text((card2_box[0][0] + 25, card2_box[0][1] + 20), "ลายพิมพ์สเปกตรัมและกล่องมืด 0-Lux", font=font_hud_title, fill=(255, 183, 77, 255))
hud_draw.text((card2_box[0][0] + 25, card2_box[0][1] + 65), "เรขาคณิต CIE 45°/0° • LED 7 แชนเนล\nตรวจวัดช่วงคลื่น 405, 465, 525, 630, 850, 940 nm", font=font_hud_desc, fill=(203, 213, 225, 220))

# Bottom Authors & Publisher Section
author_box_top = H - 280
hud_draw.line([(90, author_box_top - 30), (W - 90, author_box_top - 30)], fill=(0, 230, 153, 80), width=2)

# Authors center
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
print(f"Successfully generated futuristic master book cover: {output_cover_path}")
