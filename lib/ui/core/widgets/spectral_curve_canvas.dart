import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../domain/models/spectral_signature.dart';
import '../theme/app_theme.dart';

/// วิดเจ็ตกราฟแสดงผลคุณสมบัติทางสเปกโตรสโกปีของดิน (Soil Spectral Curve Canvas)
/// รองรับทั้งโหมดสเปกตรัมการดูดกลืนแสงของธาตุอาหารพืช (Plant Nutrient Absorbance Spectrum)
/// และโหมดสเปกตรัมการสะท้อนแสง (Reflectance Spectrum)
class SpectralCurveCanvas extends StatefulWidget {
  final SpectralSignature signature;

  const SpectralCurveCanvas({super.key, required this.signature});

  @override
  State<SpectralCurveCanvas> createState() => _SpectralCurveCanvasState();
}

class _SpectralCurveCanvasState extends State<SpectralCurveCanvas> {
  // เริ่มต้นที่โหมดสเปกตรัมการดูดกลืนแสง (Absorbance Mode) ตามสมบัติธาตุอาหารพืช
  bool _showAbsorbance = true;
  int _selectedPointIndex = 3; // ค่าเริ่มต้นที่ 630nm (Available P / Fe3+)

  static const List<Map<String, dynamic>> _channelMeta = [
    {
      'wl': '405nm',
      'name': 'Violet (405 nm)',
      'tag': 'SOM / Organic N',
      'color': Color(0xFF9D4EDD),
      'desc': 'การดูดกลืน Soret band ของฮิวมัส และไนโตรเจนอินทรีย์ในดิน',
      'target': 'Total N',
    },
    {
      'wl': '465nm',
      'name': 'Blue (465 nm)',
      'tag': 'Humic Acid',
      'color': Color(0xFF00B4D8),
      'desc': 'การดูดกลืนสารอินทรีย์ฮิวมิกและแคโรทีนอยด์ในดิน',
      'target': 'Organic Matter',
    },
    {
      'wl': '525nm',
      'name': 'Green (525 nm)',
      'tag': 'Soil Matrix',
      'color': Color(0xFF2EC4B6),
      'desc': 'รอยต่อการสะท้อนของคลอโรฟิลล์และ Munsell soil hue',
      'target': 'Soil Matrix',
    },
    {
      'wl': '630nm',
      'name': 'Red (630 nm)',
      'tag': 'Fe-Oxide (P)',
      'color': Color(0xFFFF595E),
      'desc': 'การดูดกลืนฮีมาไทต์ Fe3+ มีสหสัมพันธ์ตรงกับ Available P (Bray II)',
      'target': 'Available P',
    },
    {
      'wl': '850nm',
      'name': 'NIR 1 (850 nm)',
      'tag': 'Bray-II P Proxy',
      'color': Color(0xFFFF924C),
      'desc': 'การดูดกลืนเกอไทต์ Fe-Oxide ไหล่การสั่นสะเทือนของฟอสเฟต',
      'target': 'Available P',
    },
    {
      'wl': '940nm',
      'name': 'NIR 2 (940 nm)',
      'tag': 'H2O / Total N',
      'color': Color(0xFFFFCA3A),
      'desc': 'โอเวอร์โทนที่ 3 ของน้ำและความชื้น เชื่อมโยง Total N (Kjeldahl)',
      'target': 'Total N',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final meta = _channelMeta[_selectedPointIndex];
    final values = _showAbsorbance
        ? widget.signature.absorbanceList
        : widget.signature.reflectanceList;
    final currentVal = values[_selectedPointIndex];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ส่วนหัวและปุ่มสลับโหมด Absorbance vs Reflectance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _showAbsorbance
                              ? AppTheme.accentLime
                              : Colors.cyanAccent,
                          boxShadow: [
                            BoxShadow(
                              color: (_showAbsorbance
                                      ? AppTheme.accentLime
                                      : Colors.cyanAccent)
                                  .withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _showAbsorbance
                            ? 'สเปกตรัมการดูดกลืนแสงธาตุอาหารพืช'
                            : 'สเปกตรัมการสะท้อนแสงดิน (Vis-NIR)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _showAbsorbance
                        ? 'Beer-Lambert Absorbance [A = log₁₀(1/R)]'
                        : 'Surface Reflectance Factor [%R]',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontFamily: 'monospace',
                      color: AppTheme.textMuted.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              // Segmented Toggle
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: [
                    _buildToggleButton(
                      label: 'Absorbance',
                      isSelected: _showAbsorbance,
                      onTap: () => setState(() => _showAbsorbance = true),
                    ),
                    _buildToggleButton(
                      label: '%Reflect',
                      isSelected: !_showAbsorbance,
                      onTap: () => setState(() => _showAbsorbance = false),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // พื้นที่วาดเส้นกราฟ CustomPaint
          SizedBox(
            height: 155,
            child: GestureDetector(
              onTapDown: (details) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final local = details.localPosition;
                // คำนวณหา index ที่ใกล้เคียงที่สุด
                final step = (box.size.width - 32) / (values.length - 1);
                int closestIdx = (local.dx / step).round().clamp(0, values.length - 1);
                setState(() => _selectedPointIndex = closestIdx);
              },
              child: CustomPaint(
                size: Size.infinite,
                painter: _AdvancedSpectralPainter(
                  values: values,
                  isAbsorbance: _showAbsorbance,
                  selectedIndex: _selectedPointIndex,
                  metaList: _channelMeta,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // แถบความยาวคลื่นและแท็กธาตุอาหารด้านล่างแกน X
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_channelMeta.length, (i) {
              final isSel = i == _selectedPointIndex;
              final col = _channelMeta[i]['color'] as Color;
              return GestureDetector(
                onTap: () => setState(() => _selectedPointIndex = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSel
                        ? col.withValues(alpha: 0.25)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSel ? col : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _channelMeta[i]['wl'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          color: isSel ? AppTheme.textLight : AppTheme.textMuted,
                        ),
                      ),
                      Text(
                        _channelMeta[i]['target'] as String,
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          color: col,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 10),

          // การ์ดรายละเอียดของจุดที่เลือก (Selected Wavelength Diagnostic HUD)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppTheme.bgDark.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (meta['color'] as Color).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 36,
                  decoration: BoxDecoration(
                    color: meta['color'] as Color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${meta['name']} • ${meta['tag']}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: meta['color'] as Color,
                            ),
                          ),
                          Text(
                            _showAbsorbance
                                ? 'A = ${currentVal.toStringAsFixed(3)}'
                                : 'R = ${(currentVal * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentLime,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        meta['desc'] as String,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppTheme.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppTheme.textLight : AppTheme.textMuted,
          ),
        ),
      ),
    );
  }
}

class _AdvancedSpectralPainter extends CustomPainter {
  final List<double> values;
  final bool isAbsorbance;
  final int selectedIndex;
  final List<Map<String, dynamic>> metaList;

  _AdvancedSpectralPainter({
    required this.values,
    required this.isAbsorbance,
    required this.selectedIndex,
    required this.metaList,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // กำหนดระยะขอบซ้ายขวา
    const padX = 12.0;
    final drawW = size.width - padX * 2;
    final drawH = size.height - 18.0;

    // หาค่า Min / Max สำหรับการทำ Scaling
    double minVal = isAbsorbance ? 0.0 : 0.0;
    double maxVal = isAbsorbance ? 1.5 : 1.0;

    // คำนวณพิกัดแต่ละจุด
    final double stepX = drawW / (values.length - 1);
    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final x = padX + i * stepX;
      final normalized = ((values[i] - minVal) / (maxVal - minVal)).clamp(0.05, 0.95);
      final y = drawH - (normalized * drawH) + 8.0;
      points.add(Offset(x, y));
    }

    // 1. วาดเส้นแนวนอนบอกระดับสเกล (Background Grid)
    final gridPaint = Paint()
      ..color = AppTheme.borderDark.withValues(alpha: 0.4)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final y = 8.0 + (drawH * (i / 3.0));
      canvas.drawLine(Offset(padX, y), Offset(padX + drawW, y), gridPaint);
    }

    // 2. วาดเส้นประอ้างอิงคุณสมบัติการดูดกลืนดินเกษตรมาตรฐาน (Reference Baseline)
    if (isAbsorbance) {
      final refValues = [0.85, 0.72, 0.58, 0.44, 0.36, 0.32];
      final refPoints = <Offset>[];
      for (int i = 0; i < refValues.length; i++) {
        final x = padX + i * stepX;
        final norm = ((refValues[i] - minVal) / (maxVal - minVal)).clamp(0.05, 0.95);
        refPoints.add(Offset(x, drawH - (norm * drawH) + 8.0));
      }

      final refPaint = Paint()
        ..color = Colors.cyan.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      // วาดเส้นประอ้างอิง
      for (int i = 0; i < refPoints.length - 1; i++) {
        final p1 = refPoints[i];
        final p2 = refPoints[i + 1];
        canvas.drawLine(p1, Offset(p1.dx + (p2.dx - p1.dx) * 0.6, p1.dy + (p2.dy - p1.dy) * 0.6), refPaint);
      }
    }

    // 3. สร้างเส้นโค้งสมูท Bezier Spline
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    // 4. วาด Gradient Area Fill ใต้เส้นกราฟ
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, drawH + 8.0)
      ..lineTo(points.first.dx, drawH + 8.0)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          isAbsorbance
              ? AppTheme.accentLime.withValues(alpha: 0.35)
              : Colors.cyanAccent.withValues(alpha: 0.35),
          isAbsorbance
              ? AppTheme.primaryGreen.withValues(alpha: 0.0)
              : Colors.blue.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, drawH + 8.0))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 5. วาดเส้นกราฟหลัก
    final linePaint = Paint()
      ..color = isAbsorbance ? AppTheme.accentLime : Colors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // 6. วาดเส้นไกด์แนวดิ่งสำหรับจุดที่เลือก
    final selPt = points[selectedIndex];
    final guidePaint = Paint()
      ..color = (metaList[selectedIndex]['color'] as Color).withValues(alpha: 0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(selPt.dx, 8.0), Offset(selPt.dx, drawH + 8.0), guidePaint);

    // 7. วาดจุดโหนดบนกราฟทุกจุด
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final isSel = i == selectedIndex;
      final dotColor = metaList[i]['color'] as Color;

      if (isSel) {
        // วงแหวนสะท้อนเรืองแสงของจุดที่เลือก
        final haloPaint = Paint()
          ..color = dotColor.withValues(alpha: 0.35)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pt, 9.0, haloPaint);
      }

      final outerPaint = Paint()
        ..color = isSel ? dotColor : (isAbsorbance ? AppTheme.accentLime : Colors.cyanAccent)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSel ? 2.5 : 1.8;

      final innerPaint = Paint()
        ..color = isSel ? Colors.white : AppTheme.cardDark
        ..style = PaintingStyle.fill;

      canvas.drawCircle(pt, isSel ? 5.0 : 3.8, innerPaint);
      canvas.drawCircle(pt, isSel ? 5.0 : 3.8, outerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AdvancedSpectralPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.isAbsorbance != isAbsorbance ||
      oldDelegate.selectedIndex != selectedIndex;
}
