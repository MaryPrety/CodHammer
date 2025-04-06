import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class RadarChartWidget extends StatelessWidget {
  final Map<String, double> stats;
  final Color glowColor;
  final Color tertiaryColor;
  final Color cardColor;

  const RadarChartWidget({
    Key? key,
    required this.stats,
    required this.glowColor,
    required this.tertiaryColor,
    required this.cardColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            RadarChart(
              RadarChartData(
                radarTouchData: RadarTouchData(enabled: true),
                titlePositionPercentageOffset: 0.2,
                radarShape: RadarShape.polygon,
                tickCount: 5,

                // ✅ Скрываем цифры тиков (Hide tick numbers)
                ticksTextStyle: const TextStyle(color: Colors.transparent),

                // ✅ Цвет многоугольников (glowColor с прозрачностью) (Polygon color - glowColor with transparency)
                tickBorderData: BorderSide(
                  color: glowColor.withOpacity(0.25), // Прозрачнее (More transparent)
                  width: 3,
                ),

                // ✅ Цвет внешнего пятиугольника (контур) (Outer pentagon color - border)
                radarBorderData: BorderSide(
                  color: glowColor.withOpacity(0.25),
                  width: 3,
                ),

                // ✅ Цвет направляющих от центра к пикам (Guiding lines from center to peaks color)
                gridBorderData: BorderSide(
                  color: glowColor.withOpacity(0.2),
                  width: 1.5,
                ),

                radarBackgroundColor: Colors.transparent,

                dataSets: [
                  RadarDataSet(
                    dataEntries: stats.entries
                        .map((e) => RadarEntry(value: e.value))
                        .toList(),
                    fillColor: tertiaryColor.withOpacity(0.25),
                    borderColor: Colors.transparent,
                    borderWidth: 0,
                    entryRadius: 0,
                  ),
                ],
                titleTextStyle: TextStyle(
                  color: tertiaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                getTitle: (index, angle) {
                  final titles = stats.keys.toList();
                  return RadarChartTitle(
                    text: titles[index],
                    angle: angle,
                  );
                },
              ),
            ),

            // Слой свечения (Glow layer)
            Positioned.fill(
              child: IgnorePointer( // Make glow layer non-interactive
                child: CustomPaint(
                  painter: GlowPainter(
                    points: stats.values.toList(),
                    color: tertiaryColor,
                  ),
                ),
              ),
            ),

            // Иконки screw на концах пиков (Screw icons at the peaks)
            ..._buildScrewImages(context, stats), // Pass context to _buildScrewImages
          ],
        ),
      ),
    );
  }

  List<Widget> _buildScrewImages(BuildContext context, Map<String, double> stats) {
    final anglePerStat = (2 * pi) / stats.length;
    final chartRadius = MediaQuery.of(context).size.width / 2.5; // Responsive radius based on screen width

    return List.generate(stats.length, (index) {
      final value = stats.values.elementAt(index);
      final angle = anglePerStat * index - pi / 2;
      final dx = chartRadius * value * cos(angle);
      final dy = chartRadius * value * sin(angle);

      return Positioned.fill(
        child: Align(
          alignment: Alignment.center,
          child: Transform.translate(
            offset: Offset(dx, dy),
            child: Image.asset(
              'assets/screw.png',
              width: 26,
              height: 26,
              errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                // ✅ Error handling for asset loading
                print('Error loading asset: assets/screw.png');
                return const Icon(Icons.error_outline, color: Colors.red); // Show error icon
              },
            ),
          ),
        ),
      );
    });
  }
}

class GlowPainter extends CustomPainter {
  final List<double> points;
  final Color color;

  GlowPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final anglePerPoint = (2 * pi) / points.length;
    final radius = size.width / 2.2; // Radius of glow effect, adjust as needed

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final angle = anglePerPoint * i - pi / 2;
      final dx = center.dx + radius * points[i] * cos(angle);
      final dy = center.dy + radius * points[i] * sin(angle);
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }
    path.close();

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(0.7), // Slightly brighter glow
          color.withOpacity(0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.8)) // Smaller radius for gradient
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25) // Increased blur for softer glow
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(covariant GlowPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color; // ✅ Optimize repaint
  }
}