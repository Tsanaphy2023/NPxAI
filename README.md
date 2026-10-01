# NPxAI: Smart Soil Nitrogen & Phosphorus Analyzer with Edge AI

**ระบบแอปพลิเคชันวิเคราะห์ปริมาณไนโตรเจนและฟอสฟอรัสในดินแบบพกพาด้วยหลักการสะท้อนแสงร่วมกับปัญญาประดิษฐ์**  
*(Development of a Portable Soil Nitrogen and Phosphorus Analyzer using Reflectance Principle Integrated with Artificial Intelligence)*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Edge AI](https://img.shields.io/badge/Edge%20AI-Deep%20Learning-007A4D)](https://github.com/Tsanaphy2023/NPxAI)
[![3D CAD](https://img.shields.io/badge/3D%20CAD-OpenSCAD%20%2F%20STL-F58025)](https://github.com/Tsanaphy2023/NPxAI/tree/main/hardware_3d_cad)
[![GitHub](https://img.shields.io/badge/GitHub-Tsanaphy2023%2FNPxAI-181717?logo=github)](https://github.com/Tsanaphy2023/NPxAI)

โครงการวิจัยเสนอของบประมาณกองทุนวิจัย มหาวิทยาลัยราชภัฏรำไพพรรณี ประจำปีงบประมาณ พ.ศ. 2569  
ภายใต้แผนงานวิจัย: *การบูรณาการเทคโนโลยีจุลชีววิทยาและปัญญาประดิษฐ์เพื่อการจัดการธาตุอาหารพืชอย่างยั่งยืนในพื้นที่เกษตรกรรมจังหวัดจันทบุรี*  
**คลังรหัสต้นฉบับบน GitHub:** [https://github.com/Tsanaphy2023/NPxAI](https://github.com/Tsanaphy2023/NPxAI)

---

## 1. การบูรณาการ 2 โครงการย่อย (Research Integration)

```text
+----------------------------------------------------------------------------------+
| แผนงานหลัก: การจัดการธาตุอาหาร N/P อย่างยั่งยืนบนฐานข้อมูล (SDG 2, 9, 12)        |
+----------------------------------------------------------------------------------+
                                        │
             ┌──────────────────────────┴──────────────────────────┐
             ▼                                                     ▼
┌──────────────────────────────┐              ┌──────────────────────────────┐
│ โครงการย่อยที่ 1 (จุลชีววิทยา)│              │ โครงการย่อยที่ 2 (AI/เทคโนโลยี)│
│ ผศ.ดร.จิรภัทร จันทมาลี      │              │ ผศ.ดร.ชีวะ ทัศนา             │
│ • คัดแยกแบคทีเรียละลาย P (PSB)│              │ • 3D Printed Chamber & LED   │
│ • คัดแยกแบคทีเรียตรึง N (NFB) │              │ • Reflectance Spectroscopy   │
│ • ฐานข้อมูลสายพันธุ์ท้องถิ่น │              │ • Edge AI: Deep Learning     │
│ • ชีวภัณฑ์จุลินทรีย์ 6-10 สายพันธุ์           │ • Mobile Flutter Application │
└──────────────┬───────────────┘              └──────────────┬───────────────┘
               │                                             │
               └──────────────────────┬──────────────────────┘
                                      ▼
             ┌─────────────────────────────────────────────────┐
             │       NPxAI Mobile Edge Application             │
             │ - วัด Total N (g/kg) & Available P (mg/kg)      │
             │ - ปุ๋ยเคมีสั่งตัด + ชีวภัณฑ์จุลินทรีย์ท้องถิ่น PSB/NFB │
             │ - ลดการใช้ปุ๋ยเคมี 10-35% และลดมลพิษทางดินและน้ำ│
             └─────────────────────────────────────────────────┘
```

---

## 2. โครงสร้างโมเดล 3 มิติเชิงแสง (Optical Dark Chamber 3D CAD)

ไฟล์โมเดลสามมิติสำหรับการพิมพ์ 3 มิติ (3D Printing) ทั้งหมด ถูกจัดเก็บในโฟลเดอร์ [`hardware_3d_cad/`](hardware_3d_cad/):

- **`npxai_dark_chamber_body.stl`** (135 KB): ตัวเรือนกล่องมืด Working Distance 55mm พร้อมครีบดักแสง Baffles และช่องติดตั้ง LED 45°
- **`npxai_smartphone_mount_adapter.stl`** (40.9 KB): แท่นประกบสมาร์ทโฟน ร่องซีลโอริง/โฟม EVA ป้องกันแสงรั่ว 0 Lux
- **`npxai_soil_sample_drawer.stl`** (23.1 KB): ลิ้นชักเลื่อนสไลด์บรรจุถาดดินมาตรฐาน (Ø35mm ลึก 8mm) พร้อมแม่เหล็กดูดล็อก
- **`npxai_soil_leveler_press.stl`** (22.7 KB): ลูกสูบเกลี่ยหน้าดินเรียบสม่ำเสมอ (Ø34mm)
- **`npxai_dark_chamber_assembly.scad`** (13.5 KB): ซอร์สโค้ด OpenSCAD ปรับแต่งขนาดพารามิเตอร์ได้
- **`viewer_3d.html`** (11.5 KB): เว็บแอปพลิเคชัน Three.js สำหรับเปิดหมุนดูโมเดล 360 องศา และภาพแยกชิ้นส่วน

---

## 3. สถาปัตยกรรมซอฟต์แวร์ (Software Architecture v1.2.0)

พัฒนาตามมาตรฐาน **`flutter-apply-architecture-best-practices`** และ **`soil-pht-aiot-architect`**:

```text
lib/
├── data/
│   ├── models/                  # ข้อมูล DTO และ Data Transfer Objects
│   ├── repositories/            # SoilRepositoryImpl, MicrobeRepositoryImpl
│   └── services/                # HardwareChamberService, CameraVisionService, StorageExportService
├── domain/
│   ├── models/                  # SpectralSignature, SoilSample, NutrientPrediction, BioFertilizerRecommendation
│   └── use_cases/               # ColorNormalizationUseCase, EdgeAiInferenceUseCase, IntegratedAdvisorUseCase
└── ui/
    ├── core/                    # AppTheme (Scientific Dark Green), TelemetryHud, NutrientGaugeCard, SpectralCanvas
    ├── features/
    │   ├── connection/          # ค้นหาและเชื่อมต่อ Chamber (BLE, USB-C OTG, Simulator)
    │   ├── scanner/             # จอสแกนสด + พิกัด GPS + 3 ปุ่มคำสั่ง (สแกน/ภาพ/วิดีโอ) + สลับโมเดล AI
    │   ├── result/              # รายงานผล Total N & Available P แบบแยกบรรทัดชัดเจน + กราฟ Vis-NIR
    │   └── advisor/             # คำแนะนำปุ๋ยเคมีสั่งตัดร่วมกับชีวภัณฑ์จุลินทรีย์ดิน (PSB & NFB)
    └── main_shell_view.dart     # Navigation Bar และ WidgetsBindingObserver (Port Claim / Release)
```

---

## 4. แบบจำลองปัญญาประดิษฐ์บนขอบ (Multi-Model Edge AI)

ระบบรองรับการสลับและเลือกโมเดลการเรียนรู้เชิงลึก (Deep Learning Models) สำหรับการวิเคราะห์หน้างาน:
1. **`SIMULATION`**: โมเดลจำลองมาตรฐานอ้างอิง RBRU Soil Spectral Baseline ($R^2 \approx 0.91$)
2. **`MobileNetV4-Soil`**: โมเดล Edge Inverted Bottleneck เน้นดัชนีผลต่างสเปกตรัม Vis-NIR ($R^2 \approx 0.89 - 0.92$)
3. **`EfficientNet-B0`**: โมเดล Compound Scaling ตอบสนองต่อสารอินทรีย์ฮิวมัสและความเข้มสีดิน ($R^2 \approx 0.93 - 0.94$)
4. **`Soil-ViT`**: Vision Transformer คำนวณ Self-Attention ของผลึกฟอสเฟตย่าน 940 nm ($R^2 \approx 0.95$)
5. **`ResNet18-DualBranch`**: โครงข่าย Dual-Branch ผสานภาพถ่ายสี RGB ร่วมกับแถบสเปกตรัมหลายย่านคลื่น ($R^2 \approx 0.96 - 0.97$)

---

## 5. คู่มือและเอกสารทางวิชาการ (Documentation)

- **คู่มือระบบฉบับสมบูรณ์ (Markdown):** [`docs/manual/NPxAI_Complete_Guidebook.md`](docs/manual/NPxAI_Complete_Guidebook.md)
- **เอกสารคู่มือตำราฉบับสมบูรณ์ (XeLaTeX / PDF):** [`docs/manual/NPxAI_System_Manual.tex`](docs/manual/NPxAI_System_Manual.tex)
- **คู่มือการพิมพ์ 3 มิติและการประกอบกล่อง:** [`docs/manual/npxai_3d_dark_chamber_cad_manual.md`](docs/manual/npxai_3d_dark_chamber_cad_manual.md)

---

## 6. ผู้รับผิดชอบโครงการวิจัย

- **หัวหน้าโครงการวิจัย:** ผศ.ดร.ชีวะ ทัศนา (หลักสูตร คบ.ฟิสิกส์ คณะวิทยาศาสตร์และเทคโนโลยี มหาวิทยาลัยราชภัฏรำไพพรรณี)
- **ผู้อำนวยการแผนงาน / ผู้ร่วมวิจัย:** ผศ.ดร.จิรภัทร จันทมาลี (หลักสูตร วท.บ.จุลชีววิทยา)
- **ผู้ร่วมวิจัย:** ผศ.ดร.วิกันยา ประทุมยศ (คณะเทคโนโลยีการเกษตร)
