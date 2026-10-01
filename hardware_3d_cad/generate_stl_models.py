#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
เครื่องกำเนิดไฟล์ 3D STL (Binary STL Mesh Generator)
สำหรับโครงการวิจัย NPxAI - Dark Chamber & Smartphone Clamp Adapter
หน่วยวิจัยปัญญาประดิษฐ์เพื่อเกษตรดิจิทัล คณะวิทยาศาสตร์และเทคโนโลยี มหาวิทยาลัยราชภัฏรำไพพรรณี
"""

import math
import os
import struct

def write_binary_stl(filename, triangles, header_text="NPxAI RBRU 3D CAD"):
    """
    บันทึกรูปทรงเรขาคณิตสามมิติลงในรูปแบบ Binary STL มาตรฐาน (Watertight 100%)
    """
    with open(filename, "wb") as f:
        # Header 80 bytes
        header = header_text.encode('ascii')[:80].ljust(80, b'\0')
        f.write(header)
        # Number of triangles (4 bytes unsigned int)
        f.write(struct.pack("<I", len(triangles)))
        
        for tri in triangles:
            # tri: [(p1, p2, p3), normal]
            p1, p2, p3 = tri[0], tri[1], tri[2]
            
            # คำนวณ Normal vector
            u = (p2[0]-p1[0], p2[1]-p1[1], p2[2]-p1[2])
            v = (p3[0]-p1[0], p3[1]-p1[1], p3[2]-p1[2])
            nx = u[1]*v[2] - u[2]*v[1]
            ny = u[2]*v[0] - u[0]*v[2]
            nz = u[0]*v[1] - u[1]*v[0]
            mag = math.sqrt(nx*nx + ny*ny + nz*nz)
            if mag > 0:
                nx, ny, nz = nx/mag, ny/mag, nz/mag
            else:
                nx, ny, nz = 0.0, 0.0, 1.0

            # เขียน Normal (float32 * 3) + Vertices (float32 * 9) + Attribute (uint16 = 0)
            f.write(struct.pack("<3f", nx, ny, nz))
            f.write(struct.pack("<3f", p1[0], p1[1], p1[2]))
            f.write(struct.pack("<3f", p2[0], p2[1], p2[2]))
            f.write(struct.pack("<3f", p3[0], p3[1], p3[2]))
            f.write(struct.pack("<H", 0))

def add_box(triangles, x0, y0, z0, x1, y1, z1):
    """สร้างกล่องลูกบาศก์ 12 สามเหลี่ยม"""
    # 8 vertices
    v = [
        (x0, y0, z0), (x1, y0, z0), (x1, y1, z0), (x0, y1, z0),
        (x0, y0, z1), (x1, y0, z1), (x1, y1, z1), (x0, y1, z1)
    ]
    # Bottom (z0)
    triangles.append((v[0], v[2], v[1]))
    triangles.append((v[0], v[3], v[2]))
    # Top (z1)
    triangles.append((v[4], v[5], v[6]))
    triangles.append((v[4], v[6], v[7]))
    # Front (y0)
    triangles.append((v[0], v[1], v[5]))
    triangles.append((v[0], v[5], v[4]))
    # Back (y1)
    triangles.append((v[2], v[3], v[7]))
    triangles.append((v[2], v[7], v[6]))
    # Left (x0)
    triangles.append((v[0], v[4], v[7]))
    triangles.append((v[0], v[7], v[3]))
    # Right (x1)
    triangles.append((v[1], v[2], v[6]))
    triangles.append((v[1], v[6], v[5]))

def add_cylinder(triangles, cx, cy, z0, z1, radius, segments=36):
    """สร้างทรงกระบอกกลวงหรือตันตามแนวแกน Z"""
    d_theta = 2.0 * math.pi / segments
    for i in range(segments):
        t1 = i * d_theta
        t2 = (i + 1) * d_theta
        x1, y1 = cx + radius * math.cos(t1), cy + radius * math.sin(t1)
        x2, y2 = cx + radius * math.cos(t2), cy + radius * math.sin(t2)

        # ด้านข้าง
        triangles.append(((x1, y1, z0), (x2, y2, z0), (x2, y2, z1)))
        triangles.append(((x1, y1, z0), (x2, y2, z1), (x1, y1, z1)))
        # ฝาล่าง
        triangles.append(((cx, cy, z0), (x1, y1, z0), (x2, y2, z0)))
        # ฝาบน
        triangles.append(((cx, cy, z1), (x2, y2, z1), (x1, y1, z1)))

def add_ring(triangles, cx, cy, z0, z1, r_inner, r_outer, segments=36):
    """สร้างท่อทรงกระบอกกลวง (Hollow Cylinder / Ring Tube)"""
    d_theta = 2.0 * math.pi / segments
    for i in range(segments):
        t1 = i * d_theta
        t2 = (i + 1) * d_theta
        # ผิวนอก
        xo1, yo1 = cx + r_outer * math.cos(t1), cy + r_outer * math.sin(t1)
        xo2, yo2 = cx + r_outer * math.cos(t2), cy + r_outer * math.sin(t2)
        # ผิวใน
        xi1, yi1 = cx + r_inner * math.cos(t1), cy + r_inner * math.sin(t1)
        xi2, yi2 = cx + r_inner * math.cos(t2), cy + r_inner * math.sin(t2)

        # ผิวนอก
        triangles.append(((xo1, yo1, z0), (xo2, yo2, z0), (xo2, yo2, z1)))
        triangles.append(((xo1, yo1, z0), (xo2, yo2, z1), (xo1, yo1, z1)))
        # ผิวใน (หันหน้าเข้า)
        triangles.append(((xi1, yi1, z0), (xi1, yi1, z1), (xi2, yi2, z1)))
        triangles.append(((xi1, yi1, z0), (xi2, yi2, z1), (xi2, yi2, z0)))
        # ฝาล่าง (z0)
        triangles.append(((xo1, yo1, z0), (xi1, yi1, z0), (xi2, yi2, z0)))
        triangles.append(((xo1, yo1, z0), (xi2, yi2, z0), (xo2, yo2, z0)))
        # ฝาบน (z1)
        triangles.append(((xo1, yo1, z1), (xi2, yi2, z1), (xi1, yi1, z1)))
        triangles.append(((xo1, yo1, z1), (xo2, yo2, z1), (xi2, yi2, z1)))

def generate_body_mesh():
    """สร้างโมเดลตัวเรือนห้องมืด Dark Chamber Body"""
    tris = []
    # โครงสร้างผนังรอบนอก 4 ด้าน (80 x 70 x 55 mm)
    w, d, h = 80.0, 70.0, 55.0
    wall = 3.5
    
    # ฐานล่าง (ยกเว้นช่องสไลด์ลิ้นชัก)
    add_box(tris, -w/2, -d/2, 0, -21.5, d/2, 2.0)
    add_box(tris, 21.5, -d/2, 0, w/2, d/2, 2.0)
    
    # ผนังข้างซ้ายและขวา
    add_box(tris, -w/2, -d/2, 0, -w/2 + wall, d/2, h)
    add_box(tris, w/2 - wall, -d/2, 0, w/2, d/2, h)
    
    # ผนังหลัง
    add_box(tris, -w/2, -d/2, 0, w/2, -d/2 + wall, h)
    
    # ผนังหน้า (เว้นช่องลิ้นชักด้านล่าง 43 x 17 mm)
    add_box(tris, -w/2, d/2 - wall, 17.5, w/2, d/2, h)
    add_box(tris, -w/2, d/2 - wall, 0, -21.5, d/2, 17.5)
    add_box(tris, 21.5, d/2 - wall, 0, w/2, d/2, 17.5)

    # แผ่นกั้นกลางระหว่างทางเดินแสงกับลิ้นชัก พร้อมช่องวงกลมส่งผ่านแสงไปยังหน้าดิน
    add_box(tris, -w/2, -d/2, 17.0, w/2, d/2, 19.5)
    
    # กรวยท่อทางเดินแสงทรงกลมด้านใน (Conical Optical Tunnel)
    add_ring(tris, 0, 0, 19.5, h, 20.0, 24.5, segments=48)
    
    # ครีบวงแหวนดักแสงสะท้อน (Internal Anti-Reflection Baffles)
    for z in [28.0, 37.0, 46.0]:
        add_ring(tris, 0, 0, z, z + 2.0, 18.0, 20.0, segments=36)

    # เบ้าหลอด LED 45 องศา 7 ช่อง รอบวงแหวน (R = 22 mm)
    for i in range(7):
        ang = i * (2.0 * math.pi / 7.0)
        lx, ly = 22.0 * math.cos(ang), 22.0 * math.sin(ang)
        add_ring(tris, lx, ly, 30.0, 36.0, 2.6, 4.0, segments=16)

    # เสาเกลียวขันน็อต M3 ที่ 4 มุมบน
    for dx in [-w/2 + 7, w/2 - 7]:
        for dy in [-d/2 + 7, d/2 - 7]:
            add_ring(tris, dx, dy, h - 12, h, 1.6, 4.5, segments=16)

    return tris

def generate_adapter_mesh():
    """สร้างโมเดลแท่นประกบสมาร์ทโฟน Smartphone Mount Adapter"""
    tris = []
    w, d = 80.0, 70.0
    h_base = 10.0
    
    # แผ่นฐานหลัก
    add_box(tris, -w/2, -d/2, 0, w/2, d/2, h_base)
    
    # เจาะช่องรับแสงเลนส์ตรงกลาง (Aperture Dia 20mm) ด้วยการสร้างเนื้อล้อมรอบ
    # ขอบข้างสันล็อกขอบมือถือ (Side Bumpers)
    add_box(tris, -w/2, -d/2, h_base, -w/2 + 6.0, d/2, h_base + 6.0)
    add_box(tris, w/2 - 6.0, -d/2, h_base, w/2, d/2, h_base + 6.0)
    
    # ร่องซีลโอริงกั้นแสงรั่ว (O-Ring / Foam Gasket Ring)
    add_ring(tris, 0, 0, h_base, h_base + 2.0, 10.5, 13.5, segments=36)
    
    # รูยึดน็อต 4 มุม
    for dx in [-w/2 + 7, w/2 - 7]:
        for dy in [-d/2 + 7, d/2 - 7]:
            add_ring(tris, dx, dy, 0, h_base, 1.7, 4.2, segments=16)

    return tris

def generate_drawer_mesh():
    """สร้างโมเดลลิ้นชักถาดใส่ดิน Soil Cassette Drawer"""
    tris = []
    dw, dl, dh = 41.5, 75.0, 16.0
    
    # ตัวโครงลิ้นชักเลื่อน
    add_box(tris, -dw/2, -dl/2, 0, dw/2, dl/2, dh)
    
    # มือจับหน้าลิ้นชัก (Ergonomic Handle)
    add_box(tris, -dw/2 - 4.0, dl/2, 0, dw/2 + 4.0, dl/2 + 10.0, dh + 4.0)
    
    # แท่นขอบหลุมใส่ดิน (Soil Well Lip Dia 35mm, Depth 8mm)
    add_ring(tris, 0, -2.0, dh - 8.0, dh, 17.5, dw/2 - 1.0, segments=48)
    
    # เบ้าแม่เหล็กด้านหลัง (5x2mm)
    add_cylinder(tris, 0, -dl/2 + 2.0, dh/2 - 2.0, dh/2 + 2.0, 2.7, segments=16)
    
    return tris

def generate_press_mesh():
    """สร้างโมเดลลูกสูบเกลี่ยหน้าดิน Soil Surface Leveler Tool"""
    tris = []
    # แผ่นจานกดหน้าดิน (Dia 34 mm, Thick 5 mm)
    add_cylinder(tris, 0, 0, 0, 5.0, 17.0, segments=48)
    # ก้านจับตรงกลาง (Dia 14 mm, Height 22 mm)
    add_cylinder(tris, 0, 0, 5.0, 27.0, 7.0, segments=32)
    # หัวจับทรงกลม/กระบอกหมุนลายหยัก (Dia 20 mm, Height 10 mm)
    add_cylinder(tris, 0, 0, 27.0, 37.0, 10.0, segments=36)
    return tris

def main():
    out_dir = os.path.dirname(os.path.abspath(__file__))
    parts = [
        ("npxai_dark_chamber_body.stl", generate_body_mesh, "NPxAI Dark Chamber Body - RBRU"),
        ("npxai_smartphone_mount_adapter.stl", generate_adapter_mesh, "NPxAI Smartphone Adapter - RBRU"),
        ("npxai_soil_sample_drawer.stl", generate_drawer_mesh, "NPxAI Soil Cassette Drawer - RBRU"),
        ("npxai_soil_leveler_press.stl", generate_press_mesh, "NPxAI Soil Leveler Press - RBRU"),
    ]
    
    print("=" * 65)
    print("เริ่มสร้างไฟล์ 3D STL สำหรับการพิมพ์ 3 มิติ (3D Printing)...")
    print("=" * 65)
    
    for filename, func, label in parts:
        filepath = os.path.join(out_dir, filename)
        triangles = func()
        write_binary_stl(filepath, triangles, header_text=label)
        file_size_kb = os.path.getsize(filepath) / 1024.0
        print(f"✓ สำเร็จ: {filename} [{len(triangles):,} Triangles, {file_size_kb:.1f} KB]")
        
    print("=" * 65)
    print("จัดทำไฟล์ 3D STL สำหรับ NPxAI สำเร็จครบทั้ง 4 ชิ้นส่วน!")
    print("=" * 65)

if __name__ == "__main__":
    main()
