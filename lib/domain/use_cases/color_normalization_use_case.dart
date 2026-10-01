import 'dart:math';

/// Use Case: การปรับเทียบและชดเชยสีด้วยแผ่นเทียบสีมาตรฐาน (Color Reference Chart Normalization)
/// วัตถุประสงค์ตามโครงการวิจัย: ขจัดความคลาดเคลื่อนจากเซนเซอร์กล้องสมาร์ทโฟนที่แตกต่างกัน
/// และควบคุมความแปรปรวนของแสงแวดล้อมที่อาจเล็ดลอด
class ColorNormalizationUseCase {
  /// คำนวณ Calibration Gain Factor จากค่าสีขาวมาตรฐาน (White Patch)
  /// ค่ามาตรฐานทางทฤษฎี RGB อ้างอิง: Target (240, 240, 240)
  double computeGainFactor({
    required double observedRed,
    required double observedGreen,
    required double observedBlue,
  }) {
    const double targetLuminance = 240.0;
    // คำนวณ Relative Luminance (Rec. 709)
    final double observedLuminance =
        0.2126 * observedRed + 0.7152 * observedGreen + 0.0722 * observedBlue;

    if (observedLuminance <= 1.0) return 1.0;
    // จำกัดช่วง Gain ป้องกันค่าผิดปกติสุดโต่ง
    final double gain = targetLuminance / observedLuminance;
    return gain.clamp(0.5, 2.5);
  }

  /// ปรับชดเชยค่า RGB ด้วย Matrix Calibration
  List<double> applyNormalization(
      List<double> rawRgb, double calibrationGain) {
    return rawRgb.map((val) => (val * calibrationGain).clamp(0.0, 255.0)).toList();
  }

  /// แปลงค่า RGB (0-255) เป็น HSV (Hue: 0-360, Saturation: 0-1, Value: 0-1)
  Map<String, double> rgbToHsv(double r, double g, double b) {
    final double rNorm = r / 255.0;
    final double gNorm = g / 255.0;
    final double bNorm = b / 255.0;

    final double maxVal = max(rNorm, max(gNorm, bNorm));
    final double minVal = min(rNorm, min(gNorm, bNorm));
    final double delta = maxVal - minVal;

    double h = 0.0;
    if (delta > 0.00001) {
      if (maxVal == rNorm) {
        h = 60.0 * (((gNorm - bNorm) / delta) % 6);
      } else if (maxVal == gNorm) {
        h = 60.0 * (((bNorm - rNorm) / delta) + 2);
      } else {
        h = 60.0 * (((rNorm - gNorm) / delta) + 4);
      }
    }
    if (h < 0) h += 360.0;

    final double s = maxVal == 0.0 ? 0.0 : delta / maxVal;
    final double v = maxVal;

    return {'h': h, 's': s, 'v': v};
  }
}
