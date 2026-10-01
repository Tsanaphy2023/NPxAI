import 'dart:math' as math;

/// สเปกตรัมการสะท้อนแสงและการดูดกลืนแสงของดิน (Spectral Signature & Absorbance)
/// สอดคล้องกับระเบียบวิธีวิจัยโครงการย่อยที่ 2 (Reflectance & Absorbance Spectroscopy ย่าน Vis-NIR)
class SpectralSignature {
  /// แสงสะท้อนสัมพัทธ์ที่ความยาวคลื่นต่างๆ (400 - 940 nm)
  final double r405nm; // Violet (การดูดกลืนสารอินทรีย์ฮิวมัส และไนโตรเจนอินทรีย์)
  final double r465nm; // Blue (การดูดกลืนแคโรทีนอยด์และฮิวมัส)
  final double r525nm; // Green (รอยต่อการสะท้อนคลอโรฟิลล์และฮิวสีดิน)
  final double r630nm; // Red (การดูดกลืนเหล็กออกไซด์ Fe3+ ฮีมาไทต์ / สหสัมพันธ์ Available P)
  final double r850nm; // NIR 1 (การดูดกลืนเกอไทต์ Fe-Oxide และ Available P Bray-II)
  final double r940nm; // NIR 2 (โอเวอร์โทน H2O และไนโตรเจนทั้งหมด Total N Kjeldahl)

  /// ค่าสถิติในปริภูมิสี HSV จากบริเวณสนใจ (ROI)
  final double hueMean;
  final double saturationMean;
  final double valueMean; // ความสว่างสัมพัทธ์
  final double valueMedian;

  /// ค่าปรับแก้อ้างอิงจากแผ่นเทียบสีมาตรฐาน (Color Reference Chart)
  final double calibrationGainFactor;

  const SpectralSignature({
    required this.r405nm,
    required this.r465nm,
    required this.r525nm,
    required this.r630nm,
    required this.r850nm,
    required this.r940nm,
    required this.hueMean,
    required this.saturationMean,
    required this.valueMean,
    required this.valueMedian,
    this.calibrationGainFactor = 1.0,
  });

  /// แปลงเป็น Feature Vector สำหรับโมเดล AI (ANN / SVR)
  List<double> toFeatureVector() {
    return [
      r405nm * calibrationGainFactor,
      r465nm * calibrationGainFactor,
      r525nm * calibrationGainFactor,
      r630nm * calibrationGainFactor,
      r850nm * calibrationGainFactor,
      r940nm * calibrationGainFactor,
      hueMean / 360.0,
      saturationMean,
      valueMean,
    ];
  /// คำนวณค่าการดูดกลืนแสงสัมพัทธ์ (Absorbance: A = log10(1/R))
  /// ตามกฎของ Beer-Lambert สำหรับคุณสมบัติการดูดกลืนแสงของธาตุอาหารพืช
  static double toAbsorbance(double reflectance) {
    final r = reflectance.clamp(0.01, 1.0);
    return -math.log(r) / math.ln10;
  }

  double get a405nm => toAbsorbance(r405nm);
  double get a465nm => toAbsorbance(r465nm);
  double get a525nm => toAbsorbance(r525nm);
  double get a630nm => toAbsorbance(r630nm);
  double get a850nm => toAbsorbance(r850nm);
  double get a940nm => toAbsorbance(r940nm);

  List<double> get absorbanceList => [a405nm, a465nm, a525nm, a630nm, a850nm, a940nm];
  List<double> get reflectanceList => [r405nm, r465nm, r525nm, r630nm, r850nm, r940nm];

  Map<String, dynamic> toJson() => {
        'r405nm': r405nm,
        'r465nm': r465nm,
        'r525nm': r525nm,
        'r630nm': r630nm,
        'r850nm': r850nm,
        'r940nm': r940nm,
        'hueMean': hueMean,
        'saturationMean': saturationMean,
        'valueMean': valueMean,
        'valueMedian': valueMedian,
        'calibrationGainFactor': calibrationGainFactor,
      };

  factory SpectralSignature.fromJson(Map<String, dynamic> json) =>
      SpectralSignature(
        r405nm: (json['r405nm'] as num).toDouble(),
        r465nm: (json['r465nm'] as num).toDouble(),
        r525nm: (json['r525nm'] as num).toDouble(),
        r630nm: (json['r630nm'] as num).toDouble(),
        r850nm: (json['r850nm'] as num).toDouble(),
        r940nm: (json['r940nm'] as num).toDouble(),
        hueMean: (json['hueMean'] as num).toDouble(),
        saturationMean: (json['saturationMean'] as num).toDouble(),
        valueMean: (json['valueMean'] as num).toDouble(),
        valueMedian: (json['valueMedian'] as num).toDouble(),
        calibrationGainFactor:
            (json['calibrationGainFactor'] as num?)?.toDouble() ?? 1.0,
      );
}
