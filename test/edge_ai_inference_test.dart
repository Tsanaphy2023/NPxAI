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

    test('4. Dual-Architecture - NPxAI Lite (Flash 45°) vs NPxAI Pro (Chamber 7-Band)', () {
      const signature = SpectralSignature(
        r405nm: 0.16,
        r465nm: 0.24,
        r525nm: 0.30,
        r630nm: 0.40,
        r850nm: 0.48,
        r940nm: 0.52,
        hueMean: 31.0,
        saturationMean: 0.40,
        valueMean: 0.36,
        valueMedian: 0.35,
        calibrationGainFactor: 1.0,
      );

      // Lite Mode
      final litePred = aiUseCase.predictNutrients(signature, mode: NPxAIMode.liteFlash);
      expect(litePred.hardwareMode, equals(NPxAIMode.liteFlash));
      expect(litePred.confidenceScore, greaterThanOrEqualTo(0.85));
      expect(litePred.confidenceScore, lessThanOrEqualTo(0.91));

      // Pro Mode
      final proPred = aiUseCase.predictNutrients(
        signature,
        mode: NPxAIMode.proChamber,
        modelName: 'Soil-ViT',
      );
      expect(proPred.hardwareMode, equals(NPxAIMode.proChamber));
      expect(proPred.confidenceScore, greaterThanOrEqualTo(0.93));
    });

    test('5. Available Potassium (K) - Prediction bounds and Classification', () {
      const signature = SpectralSignature(
        r405nm: 0.18,
        r465nm: 0.25,
        r525nm: 0.32,
        r630nm: 0.42,
        r850nm: 0.50,
        r940nm: 0.55,
        hueMean: 30.0,
        saturationMean: 0.45,
        valueMean: 0.35,
        valueMedian: 0.34,
        calibrationGainFactor: 1.0,
      );

      final pred = aiUseCase.predictNutrients(signature);
      expect(pred.availablePotassium, greaterThanOrEqualTo(20.0));
      expect(pred.availablePotassium, lessThanOrEqualTo(350.0));
      expect(pred.potassiumLevel, isNotNull);

      // Classify tests
      expect(NutrientPrediction.classifyPotassium(30.0), equals(NutrientLevel.veryLow));
      expect(NutrientPrediction.classifyPotassium(65.0), equals(NutrientLevel.low));
      expect(NutrientPrediction.classifyPotassium(110.0), equals(NutrientLevel.moderate));
      expect(NutrientPrediction.classifyPotassium(180.0), equals(NutrientLevel.high));
      expect(NutrientPrediction.classifyPotassium(240.0), equals(NutrientLevel.veryHigh));
    });

    test('6. Integrated Advisor - Potassium (K) and KSB Strain Recommendation', () {
      final lowKPrediction = NutrientPrediction(
        totalNitrogen: 1.60,
        nitrogenLevel: NutrientLevel.moderate,
        availablePhosphorus: 25.0,
        phosphorusLevel: NutrientLevel.moderate,
        availablePotassium: 45.0, // Low K
        potassiumLevel: NutrientLevel.low,
        hardwareMode: NPxAIMode.proChamber,
        confidenceScore: 0.96,
        modelName: 'Soil-ViT',
        predictedAt: DateTime.now(),
      );

      final recommendation = advisorUseCase.generateRecommendation(
        prediction: lowKPrediction,
        cropName: 'ทุเรียนหมอนทอง',
        growthStage: 'ระยะขยายขนาดผล',
      );

      // เมื่อ K ต่ำ ต้องแนะนำสายพันธุ์ KSB (แบคทีเรียละลายโพแทสเซียม) และปุ๋ยโพแทสเซียม
      final hasKsb = recommendation.recommendedStrains
          .any((s) => s.functionalType == 'KSB');
      expect(hasKsb, isTrue);
      expect(recommendation.chemicalFertilizerFormula.contains('0-0-60') ||
             recommendation.chemicalFertilizerFormula.contains('13-0-46'), isTrue);
    });

    test('7. Soil Organic Matter (SOM/OM) - Prediction bounds and DLD Classification', () {
      const signature = SpectralSignature(
        r405nm: 0.14,
        r465nm: 0.20,
        r525nm: 0.26,
        r630nm: 0.35,
        r850nm: 0.44,
        r940nm: 0.48,
        hueMean: 28.0,
        saturationMean: 0.42,
        valueMean: 0.32,
        valueMedian: 0.31,
        calibrationGainFactor: 1.0,
      );

      final pred = aiUseCase.predictNutrients(signature);
      expect(pred.soilOrganicMatter, greaterThanOrEqualTo(0.5));
      expect(pred.soilOrganicMatter, lessThanOrEqualTo(6.0));
      expect(pred.organicMatterLevel, isNotNull);

      // Classify tests according to Land Development Department (DLD) standards
      expect(NutrientPrediction.classifyOrganicMatter(0.8), equals(NutrientLevel.veryLow));
      expect(NutrientPrediction.classifyOrganicMatter(1.3), equals(NutrientLevel.low));
      expect(NutrientPrediction.classifyOrganicMatter(2.1), equals(NutrientLevel.moderate));
      expect(NutrientPrediction.classifyOrganicMatter(3.0), equals(NutrientLevel.high));
      expect(NutrientPrediction.classifyOrganicMatter(4.2), equals(NutrientLevel.veryHigh));
    });
  });
}
