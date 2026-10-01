import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../view_models/fertilizer_advisor_view_model.dart';

class FertilizerAdvisorView extends StatelessWidget {
  final FertilizerAdvisorViewModel viewModel;

  const FertilizerAdvisorView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final bool isCompact = screenWidth < 360;

        return ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) {
            final recom = viewModel.recommendation;

            if (recom == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.eco_outlined,
                          size: 64, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        'ยังไม่มีคำแนะนำการจัดการปุ๋ย',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'กรุณาทำการสแกนดินในแท็บ "สแกนดิน" ก่อนเพื่อรับคำแนะนำแบบสั่งตัดเฉพาะแปลง',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12.0 : 16.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. หัวข้อพืชและระยะการเจริญเติบโต
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  recom.cropName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentLime,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentAmber.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'ประหยัดปุ๋ยเคมีได้ ~${recom.estimatedCostReductionPercent.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentAmber,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'เลือกระยะการเจริญเติบโตของพืช:',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: viewModel.selectedGrowthStage,
                            isExpanded: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.backgroundDark,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    const BorderSide(color: AppTheme.borderDark),
                              ),
                            ),
                            items: viewModel.availableGrowthStages
                                .map((stage) => DropdownMenuItem(
                                    value: stage,
                                    child: Text(stage,
                                        style: TextStyle(
                                            fontSize: isCompact ? 12 : 13))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                viewModel.setGrowthStage(
                                  val,
                                  recom.prediction,
                                  recom.cropName,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. ส่วนที่ 1: คำแนะนำปุ๋ยเคมีสั่งตัด
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.science, color: AppTheme.accentLime, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '1. คำแนะนำปุ๋ยเคมีสั่งตัด (Chemical Fertilizer)',
                                  style: TextStyle(
                                    fontSize: isCompact ? 12 : 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: AppTheme.borderDark, height: 18),
                          Text(
                            'สูตรปุ๋ยแนะนำ: ${recom.chemicalFertilizerFormula}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentLime,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'อัตราการใส่: ${recom.chemicalRateKgPerRai} กก./ต้น หรือ กก./ไร่',
                            style: const TextStyle(fontSize: 12.5, color: AppTheme.textLight),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            recom.chemicalApplicationGuide,
                            style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3. ส่วนที่ 2: คำแนะนำชีวภัณฑ์จุลินทรีย์ดิน (โครงการย่อยที่ 1)
                  Card(
                    color: const Color(0xFF142C20),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.biotech, color: AppTheme.accentLime, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '2. คำแนะนำชีวภัณฑ์จุลินทรีย์ดิน (โครงการย่อยที่ 1)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            recom.bioInoculantActionPlan,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textLight,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'สายพันธุ์จุลินทรีย์เด่นที่คัดเลือกจากพื้นที่จันทบุรี/ตราด:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentLime,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...recom.recommendedStrains.map((strain) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardDark,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.borderDark),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${strain.strainCode}: ${strain.scientificName}',
                                            style: TextStyle(
                                              fontSize: isCompact ? 11 : 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textLight,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: strain.functionalType == 'PSB'
                                                ? Colors.purple.withValues(alpha: 0.2)
                                                : Colors.blue.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            strain.functionalType,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: strain.functionalType == 'PSB'
                                                  ? Colors.purpleAccent
                                                  : Colors.lightBlueAccent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'แหล่งคัดแยก: ${strain.isolationSource}',
                                      style: TextStyle(
                                          fontSize: isCompact ? 10 : 11,
                                          color: AppTheme.textMuted),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'วิธีใช้: ${strain.applicationMethod}',
                                      style: TextStyle(
                                          fontSize: isCompact ? 10 : 11,
                                          color: AppTheme.accentLime),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. ผลกระทบต่อสิ่งแวดล้อมและความยั่งยืน
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderDark),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.public, color: AppTheme.accentLime, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            recom.environmentalImpactNotice,
                            style: TextStyle(
                                fontSize: isCompact ? 10 : 11,
                                color: AppTheme.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
