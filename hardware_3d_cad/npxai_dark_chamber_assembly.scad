// ==============================================================================
// โครงการวิจัย: NPxAI - เครื่องวิเคราะห์ไนโตรเจนและฟอสฟอรัสในดินแบบพกพาด้วยสเปกตรัมร่วมกับปัญญาประดิษฐ์
// ออกแบบโดย: ผศ.ดร.ชีวะ ทัศนา และ ผศ.ดร.จิรภัทร จันทมาลี
// หน่วยวิจัยปัญญาประดิษฐ์เพื่อเกษตรดิจิทัล คณะวิทยาศาสตร์และเทคโนโลยี มหาวิทยาลัยราชภัฏรำไพพรรณี (RBRU)
// ชิ้นงาน: 3D Model Optical Dark Chamber & Smartphone Clamp Adapter (OpenSCAD Parametric)
// ==============================================================================

/* [การเลือกชิ้นส่วนที่ต้องการเรนเดอร์ (Render Target)] */
part = "all"; // [all:ประกอบรวมทั้งหมด, body:ตัวเรือนกล่องมืด, adapter:แท่นประกบสมาร์ทโฟน, drawer:ลิ้นชักถาดใส่ดิน, press:ลูกสูบเกลี่ยหน้าดิน, exploded:มุมมองแยกชิ้นส่วน]

/* [พารามิเตอร์เชิงแสงและกลศาสตร์ (Optical & Mechanical Parameters)] */
$fn = 64; // ความละเอียดของส่วนโค้งวงกลม

// ขนาดภายนอกของตัวเรือนกล่องมืด (Dark Chamber Outer Dimensions)
chamber_width  = 80.0; // มิลลิเมตร (แกน X)
chamber_depth  = 70.0; // มิลลิเมตร (แกน Y)
chamber_height = 55.0; // มิลลิเมตร (แกน Z - Working Distance จากกล้องถึงหน้าดิน)
wall_thickness = 3.0;  // ความหนาผนังทึบแสงป้องกันแสงรั่ว (Light-tight Wall)

// พารามิเตอร์ช่องรับภาพเลนส์กล้อง (Optical Aperture)
aperture_dia   = 20.0; // ช่องรับภาพสำหรับเลนส์กล้องหลักสมาร์ทโฟน
gasket_groove_dia = 28.0; // ร่องใส่โอริงหรือโฟม EVA กั้นแสงรั่ว
gasket_depth   = 1.5;

// พารามิเตอร์ลิ้นชักใส่ตัวอย่างดิน (Soil Cassette Drawer)
drawer_width   = 42.0;
drawer_height  = 16.0;
drawer_length  = 75.0;
drawer_clearance = 0.4; // ระยะเผื่อสไลด์หลวมกำลังดีสำหรับการพิมพ์ 3 มิติ

// หลุมใส่ถาดดิน (Soil Cup / Petri Dish Well)
soil_well_dia  = 35.0; // เส้นผ่านศูนย์กลางหลุมใส่ดิน
soil_well_depth= 8.0;  // ความลึกของดิน

// รูยึดน็อต M3 (M3 Screw & Heat-set Insert Holes)
screw_m3_dia   = 3.2;
screw_spacing_x= chamber_width - 12;
screw_spacing_y= chamber_depth - 12;

// รูติดตั้งหลอด LED 45 องศา (7 LEDs: White, 405, 465, 525, 630, 850, 940 nm)
led_hole_dia   = 5.2; // สำหรับหลอด LED 5mm
led_pitch_dia  = 44.0; // เส้นผ่านศูนย์กลางวงแหวน LED
led_angle_deg  = 45.0; // มุมส่องตกกระทบ 45 องศาตามมาตรฐาน CIE 45/0

// ==============================================================================
// 1. โมดูล: ตัวเรือนกล่องมืด (Dark Chamber Body)
// ==============================================================================
module dark_chamber_body() {
    difference() {
        // เปลือกนอกกล่องทรงสี่เหลี่ยมขอบมน
        translate([0, 0, chamber_height / 2])
            rounded_box([chamber_width, chamber_depth, chamber_height], 5);

        // โพรงทางเดินแสงทรงกรวยปิรามิดตัดยอด (Internal Optical Tapered Cavity)
        translate([0, 0, -1])
            cylinder(h = chamber_height + 2, r1 = (soil_well_dia + 12) / 2, r2 = (aperture_dia + 6) / 2);

        // ครีบวงแหวนดักแสงสะท้อนภายใน (Internal Anti-Reflection Baffles)
        for (z = [12, 22, 32, 42]) {
            translate([0, 0, z])
                difference() {
                    cylinder(h = 2.0, r = 26, center = false);
                    cylinder(h = 2.1, r = 21, center = false);
                }
        }

        // รางสไลด์ลิ้นชักใส่ตัวอย่างดินด้านล่าง (Bottom Drawer Slide Tunnel)
        translate([0, 0, drawer_height / 2 + 1.5])
            cube([drawer_width + drawer_clearance * 2, chamber_depth + 4, drawer_height + drawer_clearance * 2], center = true);

        // รูติดตั้งหลอด LED 7 ดวง ทำมุม 45 องศา (45-degree Multi-Spectral LED Ports)
        for (i = [0 : 6]) {
            rotate([0, 0, i * (360 / 7)])
                translate([led_pitch_dia / 2, 0, 24])
                    rotate([0, -led_angle_deg, 0])
                        cylinder(h = 25, r = led_hole_dia / 2, center = true);
        }

        // ช่องใส่แผ่นเทียบสีขาวมาตรฐาน (Internal White Reference Slot 10x10mm)
        translate([18, 18, 12])
            cube([10.5, 10.5, 3], center = true);

        // รูเกลียวน็อต M3 ยึดฝาบน 4 มุม (Top Mounting Screw Holes)
        for (dx = [-screw_spacing_x / 2, screw_spacing_x / 2]) {
            for (dy = [-screw_spacing_y / 2, screw_spacing_y / 2]) {
                translate([dx, dy, chamber_height - 12])
                    cylinder(h = 15, r = screw_m3_dia / 2);
            }
        }

        // รูฝังแม่เหล็กนีโอไดเมียมล็อกลิ้นชัก (Drawer Magnetic Lock Pocket 5x2mm)
        translate([0, -chamber_depth / 2 + wall_thickness + 1, drawer_height / 2 + 1.5])
            rotate([90, 0, 0])
                cylinder(h = 3, r = 2.6);
    }
}

// ==============================================================================
// 2. โมดูล: แท่นประกบสมาร์ทโฟน (Smartphone Mount Adapter Lid)
// ==============================================================================
module smartphone_adapter() {
    adapter_h = 10.0;
    lip_h     = 5.0;
    
    difference() {
        union() {
            // แผ่นฐานประกบกล่อง
            translate([0, 0, adapter_h / 2])
                rounded_box([chamber_width, chamber_depth, adapter_h], 5);
            
            // ขอบสันล็อกสมาร์ทโฟน (Side Alignment Guides)
            translate([-chamber_width / 2 + 3, 0, adapter_h + lip_h / 2])
                cube([6, chamber_depth, lip_h], center = true);
            translate([chamber_width / 2 - 3, 0, adapter_h + lip_h / 2])
                cube([6, chamber_depth, lip_h], center = true);
        }

        // ช่องแสงหลักตรงเลนส์กล้องสมาร์ทโฟน (Central Optical Aperture)
        translate([0, 0, -1])
            cylinder(h = adapter_h + lip_h + 2, r = aperture_dia / 2);

        // ร่องซีลโอริง / โฟมกั้นแสงรั่ว (O-Ring / Foam Light-Lock Recess)
        translate([0, 0, adapter_h - gasket_depth])
            difference() {
                cylinder(h = gasket_depth + 1, r = gasket_groove_dia / 2);
                cylinder(h = gasket_depth + 1, r = (aperture_dia + 2) / 2);
            }

        // รูร้อยน็อต M3 เตเปอร์ 4 มุม (Countersunk M3 Screw Holes)
        for (dx = [-screw_spacing_x / 2, screw_spacing_x / 2]) {
            for (dy = [-screw_spacing_y / 2, screw_spacing_y / 2]) {
                translate([dx, dy, -1]) {
                    cylinder(h = adapter_h + 2, r = screw_m3_dia / 2);
                    translate([0, 0, adapter_h - 2])
                        cylinder(h = 4, r1 = screw_m3_dia / 2, r2 = 3.3);
                }
            }
        }
    }
}

// ==============================================================================
// 3. โมดูล: ลิ้นชักถาดใส่ตัวอย่างดิน (Soil Cassette Drawer)
// ==============================================================================
module soil_drawer() {
    difference() {
        union() {
            // ตัวลิ้นชักเลื่อนสไลด์
            translate([0, 0, drawer_height / 2])
                rounded_box([drawer_width, drawer_length, drawer_height], 3);

            // มือจับลิ้นชักด้านหน้า (Front Ergonomic Pull Handle)
            translate([0, drawer_length / 2 + 5, drawer_height / 2])
                rounded_box([drawer_width + 8, 10, drawer_height + 4], 4);
        }

        // หลุมทรงกระบอกใส่ถาดดิน (Soil Well Bed)
        translate([0, -2, drawer_height - soil_well_depth + 0.1])
            cylinder(h = soil_well_depth + 1, r = soil_well_dia / 2);

        // รูฝังแม่เหล็กด้านท้ายลิ้นชัก (Rear Magnetic Lock 5x2mm)
        translate([0, -drawer_length / 2 + 1.5, drawer_height / 2])
            rotate([90, 0, 0])
                cylinder(h = 3, r = 2.6);

        // สลักตัวอักษร RBRU NPxAI ที่หน้ามือจับ
        translate([0, drawer_length / 2 + 9.5, drawer_height / 2 - 2])
            rotate([90, 0, 0])
                linear_extrude(height = 1.0)
                    text("NPxAI", size = 4.5, halign = "center", font = "Liberation Sans:style=Bold");
    }
}

// ==============================================================================
// 4. โมดูล: ลูกสูบเกลี่ยหน้าดินเรียบ (Soil Surface Leveler & Press Tool)
// ==============================================================================
module soil_press() {
    press_dia   = soil_well_dia - 0.8;
    press_thick = 5.0;
    knob_dia    = 18.0;
    knob_height = 20.0;

    union() {
        // แผ่นกดหน้าดินเรียบ (Flat Pressing Disc)
        cylinder(h = press_thick, r = press_dia / 2);
        
        // ก้านจับและหัวหมุนลายหยัก (Knurled Grip Handle)
        translate([0, 0, press_thick])
            cylinder(h = knob_height, r = knob_dia / 2);
            
        translate([0, 0, press_thick + knob_height])
            sphere(r = knob_dia / 2);
    }
}

// ==============================================================================
// ฟังก์ชันช่วย: กล่องสี่เหลี่ยมขอบมน (Rounded Box Helper)
// ==============================================================================
module rounded_box(size, radius) {
    x = size[0] - radius * 2;
    y = size[1] - radius * 2;
    z = size[2];
    hull() {
        translate([-x / 2, -y / 2, -z / 2]) cylinder(h = z, r = radius);
        translate([ x / 2, -y / 2, -z / 2]) cylinder(h = z, r = radius);
        translate([-x / 2,  y / 2, -z / 2]) cylinder(h = z, r = radius);
        translate([ x / 2,  y / 2, -z / 2]) cylinder(h = z, r = radius);
    }
}

// ==============================================================================
// ตรรกะการเรนเดอร์ชิ้นงานตามตัวเลือก (Assembly & Rendering Switch)
// ==============================================================================
if (part == "all") {
    // เรนเดอร์แบบประกอบรวมพร้อมใช้งาน
    color([0.2, 0.2, 0.2, 0.95]) dark_chamber_body();
    translate([0, 0, chamber_height])
        color([0.15, 0.45, 0.25, 0.95]) smartphone_adapter();
    translate([0, 0, 1.5])
        color([0.3, 0.3, 0.35, 1.0]) soil_drawer();
} else if (part == "body") {
    dark_chamber_body();
} else if (part == "adapter") {
    smartphone_adapter();
} else if (part == "drawer") {
    soil_drawer();
} else if (part == "press") {
    soil_press();
} else if (part == "exploded") {
    // มุมมองแยกชิ้นส่วนสำหรับจัดทำคู่มือและรายงานวิจัย (Exploded View)
    dark_chamber_body();
    translate([0, 0, chamber_height + 25])
        color([0.15, 0.45, 0.25, 0.85]) smartphone_adapter();
    translate([0, 45, 1.5])
        color([0.3, 0.3, 0.35, 0.95]) soil_drawer();
    translate([0, 45, 30])
        color([0.2, 0.55, 0.7, 0.9]) soil_press();
}
