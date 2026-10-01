import '../models/bio_fertilizer_recommendation.dart';
import '../models/nutrient_prediction.dart';

/// Use Case: การประมวลผลคำแนะนำปุ๋ยแบบบูรณาการ (Integrated Bio-Chemical Fertilizer Advisor)
/// บูรณาการผลผลิตโครงการย่อยที่ 1 (จุลชีววิทยา PSB/NFB) และโครงการย่อยที่ 2 (AI วัดธาตุอาหาร)
class IntegratedAdvisorUseCase {
  /// ฐานข้อมูลสายพันธุ์จุลินทรีย์เด่นจากโครงการย่อยที่ 1 (คัดแยกจากดินเกษตรอินทรีย์ จันทบุรี/ตราด)
  static final List<MicrobeStrainInfo> localMicrobeStrains = [
    const MicrobeStrainInfo(
      strainCode: 'RBRU-PSB-01',
      scientificName: 'Burkholderia vietnamiensis (Chanthaburi native)',
      functionalType: 'PSB',
      efficacyScore: 185.4, // ละลายฟอสเฟตได้ 185.4 mg P/L ในห้องปฏิบัติการ
      isolationSource: 'สวนทุเรียนอินทรีย์ ต.มะขาม อ.มะขาม จ.จันทบุรี',
      applicationMethod:
          'ผสมชีวภัณฑ์ 50 มล. ต่อน้ำ 20 ลิตร ราดโคนต้นรัศมีทรงพุ่มทุก 15-30 วัน',
    ),
    const MicrobeStrainInfo(
      strainCode: 'RBRU-PSB-04',
      scientificName: 'Bacillus megaterium (Eastern strain)',
      functionalType: 'PSB',
      efficacyScore: 162.8,
      isolationSource: 'สวนมังคุด ต.สองพี่น้อง อ.ท่าใหม่ จ.จันทบุรี',
      applicationMethod:
          'คลุกปุ๋ยหมักชีวภาพอัตรา 1 กก. ต่อต้นช่วงต้นฤดูฝน ช่วยปลดปล่อยฟอสฟอรัสที่ตกค้าง',
    ),
    const MicrobeStrainInfo(
      strainCode: 'RBRU-NFB-02',
      scientificName: 'Azotobacter beijerinckii (High nitrogen-fixer)',
      functionalType: 'NFB',
      efficacyScore: 42.6, // ผลิตแอมโมเนียม 42.6 mg NH4+/L
      isolationSource: 'แปลงเกษตรธรรมชาติ ต.ประณีต อ.เขาสมิง จ.ตราด',
      applicationMethod:
          'ฉีดพ่นทางดินช่วงแตกใบอ่อน ร่วมกับฮิวมิคแอซิดเพื่อเป็นแหล่งพลังงานคาร์บอน',
    ),
    const MicrobeStrainInfo(
      strainCode: 'RBRU-NFB-05',
      scientificName: 'Beijerinckia indica (Acid-tolerant N-fixer)',
      functionalType: 'NFB',
      efficacyScore: 38.9,
      isolationSource: 'ดินสวนทุเรียนดินกรดภูเขาไฟ จ.จันทบุรี (pH 4.8)',
      applicationMethod:
          'ราดลงดินหลังเก็บเกี่ยวผลผลิต ช่วยตรึงไนโตรเจนจากอากาศในสภาพดินกรดจัด',
    ),
  ];

  /// สร้างคำแนะนำแบบสั่งตัดสำหรับพืชเศรษฐกิจ (เช่น ทุเรียน, มังคุด, เงาะ)
  BioFertilizerRecommendation generateRecommendation({
    required NutrientPrediction prediction,
    required String cropName,
    required String growthStage,
  }) {
    String chemicalFormula = '16-16-16';
    double rateKg = 1.0;
    String guide = '';
    double savingPercent = 15.0;
    final List<MicrobeStrainInfo> strains = [];
    String bioPlan = '';

    final bool isLowN = prediction.nitrogenLevel == NutrientLevel.veryLow ||
        prediction.nitrogenLevel == NutrientLevel.low;
    final bool isLowP = prediction.phosphorusLevel == NutrientLevel.veryLow ||
        prediction.phosphorusLevel == NutrientLevel.low;
    final bool isHighP = prediction.phosphorusLevel == NutrientLevel.high ||
        prediction.phosphorusLevel == NutrientLevel.veryHigh;

    // ตรรกะวิเคราะห์ปุ๋ยเคมีร่วมกับสถานะ N/P
    if (isLowN && isLowP) {
      chemicalFormula = '15-15-15 หรือ 16-16-16';
      rateKg = 1.2;
      guide =
          'ดินขาดทั้งไนโตรเจนและฟอสฟอรัส ใส่ปุ๋ยเคมีรองพื้นปริมาณพอเหมาะ แบ่งใส่ 2 ครั้ง พร้อมปรับปรุงอินทรียวัตถุ';
      savingPercent = 15.0;
      strains.addAll([localMicrobeStrains[0], localMicrobeStrains[2]]);
      bioPlan =
          'ใช้ชีวภัณฑ์คู่ผสม: เสริมแบคทีเรียตรึง N (RBRU-NFB-02) เพื่อดึง N2 อากาศ และแบคทีเรียละลาย P (RBRU-PSB-01) ช่วยให้รากดูดซึมปุ๋ยได้ไว';
    } else if (isLowP && !isLowN) {
      chemicalFormula = 'ลดสัดส่วนปุ๋ยฟอสเฟตเคมีลง 40% และใช้ปุ๋ยเดี่ยวสูตร 25-7-7 หรือ 46-0-0 เฉพาะที่จำเป็น';
      rateKg = 0.8;
      guide =
          'ฟอสฟอรัสในรูปละลายน้ำมีจำกัด แต่ในดินจันทบุรีมักมีฟอสฟอรัสสะสมที่จับกับเหล็กและอะลูมิเนียม ไม่ควรเพิ่มปุ๋ย P เคมีมากเกินไป';
      savingPercent = 25.0;
      strains.add(localMicrobeStrains[0]);
      strains.add(localMicrobeStrains[1]);
      bioPlan =
          '★ พระเอกหลัก: ใช้แบคทีเรียละลายฟอสเฟต PSB (RBRU-PSB-01 / 04) เพื่อย่อยสลาย P อนินทรีย์ที่จับตัวแน่นในดิน ให้เปลี่ยนเป็นรูป Available P ที่รากพืชดูดซึมได้ทันที';
    } else if (isLowN && !isLowP) {
      chemicalFormula = 'ใช้ปุ๋ยตัวหน้าสูง เช่น 25-7-7 หรือ ยูเรีย 46-0-0 ผสมปุ๋ยหมักชีวภาพ';
      rateKg = 0.9;
      guide = 'ฟอสฟอรัสมีเพียงพอแล้ว งดใส่ปุ๋ยฟอสเฟตเพิ่มเติมเพื่อป้องกันธาตุอาหารตกค้างและชะล้างลงแหล่งน้ำ';
      savingPercent = 20.0;
      strains.add(localMicrobeStrains[2]);
      strains.add(localMicrobeStrains[3]);
      bioPlan =
          '★ ใส่ชีวภัณฑ์ NFB สายพันธุ์ทนดินกรด (RBRU-NFB-05) ช่วยสร้างสะสมไนโตรเจนทางชีวภาพ ลดการใส่ยูเรียเคมีลงได้ 20-30%';
    } else if (isHighP) {
      chemicalFormula = 'งดใส่ปุ๋ยฟอสเฟต (งด 0-3-0 หรือตัวกลาง) ใส่เฉพาะ 13-0-46 หรือโพแทสเซียมตามระยะพืช';
      rateKg = 0.5;
      guide =
          'ฟอสฟอรัสในดินสะสมสูงมากเกินเกณฑ์ (Over-fertilization) ควรงดปุ๋ยเคมีฟอสเฟตเด็ดขาด เพื่อรักษาสิ่งแวดล้อมและลดต้นทุน';
      savingPercent = 35.0;
      strains.add(localMicrobeStrains[0]);
      bioPlan =
          'ใช้จุลินทรีย์ช่วยปรับสมดุลและลดการปลดปล่อย P ส่วนเกินลงสู่น้ำใต้ดิน เสริมจุลินทรีย์กลุ่มยับยั้งเชื้อราก่อโรครากเน่า (คุณสมบัติ PGPR)';
    } else {
      chemicalFormula = '16-16-16 ในอัตราปกติ หรือปุ๋ยอินทรีย์เคมี';
      rateKg = 0.7;
      guide = 'ดินมีความอุดมสมบูรณ์ของ N และ P ในเกณฑ์ปานกลางที่เหมาะสม รักษาหน้าดินด้วยเศษอินทรียวัตถุ';
      savingPercent = 18.0;
      strains.add(localMicrobeStrains[1]);
      strains.add(localMicrobeStrains[3]);
      bioPlan =
          'เติมชีวภัณฑ์เพื่อการรักษาสมดุลนิเวศวิทยาจุลินทรีย์ดินและเสริมความต้านทานโรค';
    }

    return BioFertilizerRecommendation(
      cropName: cropName,
      growthStage: growthStage,
      prediction: prediction,
      chemicalFertilizerFormula: chemicalFormula,
      chemicalRateKgPerRai: rateKg,
      chemicalApplicationGuide: guide,
      estimatedCostReductionPercent: savingPercent,
      recommendedStrains: strains,
      bioInoculantActionPlan: bioPlan,
      environmentalImpactNotice:
          'สอดคล้องกับ SDG 2, 9, 12: การจัดการตามคำแนะนำนี้ช่วยลดมลพิษจากการชะล้างธาตุอาหารลงแหล่งน้ำ และลดต้นทุนการผลิต 10-35%',
    );
  }
}
