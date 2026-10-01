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
      'desc': 'ย่าน UV-A / Soret band ดูดกลืนพันธะคอนจูเกต C=C สารฮิวมัส และไนโตรเจนอินทรีย์',
      'target': 'Total N',
      'shortTarget': 'Total N',
      'band': 'UV',
      'bandColor': Color(0xFF9D4EDD),
      'bandRange': '380–405 nm',
    },
    {
      'wl': '465nm',
      'name': 'Blue (465 nm)',
      'tag': 'Humic Acid',
      'color': Color(0xFF00B4D8),
      'desc': 'ย่าน VIS Blue ดูดกลืนกรดฮิวมิก สารสีแคโรทีนอยด์ และอินทรียวัตถุในดิน (SOM)',
      'target': 'Organic Matter',
      'shortTarget': 'SOM',
      'band': 'VIS',
      'bandColor': Color(0xFF00B4D8),
      'bandRange': '420–700 nm',
    },
    {
      'wl': '525nm',
      'name': 'Green (525 nm)',
      'tag': 'Soil Matrix',
      'color': Color(0xFF2EC4B6),
      'desc': 'ย่าน VIS Green จุดเปลี่ยนผ่านการสะท้อนของคลอโรฟิลล์ และฮิวสีดินมันเซลล์ (Munsell)',
      'target': 'Soil Matrix',
      'shortTarget': 'Matrix',
      'band': 'VIS',
      'bandColor': Color(0xFF00B4D8),
      'bandRange': '420–700 nm',
    },
    {
      'wl': '630nm',
      'name': 'Red (630 nm)',
      'tag': 'Fe-Oxide (P)',
      'color': Color(0xFFFF595E),
      'desc': 'ย่าน VIS Red ดูดกลืน d-d transition ของ Fe3+ (Hematite) สัมพันธ์กับ Available P',
      'target': 'Available P',
      'shortTarget': 'Avail P',
      'band': 'VIS',
      'bandColor': Color(0xFF00B4D8),
      'bandRange': '420–700 nm',
    },
    {
      'wl': '850nm',
      'name': 'NIR 1 (850 nm)',
      'tag': 'Bray-II P Proxy',
      'color': Color(0xFFFF924C),
      'desc': 'ย่าน IR (NIR 1) ดูดกลืนเกอไทต์ Fe-Oxide ไหล่การสั่นสะเทือนของฟอสเฟตในดิน',
      'target': 'Available P',
      'shortTarget': 'Avail P',
      'band': 'IR',
      'bandColor': Color(0xFFFF924C),
      'bandRange': '750–950 nm',
    },
    {
      'wl': '940nm',
      'name': 'NIR 2 (940 nm)',
      'tag': 'H2O / Total N',
      'color': Color(0xFFFFCA3A),
      'desc': 'ย่าน IR (NIR 2) โอเวอร์โทนที่ 3 ของน้ำและความชื้น เชื่อมโยง Total N (Kjeldahl)',
      'target': 'Total N',
      'shortTarget': 'Total N',
      'band': 'IR',
      'bandColor': Color(0xFFFF924C),
      'bandRange': '750–950 nm',
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
            crossAxisAlignment: CrossAxisAlignment.center,
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
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _showAbsorbance
                          ? 'สเปกตรัมการดูดกลืนแสง'
                          : 'สเปกตรัมการสะท้อนแสง',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _showAbsorbance
                          ? 'Absorbance [A = log₁₀(1/R)]'
                          : 'Reflectance [%R]',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: AppTheme.textMuted.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Segmented Toggle
              // Segmented Toggle
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleButton(
                      label: 'Absorb',
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

          const SizedBox(height: 10),

          // แถบจำแนกย่านสเปกตรัม (UV • VIS • IR Spectrum Band Selector)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppTheme.backgroundDark.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderDark.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                _buildBandPill(
                  label: 'UV',
                  sub: '380–405 nm',
                  color: const Color(0xFF9D4EDD),
                  isSelected: meta['band'] == 'UV',
                  onTap: () => setState(() => _selectedPointIndex = 0),
                ),
                const SizedBox(width: 4),
                _buildBandPill(
                  label: 'VIS',
                  sub: '420–700 nm',
                  color: const Color(0xFF00B4D8),
                  isSelected: meta['band'] == 'VIS',
                  onTap: () {
                    if (meta['band'] != 'VIS') {
                      setState(() => _selectedPointIndex = 3); // 630nm
                    }
                  },
                ),
                const SizedBox(width: 4),
                _buildBandPill(
                  label: 'IR (NIR)',
                  sub: '750–950 nm',
                  color: const Color(0xFFFF924C),
                  isSelected: meta['band'] == 'IR',
                  onTap: () {
                    if (meta['band'] != 'IR') {
                      setState(() => _selectedPointIndex = 4); // 850nm
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

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

          // แถบความยาวคลื่นและแท็กธาตุอาหารด้านล่างแกน X (พร้อมป้ายกำกับ UV / VIS / IR)
          Row(
            children: List.generate(_channelMeta.length, (i) {
              final isSel = i == _selectedPointIndex;
              final col = _channelMeta[i]['color'] as Color;
              final bandCol = _channelMeta[i]['bandColor'] as Color;
              final bandName = _channelMeta[i]['band'] as String;

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPointIndex = i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ป้ายย่านคลื่น UV, VIS, IR
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            color: bandCol.withValues(alpha: isSel ? 0.35 : 0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            bandName,
                            style: TextStyle(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w800,
                              color: bandCol,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _channelMeta[i]['wl'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                            color: isSel ? AppTheme.textLight : AppTheme.textMuted,
                          ),
                        ),
                        Text(
                          _channelMeta[i]['shortTarget'] as String? ??
                              _channelMeta[i]['target'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: col,
                          ),
                        ),
                      ],
                    ),
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
              color: AppTheme.backgroundDark.withValues(alpha: 0.7),
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
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: (meta['bandColor'] as Color).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: (meta['bandColor'] as Color).withValues(alpha: 0.5),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              meta['band'] as String,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: meta['bandColor'] as Color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${meta['name']} • ${meta['tag']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: meta['color'] as Color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _showAbsorbance
                                ? 'A = ${currentVal.toStringAsFixed(3)}'
                                : 'R = ${(currentVal * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 11.5,
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

  Widget _buildBandPill({
    required String label,
    required String sub,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.22) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isSelected ? AppTheme.textLight : AppTheme.textMuted,
                ),
              ),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : AppTheme.textMuted.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
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

    // 0. วาดแถบพื้นหลังแบ่ง 3 ย่านคลื่นสเปกตรัม (UV, VIS, IR Spectral Zones)
    final uvVisSplitX = (points[0].dx + points[1].dx) / 2;
    final visIrSplitX = (points[3].dx + points[4].dx) / 2;

    // UV Zone (380 - 420 nm)
    final uvRect = Rect.fromLTRB(padX, 4.0, uvVisSplitX, drawH + 12.0);
    final uvPaint = Paint()..color = const Color(0xFF9D4EDD).withValues(alpha: 0.08);
    canvas.drawRRect(
      RRect.fromRectAndCorners(uvRect, topLeft: const Radius.circular(8), bottomLeft: const Radius.circular(8)),
      uvPaint,
    );

    // VIS Zone (420 - 700 nm)
    final visRect = Rect.fromLTRB(uvVisSplitX, 4.0, visIrSplitX, drawH + 12.0);
    final visPaint = Paint()..color = const Color(0xFF00B4D8).withValues(alpha: 0.05);
    canvas.drawRect(visRect, visPaint);

    // IR Zone (750 - 980 nm)
    final irRect = Rect.fromLTRB(visIrSplitX, 4.0, padX + drawW, drawH + 12.0);
    final irPaint = Paint()..color = const Color(0xFFFF924C).withValues(alpha: 0.08);
    canvas.drawRRect(
      RRect.fromRectAndCorners(irRect, topRight: const Radius.circular(8), bottomRight: const Radius.circular(8)),
      irPaint,
    );

    // วาดเส้นประแนวตั้งแบ่งขอบเขตย่านสเปกตรัม
    final splitLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;
    for (double y = 4.0; y < drawH + 12.0; y += 8.0) {
      canvas.drawLine(Offset(uvVisSplitX, y), Offset(uvVisSplitX, y + 4.0), splitLinePaint);
      canvas.drawLine(Offset(visIrSplitX, y), Offset(visIrSplitX, y + 4.0), splitLinePaint);
    }

    // วาดป้ายข้อความกำกับย่านคลื่น UV, VIS, IR
    void drawZoneLabel(String text, double centerX, Color col) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: 9.0,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: col.withValues(alpha: 0.65),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(centerX - tp.width / 2, 6.0));
    }

    drawZoneLabel('UV', (padX + uvVisSplitX) / 2, const Color(0xFF9D4EDD));
    drawZoneLabel('VIS', (uvVisSplitX + visIrSplitX) / 2, const Color(0xFF00B4D8));
    drawZoneLabel('IR (NIR)', (visIrSplitX + padX + drawW) / 2, const Color(0xFFFF924C));

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
