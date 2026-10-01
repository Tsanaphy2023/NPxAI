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
}

/// ผลการทำนายปริมาณธาตุอาหารในดิน (Total N และ Available P)
class NutrientPrediction {
  /// ไนโตรเจนทั้งหมด (Total N) หน่วย: g/kg (หรือ %)
  final double totalNitrogen;
  final NutrientLevel nitrogenLevel;

  /// ฟอสฟอรัสที่เป็นประโยชน์ (Available P) หน่วย: mg/kg (ppm)
  final double availablePhosphorus;
  final NutrientLevel phosphorusLevel;

  /// สัมประสิทธิ์ความเชื่อมั่นของแบบจำลอง ($R^2$ หรือ Confidence)
  final double confidenceScore;
  final String modelName; // เช่น "RBRU-Ensemble-ANN-SVR"
  final DateTime predictedAt;

  const NutrientPrediction({
    required this.totalNitrogen,
    required this.nitrogenLevel,
    required this.availablePhosphorus,
    required this.phosphorusLevel,
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

  Map<String, dynamic> toJson() => {
        'totalNitrogen': totalNitrogen,
        'nitrogenLevel': nitrogenLevel.name,
        'availablePhosphorus': availablePhosphorus,
        'phosphorusLevel': phosphorusLevel.name,
        'confidenceScore': confidenceScore,
        'modelName': modelName,
        'predictedAt': predictedAt.toIso8601String(),
      };
}
