import 'package:flutter_test/flutter_test.dart';
import 'package:npxai_soil_analyzer/domain/models/nutrient_prediction.dart';
import 'package:npxai_soil_analyzer/domain/models/spectral_signature.dart';
import 'package:npxai_soil_analyzer/domain/use_cases/color_normalization_use_case.dart';
import 'package:npxai_soil_analyzer/domain/use_cases/edge_ai_inference_use_case.dart';
import 'package:npxai_soil_analyzer/domain/use_cases/integrated_advisor_use_case.dart';

void main() {
  group('Edge AI Inference & Architecture Tests', () {
    late EdgeAiInferenceUseCase aiUseCase;
    late ColorNormalizationUseCase colorUseCase;
    late IntegratedAdvisorUseCase advisorUseCase;

    setUp(() {
      aiUseCase = EdgeAiInferenceUseCase();
      colorUseCase = ColorNormalizationUseCase();
      advisorUseCase = IntegratedAdvisorUseCase();
    });

    test('1. Color Normalization - Rec. 709 Gain and RGB to HSV conversion', () {
      final gain = colorUseCase.computeGainFactor(
        observedRed: 240.0,
        observedGreen: 240.0,
        observedBlue: 240.0,
      );
      expect(gain, closeTo(1.0, 0.05));

      final hsv = colorUseCase.rgbToHsv(255, 0, 0);
      expect(hsv['h'], closeTo(0.0, 0.1));
      expect(hsv['s'], closeTo(1.0, 0.1));
      expect(hsv['v'], closeTo(1.0, 0.1));
    });

    test('2. Edge AI Model Inference - Total N and Available P prediction bounds', () {
      const signature = SpectralSignature(
        r405nm: 0.15,
        r465nm: 0.22,
        r525nm: 0.28,
        r630nm: 0.38,
        r850nm: 0.45,
        r940nm: 0.50,
        hueMean: 32.5,
        saturationMean: 0.42,
        valueMean: 0.38,
        valueMedian: 0.37,
        calibrationGainFactor: 1.0,
      );

      final prediction = aiUseCase.predictNutrients(signature);

      // ตรวจสอบค่า Total N (ควรอยู่ในช่วง 0.4 - 3.0 g/kg)
      expect(prediction.totalNitrogen, greaterThanOrEqualTo(0.4));
      expect(prediction.totalNitrogen, lessThanOrEqualTo(3.0));

      // ตรวจสอบค่า Available P (ควรอยู่ในช่วง >= 2.0 mg/kg)
      expect(prediction.availablePhosphorus, greaterThanOrEqualTo(2.0));

      // ตรวจสอบความเชื่อมั่น R^2 > 0.85 ตามข้อกำหนดโครงการวิจัย
      expect(prediction.confidenceScore, greaterThanOrEqualTo(0.85));
    });

    test('3. Integrated Bio-Fertilizer Advisor - Recommends PSB and NFB strains', () {
      final lowPPrediction = NutrientPrediction(
        totalNitrogen: 1.45,
        nitrogenLevel: NutrientLevel.moderate,
        availablePhosphorus: 6.2, // ต่ำมาก (< 10 mg/kg)
        phosphorusLevel: NutrientLevel.low,
        confidenceScore: 0.93,
        modelName: 'RBRU-Test',
        predictedAt: DateTime.now(),
      );

      final recommendation = advisorUseCase.generateRecommendation(
        prediction: lowPPrediction,
        cropName: 'ทุเรียนหมอนทอง',
        growthStage: 'ระยะสะสมอาหาร',
      );

      // เมื่อฟอสฟอรัสต่ำ ต้องแนะนำสายพันธุ์ PSB (แบคทีเรียละลายฟอสเฟต)
      final hasPsb = recommendation.recommendedStrains
          .any((s) => s.functionalType == 'PSB');
      expect(hasPsb, isTrue);

      // ตรวจสอบการลดต้นทุนปุ๋ยเคมี (10-35%)
      expect(recommendation.estimatedCostReductionPercent, greaterThanOrEqualTo(10.0));
      expect(recommendation.chemicalFertilizerFormula.isNotEmpty, isTrue);
    });
  });
}
