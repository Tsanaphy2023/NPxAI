import 'nutrient_prediction.dart';

/// ข้อมูลสายพันธุ์จุลินทรีย์ท้องถิ่นที่มีศักยภาพสูง (จากโครงการย่อยที่ 1)
class MicrobeStrainInfo {
  final String strainCode; // เช่น "RBRU-PSB-01"
  final String scientificName; // เช่น "Burkholderia vietnamiensis"
  final String functionalType; // "PSB" (ละลายฟอสเฟต) หรือ "NFB" (ตรึงไนโตรเจน)
  final double efficacyScore; // ประสิทธิภาพ (mg/L ละลาย P หรือผลิต NH4+)
  final String isolationSource; // เช่น "สวนผลไม้เกษตรอินทรีย์ อ.มะขาม จ.จันทบุรี"
  final String applicationMethod; // วิธีการคลุกดินหรือฉีดพ่นราก

  const MicrobeStrainInfo({
    required this.strainCode,
    required this.scientificName,
    required this.functionalType,
    required this.efficacyScore,
    required this.isolationSource,
    required this.applicationMethod,
  });
}

/// คำแนะนำปุ๋ยแบบบูรณาการ (ปุ๋ยเคมีสั่งตัด + ชีวภัณฑ์จุลินทรีย์ดิน)
class BioFertilizerRecommendation {
  final String cropName;
  final String growthStage; // เช่น ระยะสะสมอาหาร, ระยะฟื้นต้นหลังเก็บเกี่ยว, ระยะติดผล
  final NutrientPrediction prediction;

  /// คำแนะนำปุ๋ยเคมีสั่งตัด
  final String chemicalFertilizerFormula; // เช่น "16-16-16", "46-0-0"
  final double chemicalRateKgPerRai; // อัตรา กก./ไร่ หรือ กรัม/ต้น
  final String chemicalApplicationGuide;
  final double estimatedCostReductionPercent; // ร้อยละการประหยัดปุ๋ยเคมี (10-30%)

  /// คำแนะนำชีวภัณฑ์จุลินทรีย์ (จากผลการวิจัยโครงการย่อยที่ 1)
  final List<MicrobeStrainInfo> recommendedStrains;
  final String bioInoculantActionPlan;
  final String environmentalImpactNotice;

  const BioFertilizerRecommendation({
    required this.cropName,
    required this.growthStage,
    required this.prediction,
    required this.chemicalFertilizerFormula,
    required this.chemicalRateKgPerRai,
    required this.chemicalApplicationGuide,
    required this.estimatedCostReductionPercent,
    required this.recommendedStrains,
    required this.bioInoculantActionPlan,
    required this.environmentalImpactNotice,
  });
}
