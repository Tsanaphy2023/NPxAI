enum NutrientLevel {
  veryLow,
  low,
  moderate,
  high,
  veryHigh;

  String get labelTh {
    switch (this) {
      case NutrientLevel.veryLow:
        return 'ต่ำมาก';
      case NutrientLevel.low:
        return 'ต่ำ';
      case NutrientLevel.moderate:
        return 'ปานกลาง (เหมาะสม)';
      case NutrientLevel.high:
        return 'สูง';
      case NutrientLevel.veryHigh:
        return 'สูงมาก';
    }
  }

  String get shortLabelTh {
    switch (this) {
      case NutrientLevel.veryLow:
        return 'ต่ำมาก';
      case NutrientLevel.low:
        return 'ต่ำ';
      case NutrientLevel.moderate:
        return 'ปานกลาง';
      case NutrientLevel.high:
        return 'สูง';
      case NutrientLevel.veryHigh:
        return 'สูงมาก';
    }
  }
}

/// สถาปัตยกรรมโหมดการทำงานของอุปกรณ์ (Dual-Architecture)
enum NPxAIMode {
  /// 1. โหมดพกพาประหยัด (NPxAI Lite - Flash Mode)
  /// ใช้กล่อง 3D Box ดึงแสงจากแฟลชมือถือผ่านท่อนำแสง 45°
  liteFlash,

  /// 2. โหมดความแม่นยำสูงระดับห้องปฏิบัติการ (NPxAI Pro - Chamber Mode)
  /// ใช้กล่อง 3D Box ร่วมกับชุดวงจรสโตรบ LED 7 แถบความยาวคลื่นและห้องมืดสมบูรณ์
  proChamber;

  String get labelTh {
    switch (this) {
      case NPxAIMode.liteFlash:
        return 'NPxAI Lite (Flash 45°)';
      case NPxAIMode.proChamber:
        return 'NPxAI Pro (Chamber 7-Band)';
    }
  }

  String get shortLabelTh {
    switch (this) {
      case NPxAIMode.liteFlash:
        return 'Lite (Flash 45°)';
      case NPxAIMode.proChamber:
        return 'Pro (Chamber)';
    }
  }

  String get descriptionTh {
    switch (this) {
      case NPxAIMode.liteFlash:
        return 'โหมดพกพาประหยัด ใช้แสงแฟลชมือถือผ่านท่อนำแสง 45° รวดเร็ว ต้นทุนต่ำ (R² ≈ 0.86 - 0.88)';
      case NPxAIMode.proChamber:
        return 'โหมดความแม่นยำสูงระดับแล็บ ใช้สโตรบ LED 7 แถบความยาวคลื่น และ 0-Lux Calibration (R² ≈ 0.94 - 0.97)';
    }
  }
}

/// ผลการทำนายปริมาณธาตุอาหารในดิน (Total N, Available P และ Available K)
class NutrientPrediction {
  /// ไนโตรเจนทั้งหมด (Total N) หน่วย: g/kg (หรือ %)
  final double totalNitrogen;
  final NutrientLevel nitrogenLevel;

  /// ฟอสฟอรัสที่เป็นประโยชน์ (Available P) หน่วย: mg/kg (ppm)
  final double availablePhosphorus;
  final NutrientLevel phosphorusLevel;

  /// โพแทสเซียมที่แลกเปลี่ยนได้ (Available K) หน่วย: mg/kg (ppm)
  final double availablePotassium;
  final NutrientLevel potassiumLevel;

  /// อินทรียวัตถุในดิน (Soil Organic Matter: OM / SOM) หน่วย: %
  final double soilOrganicMatter;
  final NutrientLevel organicMatterLevel;

  /// โหมดสถาปัตยกรรมฮาร์ดแวร์ที่ใช้ตรวจวัด
  final NPxAIMode hardwareMode;

  /// สัมประสิทธิ์ความเชื่อมั่นของแบบจำลอง ($R^2$ หรือ Confidence)
  final double confidenceScore;
  final String modelName; // เช่น "RBRU-Ensemble-ANN-SVR"
  final DateTime predictedAt;

  const NutrientPrediction({
    required this.totalNitrogen,
    required this.nitrogenLevel,
    required this.availablePhosphorus,
    required this.phosphorusLevel,
    this.availablePotassium = 110.0,
    this.potassiumLevel = NutrientLevel.moderate,
    this.soilOrganicMatter = 2.40,
    this.organicMatterLevel = NutrientLevel.moderate,
    this.hardwareMode = NPxAIMode.proChamber,
    required this.confidenceScore,
    required this.modelName,
    required this.predictedAt,
  });

  /// การจัดระดับตามเกณฑ์ดินของกรมพัฒนาที่ดินและงานวิจัยผลไม้จันทบุรี
  static NutrientLevel classifyNitrogen(double nGPerKg) {
    if (nGPerKg < 0.6) return NutrientLevel.veryLow;
    if (nGPerKg < 1.0) return NutrientLevel.low;
    if (nGPerKg <= 1.8) return NutrientLevel.moderate;
    if (nGPerKg <= 2.5) return NutrientLevel.high;
    return NutrientLevel.veryHigh;
  }

  static NutrientLevel classifyPhosphorus(double pMgPerKg) {
    if (pMgPerKg < 5.0) return NutrientLevel.veryLow;
    if (pMgPerKg < 15.0) return NutrientLevel.low;
    if (pMgPerKg <= 35.0) return NutrientLevel.moderate;
    if (pMgPerKg <= 60.0) return NutrientLevel.high;
    return NutrientLevel.veryHigh;
  }

  static NutrientLevel classifyPotassium(double kMgPerKg) {
    if (kMgPerKg < 40.0) return NutrientLevel.veryLow;
    if (kMgPerKg < 80.0) return NutrientLevel.low;
    if (kMgPerKg <= 140.0) return NutrientLevel.moderate;
    if (kMgPerKg <= 200.0) return NutrientLevel.high;
    return NutrientLevel.veryHigh;
  }

  static NutrientLevel classifyOrganicMatter(double omPercent) {
    if (omPercent < 1.0) return NutrientLevel.veryLow;
    if (omPercent < 1.5) return NutrientLevel.low;
    if (omPercent <= 2.5) return NutrientLevel.moderate;
    if (omPercent <= 3.5) return NutrientLevel.high;
    return NutrientLevel.veryHigh;
  }

  Map<String, dynamic> toJson() => {
        'totalNitrogen': totalNitrogen,
        'nitrogenLevel': nitrogenLevel.name,
        'availablePhosphorus': availablePhosphorus,
        'phosphorusLevel': phosphorusLevel.name,
        'availablePotassium': availablePotassium,
        'potassiumLevel': potassiumLevel.name,
        'soilOrganicMatter': soilOrganicMatter,
        'organicMatterLevel': organicMatterLevel.name,
        'hardwareMode': hardwareMode.name,
        'confidenceScore': confidenceScore,
        'modelName': modelName,
        'predictedAt': predictedAt.toIso8601String(),
      };
}
