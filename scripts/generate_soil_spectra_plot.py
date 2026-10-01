import os
os.environ['MPLCONFIGDIR'] = '/tmp/mpl_config'
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np

# Set Thai font
plt.rcParams['font.family'] = 'Sarabun'
plt.rcParams['axes.unicode_minus'] = False

# Wavelength array from 350 to 2500 nm
wl = np.linspace(350, 2500, 2151)

def gaussian(x, mu, sig, amp):
    return amp * np.exp(-0.5 * ((x - mu) / sig) ** 2)

# 1. Base Organic Matter / Soil Matrix background curve (high in UV-Vis, decaying in NIR/SWIR)
base_som = 1.35 * np.exp(-(wl - 350) / 450) + 0.28 + 0.00008 * (wl - 1000)

# 2. Water / Moisture peaks (960, 1450, 1940 nm)
water_960 = gaussian(wl, 960, 45, 0.08)
water_1450 = gaussian(wl, 1450, 60, 0.52)
water_1940 = gaussian(wl, 1940, 70, 0.95)
water_curve = water_960 + water_1450 + water_1940

# 3. Iron Oxides (Goethite & Hematite) bound with Available Phosphorus
fe_goethite_480 = gaussian(wl, 480, 40, 0.22)
fe_hematite_550 = gaussian(wl, 550, 45, 0.18)
fe_hematite_880 = gaussian(wl, 880, 65, 0.16)
fe_goethite_920 = gaussian(wl, 920, 70, 0.20)
iron_oxides_p = fe_goethite_480 + fe_hematite_550 + fe_hematite_880 + fe_goethite_920

# 4. Total Nitrogen (N-H) peaks (1510, 2060, 2180 nm)
n_1510 = gaussian(wl, 1510, 22, 0.09)
n_2060 = gaussian(wl, 2060, 25, 0.11)
n_2180 = gaussian(wl, 2180, 28, 0.14)
nitrogen_curve = n_1510 + n_2060 + n_2180

# 5. Carbon / SOM (C-H) peaks (1180, 1720, 2310, 2350 nm)
ch_1180 = gaussian(wl, 1180, 30, 0.05)
ch_1720 = gaussian(wl, 1720, 35, 0.12)
ch_2310 = gaussian(wl, 2310, 22, 0.15)
ch_2350 = gaussian(wl, 2350, 25, 0.13)
carbon_curve = ch_1180 + ch_1720 + ch_2310 + ch_2350

# 6. Clay minerals & Potassium proxy (Al-OH, Illite: 1410, 2206 nm)
clay_1410 = gaussian(wl, 1410, 20, 0.08)
clay_2206 = gaussian(wl, 2206, 25, 0.24)
clay_2340 = gaussian(wl, 2340, 20, 0.10)
clay_k_curve = clay_1410 + clay_2206 + clay_2340

# Total Composite Soil Absorbance
total_absorbance = base_som + water_curve + iron_oxides_p + nitrogen_curve + carbon_curve + clay_k_curve

# Create publication-quality figure
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(15, 10.5), gridspec_kw={'height_ratios': [3.6, 1.2]}, dpi=300)
fig.patch.set_facecolor('#FFFFFF')

# Upper Plot: Soil Spectral Absorbance
ax1.set_facecolor('#FCFDFE')

# Highlight Spectral Regions with pastel backgrounds
ax1.axvspan(350, 400, color='#EDE7F6', alpha=0.6, label='_nolegend_') # UV
ax1.axvspan(400, 700, color='#E8F5E9', alpha=0.5, label='_nolegend_') # Visible
ax1.axvspan(700, 1100, color='#E1F5FE', alpha=0.5, label='_nolegend_') # Short-NIR
ax1.axvspan(1100, 2500, color='#FFF8E1', alpha=0.5, label='_nolegend_') # SWIR

# Plot background components (subtle dashed curves)
ax1.plot(wl, total_absorbance, color='#1A237E', lw=2.8, label='สเปกตรัมการดูดกลืนรวมของดิน (Total Soil Absorbance Spectrum)')
ax1.plot(wl, base_som + water_curve, color='#0288D1', lw=1.2, ls='--', alpha=0.7, label='แถบการดูดกลืนของน้ำ/ความชื้น (Moisture H₂O)')
ax1.plot(wl, base_som + iron_oxides_p, color='#D84315', lw=1.2, ls=':', alpha=0.75, label='สารประกอบเหล็กออกไซด์ที่ตรึงฟอสฟอรัส (Fe-Oxides & Ava P)')
ax1.plot(wl, base_som + nitrogen_curve + carbon_curve, color='#2E7D32', lw=1.2, ls='-.', alpha=0.75, label='สารอินทรีย์และไนโตรเจน (Organic C-H & N-H)')

# Region Labels on top
ax1.text(375, 2.62, 'UV\n(350-400 nm)', ha='center', va='center', fontsize=9.5, fontweight='bold', color='#5E35B1')
ax1.text(550, 2.62, 'แสงที่ตามองเห็น (Visible)\n(400-700 nm)', ha='center', va='center', fontsize=10, fontweight='bold', color='#2E7D32')
ax1.text(900, 2.62, 'อินฟราเรดย่านใกล้ (Short-NIR)\nขีดจำกัดกล้องสมาร์ทโฟน CMOS (700-1100 nm)', ha='center', va='center', fontsize=9.5, fontweight='bold', color='#0277BD')
ax1.text(1550, 2.62, 'อินฟราเรดย่านคลื่นสั้น (Short-Wave Infrared: SWIR)\n(1100-2500 nm)', ha='center', va='center', fontsize=10, fontweight='bold', color='#E65100')

# Specific Key Absorption Callouts
def add_peak_callout(ax, x, y, text, color, xytext=(0, 25), ha='center'):
    ax.annotate(text, xy=(x, y), xytext=xytext, textcoords='offset points',
                arrowprops=dict(arrowstyle="->", color=color, lw=1.2, shrinkA=3, shrinkB=3),
                fontsize=8.5, fontweight='bold', color=color, ha=ha,
                bbox=dict(boxstyle="round,pad=0.25", fc="#FFFFFF", ec=color, lw=0.9, alpha=0.92))

# Nitrogen Callouts
add_peak_callout(ax1, 1510, total_absorbance[np.argmin(np.abs(wl - 1510))], r'Total N ($2\nu$ N-H)' + '\n1510 nm', '#1B5E20', (0, 32))
add_peak_callout(ax1, 2060, total_absorbance[np.argmin(np.abs(wl - 2060))], 'Total N (N-H Comb)\n2060 nm', '#1B5E20', (-25, 45), ha='right')
add_peak_callout(ax1, 2180, total_absorbance[np.argmin(np.abs(wl - 2180))], 'Total N (Protein N-H)\n2180 nm', '#1B5E20', (25, 48), ha='left')

# Phosphorus & Iron Oxide Callouts
add_peak_callout(ax1, 480, total_absorbance[np.argmin(np.abs(wl - 480))], 'Ava P (Goethite)\n480 nm', '#C62828', (0, 28))
add_peak_callout(ax1, 550, total_absorbance[np.argmin(np.abs(wl - 550))], 'Ava P (Hematite)\n550 nm', '#C62828', (0, 30))
add_peak_callout(ax1, 880, total_absorbance[np.argmin(np.abs(wl - 880))], r'Ava P (Fe$^{3+}$ Hematite)' + '\n880 nm', '#C62828', (-20, 35), ha='right')
add_peak_callout(ax1, 920, total_absorbance[np.argmin(np.abs(wl - 920))], r'Ava P (Fe$^{3+}$ Goethite)' + '\n920 nm', '#C62828', (25, 35), ha='left')

# Water Callouts
add_peak_callout(ax1, 960, total_absorbance[np.argmin(np.abs(wl - 960))], r'H$_2$O ($3\nu$ O-H)' + '\n960 nm', '#0277BD', (0, -35))
add_peak_callout(ax1, 1450, total_absorbance[np.argmin(np.abs(wl - 1450))], r'H$_2$O ($2\nu$ O-H)' + '\n1450 nm', '#0277BD', (0, 32))
add_peak_callout(ax1, 1940, total_absorbance[np.argmin(np.abs(wl - 1940))], r'พีคความชื้น H$_2$O ($\nu_2+\nu_3$)' + '\n1940 nm', '#01579B', (0, 35))

# Carbon / SOM Callouts
add_peak_callout(ax1, 1180, total_absorbance[np.argmin(np.abs(wl - 1180))], r'SOM ($3\nu$ C-H)' + '\n1180 nm', '#4E342E', (0, 25))
add_peak_callout(ax1, 1720, total_absorbance[np.argmin(np.abs(wl - 1720))], r'SOM/SOC ($2\nu$ C-H)' + '\n1720 nm', '#4E342E', (0, 28))
add_peak_callout(ax1, 2310, total_absorbance[np.argmin(np.abs(wl - 2310))], 'Humic C-H Comb\n2310 nm', '#4E342E', (-20, 35), ha='right')

# Clay & Potassium Callouts
add_peak_callout(ax1, 2206, total_absorbance[np.argmin(np.abs(wl - 2206))], 'Kaolinite Al-OH / Ava K\n2206 nm', '#6A1B9A', (0, -38))

ax1.set_xlim(350, 2500)
ax1.set_ylim(0.2, 2.85)
ax1.set_ylabel('ค่าการดูดกลืนแสงเชิงสัมพัทธ์ (Relative Absorbance: log(1/R))', fontsize=11, fontweight='bold', color='#1A237E')
ax1.set_title('สเปกตรัมการดูดกลืนคลื่นของธาตุอาหารหลักและองค์ประกอบในดิน (Soil Plant Nutrient Absorption Spectra)\nอ้างอิงตามมาตรฐานการวิเคราะห์ Vis-NIR-SWIR ทางปฐพีวิทยาระดับสากล', fontsize=13, fontweight='bold', pad=14, color='#0D47A1')
ax1.grid(True, ls=':', color='#CFD8DC', alpha=0.7)
ax1.legend(loc='upper right', framealpha=0.92, edgecolor='#B0BEC5', fontsize=9)

# Lower Plot: NPxAI Multi-Spectral LED Channels
ax2.set_facecolor('#F8F9FA')

led_channels = [
    (405, 12, '#673AB7', 'UV 405 nm\n(SOM/Humic)', 1.05),
    (465, 16, '#1976D2', 'Blue 465 nm\n(Clay Texture)', 1.25),
    (525, 18, '#388E3C', 'Green 525 nm\n(Munsell Hue)', 1.05),
    (630, 20, '#D32F2F', 'Red 630 nm\n(Chlorophyll/Fe)', 1.25),
    (850, 25, '#880E4F', 'NIR-I 850 nm\n(Hematite/Fe-III)', 1.15),
    (940, 28, '#4A148C', 'NIR-II 940 nm\n(Goethite/H2O/P)', 1.15)
]

for peak, width, col, label, y_txt in led_channels:
    led_intensity = gaussian(wl, peak, width, 1.0)
    ax2.plot(wl, led_intensity, color=col, lw=2.0)
    ax2.fill_between(wl, 0, led_intensity, color=col, alpha=0.35)
    ax2.annotate(label, xy=(peak, 1.0), xytext=(0, (y_txt - 1.0) * 80 + 5), textcoords='offset points',
                 ha='center', fontsize=7.8, fontweight='bold', color=col)

# Silicon CMOS Spectral Response Curve
cmos_response = np.exp(-((wl - 550) / 220) ** 2) * (wl <= 1000)
ax2.plot(wl[wl <= 1050], cmos_response[wl <= 1050] * 0.85, color='#455A64', ls='--', lw=1.6, label='ช่วงตอบสนองของเซนเซอร์สมาร์ทโฟน CMOS (Silicon Responsivity)')

ax2.set_xlim(350, 2500)
ax2.set_ylim(0, 1.45)
ax2.set_xlabel('ความยาวคลื่นแม่เหล็กไฟฟ้า (Wavelength: nm)', fontsize=11, fontweight='bold', color='#1A237E')
ax2.set_ylabel('ความเข้มสัมพัทธ์\n(Relative Intensity)', fontsize=9.5, fontweight='bold')
ax2.set_title('สถาปัตยกรรมแถบคลื่นกระตุ้นแสงแบบมัลติสเปกตรัมในระบบ NPxAI Dark Chamber (405 - 940 nm)', fontsize=11, fontweight='bold', color='#1A237E', pad=8)
ax2.grid(True, ls=':', color='#CFD8DC', alpha=0.7)
ax2.legend(loc='upper right', framealpha=0.9, edgecolor='#B0BEC5', fontsize=8.5)

plt.tight_layout()
output_path = '/Applications/XAMPP/xamppfiles/htdocs/06_AI_Research/NPxAI/docs/manual/figures/soil_nutrient_absorption_spectra.png'
plt.savefig(output_path, dpi=300, bbox_inches='tight')
print(f"Successfully generated: {output_path}")
