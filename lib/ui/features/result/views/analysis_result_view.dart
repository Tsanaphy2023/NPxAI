import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/models/nutrient_prediction.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/nutrient_gauge_card.dart';
import '../../../core/widgets/spectral_curve_canvas.dart';
import '../view_models/analysis_result_view_model.dart';

class AnalysisResultView extends StatelessWidget {
  final AnalysisResultViewModel viewModel;
  final VoidCallback onNavigateToAdvisor;

  const AnalysisResultView({
    super.key,
    required this.viewModel,
    required this.onNavigateToAdvisor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final bool isCompact = screenWidth < 360;

        return ListenableBuilder(
          listenable: viewModel,
          builder: (context, _) {
            final sample = viewModel.sample;
            final prediction = viewModel.prediction;

            if (sample == null || prediction == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics_outlined,
                          size: 64, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        'ยังไม่มีข้อมูลการวิเคราะห์ล่าสุด',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'กรุณากลับไปที่แท็บ "สแกนดิน" เพื่อเริ่มกระบวนการสแกนสเปกตรัมและประมวลผล AI',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              );
            }

            final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss น.');

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 12.0 : 16.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. หัวข้อตัวอย่างดิน พิกัด GPS วันเวลา ชนิดพืช และประเภทสวน
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                sample.id,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentLime,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'ความเชื่อมั่น R²: ${prediction.confidenceScore}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentLime,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            sample.plotName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Badges: ชนิดพืช & ประเภทสวน & โมเดล AI
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.primaryGreen),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.eco, size: 13, color: AppTheme.accentLime),
                                    const SizedBox(width: 4),
                                    Text(
                                      'พืช: ${sample.cropType}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentAmber.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.accentAmber.withValues(alpha: 0.5)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.grass, size: 13, color: AppTheme.accentAmber),
                                    const SizedBox(width: 4),
                                    Text(
                                      'ระบบสวน: ${sample.farmingType}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.accentAmber,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (prediction.modelName.contains('SIMULATION')
                                          ? AppTheme.accentAmber
                                          : Colors.blueAccent)
                                      .withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: (prediction.modelName.contains('SIMULATION')
                                            ? AppTheme.accentAmber
                                            : Colors.blueAccent)
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      prediction.modelName.contains('SIMULATION')
                                          ? Icons.science_outlined
                                          : Icons.psychology_rounded,
                                      size: 13,
                                      color: prediction.modelName.contains('SIMULATION')
                                          ? AppTheme.accentAmber
                                          : Colors.lightBlueAccent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'โมเดล: ${prediction.modelName}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: prediction.modelName.contains('SIMULATION')
                                            ? AppTheme.accentAmber
                                            : Colors.lightBlueAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (prediction.hardwareMode == NPxAIMode.liteFlash
                                          ? Colors.deepOrangeAccent
                                          : AppTheme.accentLime)
                                      .withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: (prediction.hardwareMode == NPxAIMode.liteFlash
                                            ? Colors.deepOrangeAccent
                                            : AppTheme.accentLime)
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      prediction.hardwareMode == NPxAIMode.liteFlash
                                          ? Icons.flash_on_rounded
                                          : Icons.biotech_rounded,
                                      size: 13,
                                      color: prediction.hardwareMode == NPxAIMode.liteFlash
                                          ? Colors.deepOrangeAccent
                                          : AppTheme.accentLime,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'โหมด: ${prediction.hardwareMode.shortLabelTh}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: prediction.hardwareMode == NPxAIMode.liteFlash
                                            ? Colors.deepOrangeAccent
                                            : AppTheme.accentLime,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: AppTheme.borderDark, height: 18),
                          // พิกัด GPS & วันเวลา
                          Row(
                            children: [
                              const Icon(Icons.satellite_alt,
                                  size: 14, color: AppTheme.accentLime),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  'GPS: ${sample.latitude.abs().toStringAsFixed(6)}°${sample.latitude >= 0 ? "N" : "S"}, ${sample.longitude.abs().toStringAsFixed(6)}°${sample.longitude >= 0 ? "E" : "W"}',
                                  style: TextStyle(
                                    fontSize: isCompact ? 10.5 : 11.5,
                                    fontFamily: 'monospace',
                                    color: AppTheme.textLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.schedule,
                                  size: 14, color: AppTheme.textMuted),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  'เวลาที่วิเคราะห์: ${dateFormat.format(sample.measuredAt)}',
                                  style: TextStyle(
                                    fontSize: isCompact ? 10.5 : 11.5,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. การ์ดแสดงผลธาตุอาหารหลัก 4 พารามิเตอร์: N, P, K และ OM / SOM (Symmetric 2x2 Grid)
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: NutrientGaugeCard(
                              title: 'Total N',
                              symbol: 'N',
                              subtitle: 'ไนโตรเจนรวม (Kjeldahl)',
                              value: prediction.totalNitrogen,
                              unit: 'g/kg',
                              level: prediction.nitrogenLevel,
                              progress: (prediction.totalNitrogen / 3.0).clamp(0.0, 1.0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: NutrientGaugeCard(
                              title: 'Available P',
                              symbol: 'P',
                              subtitle: 'ฟอสฟอรัส (Bray II)',
                              value: prediction.availablePhosphorus,
                              unit: 'mg/kg',
                              level: prediction.phosphorusLevel,
                              progress: (prediction.availablePhosphorus / 60.0).clamp(0.0, 1.0),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: NutrientGaugeCard(
                              title: 'Available K',
                              symbol: 'K',
                              subtitle: 'โพแทสเซียม (NH₄OAc)',
                              value: prediction.availablePotassium,
                              unit: 'mg/kg',
                              level: prediction.potassiumLevel,
                              progress: (prediction.availablePotassium / 200.0).clamp(0.0, 1.0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: NutrientGaugeCard(
                              title: 'Soil OM',
                              symbol: 'OM',
                              subtitle: 'อินทรียวัตถุ (Walkley-Black)',
                              value: prediction.soilOrganicMatter,
                              unit: '%',
                              level: prediction.organicMatterLevel,
                              progress: (prediction.soilOrganicMatter / 5.0).clamp(0.0, 1.0),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 3. กราฟสเปกตรัม Vis-NIR (Responsive)
                  if (sample.spectralSignature != null)
                    SpectralCurveCanvas(signature: sample.spectralSignature!),
                  const SizedBox(height: 14),

                  // 4. ปุ่มเชื่อมต่อไปยังระบบแนะนำปุ๋ยและชีวภัณฑ์
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: onNavigateToAdvisor,
                    icon: const Icon(Icons.eco),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('ดูคำแนะนำปุ๋ยสั่งตัดและชีวภัณฑ์จุลินทรีย์ดิน'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 5. ปุ่มส่งออก CSV
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textLight,
                      side: const BorderSide(color: AppTheme.borderDark),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final csv = viewModel.getCsvExport();
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppTheme.cardDark,
                          title: const Text('รายงานข้อมูลการวัด (CSV Format)'),
                          content: SingleChildScrollView(
                            child: SelectableText(
                              csv,
                              style: const TextStyle(
                                  fontFamily: 'monospace', fontSize: 11),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('ปิด'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('ส่งออกข้อมูล CSV / เชื่อมต่อ Google Drive'),
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
