import 'package:flutter/material.dart';
import '../../../domain/models/nutrient_prediction.dart';
import '../theme/app_theme.dart';
import '../theme/nutrient_color_palette.dart';

class NutrientGaugeCard extends StatelessWidget {
  final String title;
  final String symbol;
  final double value;
  final String unit;
  final NutrientLevel level;
  final double progress; // 0.0 - 1.0
  final String? subtitle;

  const NutrientGaugeCard({
    super.key,
    required this.title,
    required this.symbol,
    required this.value,
    required this.unit,
    required this.level,
    required this.progress,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    // 1. สีอัตลักษณ์ประจำธาตุ (N=ฟ้า, P=ส้ม, K=แดง, OM=เขียว)
    final Color baseElementColor = NutrientColorPalette.getBaseColor(symbol);

    // 2. เฉดสีที่แปรผันตามมาตรฐานการวิเคราะห์ 5 ระดับ (Very Low -> Very High)
    final Color shadeColor = NutrientColorPalette.getNutrientShade(symbol, level);

    // 3. สีสถานะวินิจฉัยสุขภาพดินมาตรฐานสากล สำหรับป้ายระดับ (Status Badge)
    final Color statusColor = NutrientColorPalette.getDiagnosticStatusColor(level);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: shadeColor.withValues(alpha: 0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: shadeColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Symbol (สีประจำธาตุ) + Title + Status Badge (สีตามระดับการวิเคราะห์)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: baseElementColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: baseElementColor.withValues(alpha: 0.45),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        symbol,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: baseElementColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          title,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // ป้ายระดับการวิเคราะห์ เปลี่ยนสีตามมาตรฐานดิน LDD 5 ระดับ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.50),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 3.5),
                    Text(
                      level.shortLabelTh,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 8),
          // ค่าตัวเลข เปลี่ยนเฉดสีตามระดับการวิเคราะห์
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: shadeColor,
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(
                        color: shadeColor.withValues(alpha: 0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // แถบ Progress เปลี่ยนเฉดสีตามระดับการวิเคราะห์
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: AppTheme.borderDark,
              valueColor: AlwaysStoppedAnimation<Color>(shadeColor),
            ),
          ),
        ],
      ),
    );
  }
}
