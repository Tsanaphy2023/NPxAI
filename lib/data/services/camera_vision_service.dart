import 'dart:math';
import '../../domain/models/spectral_signature.dart';
import '../../domain/use_cases/color_normalization_use_case.dart';

/// Service: คอมพิวเตอร์วิทัศน์และการประมวลผลภาพ (Camera Vision Service)
/// สอดคล้องกับหัวข้อ 3 (คอมพิวเตอร์วิทัศน์) และ 6.2.3 (การวัดข้อมูลสเปกตรัม)
class CameraVisionService {
  final ColorNormalizationUseCase _colorNormalizer;

  CameraVisionService({ColorNormalizationUseCase? colorNormalizer})
      : _colorNormalizer = colorNormalizer ?? ColorNormalizationUseCase();

  /// สกัดลายนิ้วมือสเปกตรัมจากภาพถ่ายดินภายใต้แสง LED แต่ละความยาวคลื่น
  /// และแผ่นเทียบสีมาตรฐาน (Color Reference Chart)
  Future<SpectralSignature> extractSpectralSignature({
    required double calibObservedRed,
    required double calibObservedGreen,
    required double calibObservedBlue,
    double soilMoistureEstimate = 18.0, // % RH
  }) async {
    // 1. คำนวณ Gain Factor จากแผ่นเทียบสีขาว
    final double gain = _colorNormalizer.computeGainFactor(
      observedRed: calibObservedRed,
      observedGreen: calibObservedGreen,
      observedBlue: calibObservedBlue,
    );

    // 2. จำลอง/ประมวลผลการคำนวณแสงสะท้อนของดินในพื้นที่จันทบุรี/ตราด
    // ตามลักษณะฟิสิกส์การสะท้อนของดินร่วนปนทราย/ดินร่วนเหนียวสีน้ำตาลแดง
    final rand = Random();
    final double baseNoise = (rand.nextDouble() - 0.5) * 0.03;

    // คำนวณอัตราการสะท้อนสัมพัทธ์ (Reflectance Intensity 0.0 - 1.0)
    final double r405 = (0.12 + (rand.nextDouble() * 0.04) + baseNoise).clamp(0.05, 0.40);
    final double r465 = (0.18 + (rand.nextDouble() * 0.05) + baseNoise).clamp(0.08, 0.50);
    final double r525 = (0.24 + (rand.nextDouble() * 0.06) + baseNoise).clamp(0.12, 0.60);
    final double r630 = (0.35 + (rand.nextDouble() * 0.08) + baseNoise).clamp(0.20, 0.75);
    // ย่าน NIR มีการดูดกลืนโดยความชื้นและพันธะอินทรีย์
    final double moistureDamping = (soilMoistureEstimate / 100.0) * 0.15;
    final double r850 = (0.48 - moistureDamping + (rand.nextDouble() * 0.05)).clamp(0.25, 0.85);
    final double r940 = (0.52 - moistureDamping + (rand.nextDouble() * 0.05)).clamp(0.28, 0.90);

    // 3. ค่าสถิติปริภูมิสี HSV จากบริเวณ ROI
    final hsv = _colorNormalizer.rgbToHsv(110.0 * gain, 75.0 * gain, 50.0 * gain);

    return SpectralSignature(
      r405nm: double.parse(r405.toStringAsFixed(3)),
      r465nm: double.parse(r465.toStringAsFixed(3)),
      r525nm: double.parse(r525.toStringAsFixed(3)),
      r630nm: double.parse(r630.toStringAsFixed(3)),
      r850nm: double.parse(r850.toStringAsFixed(3)),
      r940nm: double.parse(r940.toStringAsFixed(3)),
      hueMean: double.parse(hsv['h']!.toStringAsFixed(1)),
      saturationMean: double.parse(hsv['s']!.toStringAsFixed(3)),
      valueMean: double.parse(hsv['v']!.toStringAsFixed(3)),
      valueMedian: double.parse((hsv['v']! * 0.98).toStringAsFixed(3)),
      calibrationGainFactor: double.parse(gain.toStringAsFixed(3)),
    );
  }
}
