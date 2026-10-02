import 'package:flutter/material.dart';
import '../../../domain/models/nutrient_prediction.dart';

/// ชุดสีมาตรฐานสากลและมาตรฐานกรมพัฒนาที่ดิน (LDD) สำหรับการแสดงผลธาตุอาหารในดิน NPxAI
/// รองรับการจำแนกโทนสีประจำธาตุ (Elemental Identity) และการเปลี่ยนเฉดสีตามระดับการวิเคราะห์ (5-Level Rating)
class NutrientColorPalette {
  // ---------------------------------------------------------------------------
  // 1. สีอัตลักษณ์ประจำธาตุอาหาร (Elemental Identity Primary Colors)
  // ---------------------------------------------------------------------------
  /// ไนโตรเจน (Total N): โทนสีฟ้า/ฟ้าคราม (Cyan / Sky Blue)
  static const Color nitrogenBase = Color(0xFF00E5FF);

  /// ฟอสฟอรัส (Available P): โทนสีส้ม/ทองอำพัน (Amber / Orange)
  static const Color phosphorusBase = Color(0xFFFF9100);

  /// โพแทสเซียม (Available K): โทนสีแดง (Red / Crimson / Rose) ตามมาตรฐานการวิจัย
  static const Color potassiumBase = Color(0xFFFF5252);

  /// อินทรียวัตถุในดิน (Soil OM): โทนสีเขียวมรกต (Emerald / Leaf Green)
  static const Color organicMatterBase = Color(0xFF69F0AE);

  /// คืนค่าสีประจำธาตุอาหารตามสัญลักษณ์ ('N', 'P', 'K', 'OM')
  static Color getBaseColor(String symbol) {
    switch (symbol.trim().toUpperCase()) {
      case 'N':
        return nitrogenBase;
      case 'P':
        return phosphorusBase;
      case 'K':
        return potassiumBase; // โทนสีแดง
      case 'OM':
        return organicMatterBase;
      default:
        return nitrogenBase;
    }
  }

  // ---------------------------------------------------------------------------
  // 2. เฉดสีตามมาตรฐานการวิเคราะห์ดิน 5 ระดับ สำหรับแต่ละธาตุ
  //    (Nutrient-Specific 5-Level Shade Gradient)
  // ---------------------------------------------------------------------------
  /// คำนวณเฉดสีที่ปรับเปลี่ยนตามระดับผลการวิเคราะห์ (ต่ำมาก -> ต่ำ -> ปานกลาง -> สูง -> สูงมาก)
  /// เพื่อให้เห็นระดับความเข้มข้นของธาตุอาหารตามเกณฑ์การประเมินดิน
  static Color getNutrientShade(String symbol, NutrientLevel level) {
    final sym = symbol.trim().toUpperCase();

    if (sym == 'K') {
      // โพแทสเซียม (K) - ตระกูลโทนสีแดง (Red Tone Spectrum)
      switch (level) {
        case NutrientLevel.veryLow:
          return const Color(0xFFFF8A80); // แดงอ่อนพาสเทล (ขาดแคลนมาก)
        case NutrientLevel.low:
          return const Color(0xFFFF5252); // แดงปะการังสว่าง (ขาดแคลน)
        case NutrientLevel.moderate:
          return const Color(0xFFFF1744); // แดงทับทิมสดใส (ปานกลาง-พอเหมาะ)
        case NutrientLevel.high:
          return const Color(0xFFD50000); // แดงเข้มสด (สูง)
        case NutrientLevel.veryHigh:
          return const Color(0xFFB71C1C); // แดงไวน์เข้มลึก (สูงมาก)
      }
    } else if (sym == 'P') {
      // ฟอสฟอรัส (P) - ตระกูลโทนสีส้ม/ทอง (Orange-Amber Tone Spectrum)
      switch (level) {
        case NutrientLevel.veryLow:
          return const Color(0xFFFFD54F); // เหลืองทองอ่อน
        case NutrientLevel.low:
          return const Color(0xFFFFB300); // เหลืองส้ม
        case NutrientLevel.moderate:
          return const Color(0xFFFF9100); // ส้มอำพันสดใส
        case NutrientLevel.high:
          return const Color(0xFFFF6D00); // ส้มสดเข้ม
        case NutrientLevel.veryHigh:
          return const Color(0xFFE65100); // ส้มไหม้ลึก
      }
    } else if (sym == 'N') {
      // ไนโตรเจน (N) - ตระกูลโทนสีฟ้าคราม (Cyan-Blue Tone Spectrum)
      switch (level) {
        case NutrientLevel.veryLow:
          return const Color(0xFF80DEEA); // ฟ้าอ่อนพาสเทล
        case NutrientLevel.low:
          return const Color(0xFF26C6DA); // ฟ้าสว่าง
        case NutrientLevel.moderate:
          return const Color(0xFF00E5FF); // ฟ้าครามสดใส
        case NutrientLevel.high:
          return const Color(0xFF00B0FF); // ฟ้าสดเข้ม
        case NutrientLevel.veryHigh:
          return const Color(0xFF0288D1); // น้ำเงินครามลึก
      }
    } else if (sym == 'OM') {
      // อินทรียวัตถุในดิน (OM) - ตระกูลโทนสีเขียวมรกต (Green-Emerald Tone Spectrum)
      switch (level) {
        case NutrientLevel.veryLow:
          return const Color(0xFFA7F3D0); // เขียวมิ้นต์อ่อน
        case NutrientLevel.low:
          return const Color(0xFF6EE7B7); // เขียวตองอ่อน
        case NutrientLevel.moderate:
          return const Color(0xFF00E676); // เขียวมรกตสดใส
        case NutrientLevel.high:
          return const Color(0xFF059669); // เขียวใบไม้เข้ม
        case NutrientLevel.veryHigh:
          return const Color(0xFF047857); // เขียวไพรเข้มลึก
      }
    }

    return getBaseColor(symbol);
  }

  // ---------------------------------------------------------------------------
  // 3. สีสถานะวินิจฉัยสุขภาพดินตามเกณฑ์มาตรฐานสากล (Agronomic Diagnostic Traffic Light)
  // ---------------------------------------------------------------------------
  /// ใช้สำหรับป้ายระดับ (Status Badge) แสดงความพร้อมของดิน
  static Color getDiagnosticStatusColor(NutrientLevel level) {
    switch (level) {
      case NutrientLevel.veryLow:
        return const Color(0xFFFF4D4F); // แดงวิกฤต (ขาดรุนแรง ต้องฟื้นฟูด่วน)
      case NutrientLevel.low:
        return const Color(0xFFFFA940); // ส้มเตือน (ขาด ต้องเติมปุ๋ย)
      case NutrientLevel.moderate:
        return const Color(0xFF52C41A); // เขียวสมบูรณ์ (เหมาะสม พอเหมาะที่สุด)
      case NutrientLevel.high:
        return const Color(0xFF1890FF); // ฟ้าสดใส (อุดมสมบูรณ์)
      case NutrientLevel.veryHigh:
        return const Color(0xFF722ED1); // ม่วงคราม (สูงเกินเกณฑ์ เสี่ยงตกค้าง)
    }
  }
}
