import 'package:flutter/material.dart';
import '../../../domain/models/spectral_signature.dart';
import '../theme/app_theme.dart';

class SpectralCurveCanvas extends StatelessWidget {
  final SpectralSignature signature;

  const SpectralCurveCanvas({super.key, required this.signature});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Vis-NIR Spectral Fingerprint',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textLight,
                ),
              ),
              Text(
                'Gain: ${signature.calibrationGainFactor}x',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.accentLime,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _SpectralPainter(signature),
            ),
          ),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('405nm', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              Text('465nm', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              Text('525nm', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              Text('630nm', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              Text('850nm', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              Text('940nm', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpectralPainter extends CustomPainter {
  final SpectralSignature signature;

  _SpectralPainter(this.signature);

  @override
  void paint(Canvas canvas, Size size) {
    final values = [
      signature.r405nm,
      signature.r465nm,
      signature.r525nm,
      signature.r630nm,
      signature.r850nm,
      signature.r940nm,
    ];

    // วาดเส้นกริดพื้นหลัง
    final gridPaint = Paint()
      ..color = AppTheme.borderDark.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final double stepX = size.width / (values.length - 1);
    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      // ปรับ Scale จากค่า Reflectance 0.0 - 1.0
      final y = size.height - (values[i].clamp(0.0, 1.0) * size.height);
      points.add(Offset(x, y));
    }

    // วาดเส้นกราฟ Gradient
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final linePaint = Paint()
      ..color = AppTheme.accentLime
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // วาดจุดโหนดบนกราฟ
    final dotPaint = Paint()..color = Colors.white;
    final outerDotPaint = Paint()
      ..color = AppTheme.primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final pt in points) {
      canvas.drawCircle(pt, 4.0, dotPaint);
      canvas.drawCircle(pt, 4.0, outerDotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpectralPainter oldDelegate) => true;
}
