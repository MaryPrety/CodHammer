// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class RadarChartWidget extends StatelessWidget {
  final Map<String, double> stats;
  final Color glowColor;
  final Color tertiaryColor;
  final Color cardColor;

  const RadarChartWidget({
    super.key,
    required this.stats,
    required this.glowColor,
    required this.tertiaryColor,
    required this.cardColor,
  });

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Вычисляем радиус на основе реального размера контейнера
            // Учитываем padding (16 с каждой стороны = 32 всего)
            final availableSize = constraints.biggest;
            final padding = 16.0;
            final availableWidth = availableSize.width - (padding * 2);
            final availableHeight = availableSize.height - (padding * 2);
            // Используем минимальный размер и делим на 2.5, чтобы получить радиус для позиционирования
            final chartRadius = min(availableWidth, availableHeight) / 2.5;
            
            // Нормализуем значения, чтобы они соответствовали тому, как RadarChart их отображает
            // RadarChart автоматически нормализует значения в диапазон 0.0-1.0
            final statsValues = stats.values.toList();
            final maxValue = statsValues.isEmpty ? 1.0 : statsValues.reduce((a, b) => a > b ? a : b);
            final normalizedStats = <String, double>{};
            final normalizationFactor = maxValue > 0 ? maxValue : 1.0;
            stats.forEach((key, value) {
              normalizedStats[key] = value / normalizationFactor;
            });
            
            return Stack(
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
                        fillColor: Colors.transparent, // Убираем заливку из RadarChart
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

                // Слой заливки - рисуем ПОД кубами, используя нормализованные значения
                Positioned.fill(
                  child: IgnorePointer( // Make fill layer non-interactive
                    child: CustomPaint(
                      painter: FillPainter(
                        points: normalizedStats.values.toList(),
                        color: tertiaryColor,
                        chartRadius: chartRadius,
                      ),
                    ),
                  ),
                ),

                // Слой свечения (Glow layer) - рисуем поверх заливки
                Positioned.fill(
                  child: IgnorePointer( // Make glow layer non-interactive
                    child: CustomPaint(
                      painter: GlowPainter(
                        points: normalizedStats.values.toList(),
                        color: tertiaryColor,
                        chartRadius: chartRadius,
                      ),
                    ),
                  ),
                ),

                // Иконки screw на концах пиков (Screw icons at the peaks) - рисуем поверх всего
                // Используем нормализованные значения для позиционирования
                ..._buildScrewImages(context, normalizedStats, chartRadius), // Pass context and radius to _buildScrewImages
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildScrewImages(BuildContext context, Map<String, double> stats, double chartRadius) {
    final anglePerStat = (2 * pi) / stats.length;
    // Получаем значения в том же порядке, что и ключи
    final statsList = stats.entries.toList();

    return List.generate(stats.length, (index) {
      final value = statsList[index].value; // Используем нормализованное значение
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

// Кастомный painter для заливки пятиугольника - точно соответствует центрам кубов
class FillPainter extends CustomPainter {
  final List<double> points;
  final Color color;
  final double chartRadius;

  FillPainter({
    required this.points,
    required this.color,
    required this.chartRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final anglePerPoint = (2 * pi) / points.length;
    // Используем точно тот же радиус, что и для позиционирования кубов
    final radius = chartRadius;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final angle = anglePerPoint * i - pi / 2;
      // Используем точно тот же расчет, что и для кубов (центр куба)
      final dx = center.dx + radius * points[i] * cos(angle);
      final dy = center.dy + radius * points[i] * sin(angle);
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }
    path.close();

    // Рисуем заливку без эффекта свечения
    final fillPaint = Paint()
      ..color = color.withOpacity(0.25)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant FillPainter oldDelegate) {
    return oldDelegate.points != points || 
           oldDelegate.color != color || 
           oldDelegate.chartRadius != chartRadius;
  }
}

// Кастомный painter для эффекта свечения
class GlowPainter extends CustomPainter {
  final List<double> points;
  final Color color;
  final double chartRadius;

  GlowPainter({
    required this.points,
    required this.color,
    required this.chartRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final anglePerPoint = (2 * pi) / points.length;
    // Используем точно тот же радиус, что и для позиционирования кубов
    final radius = chartRadius;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final angle = anglePerPoint * i - pi / 2;
      // Используем точно тот же расчет, что и для кубов (центр куба)
      final dx = center.dx + radius * points[i] * cos(angle);
      final dy = center.dy + radius * points[i] * sin(angle);
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
    }
    path.close();

    // Рисуем эффект свечения поверх заливки
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
    return oldDelegate.points != points || 
           oldDelegate.color != color || 
           oldDelegate.chartRadius != chartRadius; // ✅ Optimize repaint
  }
}