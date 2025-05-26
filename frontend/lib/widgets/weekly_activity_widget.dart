// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class WeeklyActivityWidget extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyData;
  final List<Color> attendanceGradient;
  final List<Color> hackathonsGradient;
  final List<Color> pollsGradient;
  final Color cardColor;

  const WeeklyActivityWidget({
    super.key,
    required this.weeklyData,
    required this.attendanceGradient,
    required this.hackathonsGradient,
    required this.pollsGradient,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChartLegend(),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: weeklyData.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final data = weeklyData[index];
                return _buildDailyChart(
                  data['day'],
                  data['attendance'].toDouble(),
                  data['hackathons'].toDouble(),
                  data['polls'].toDouble(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Строит легенду графика
  Widget _buildChartLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildLegendItem(attendanceGradient[0], 'Attendance'),
        _buildLegendItem(hackathonsGradient[0], 'Hackathons'),
        _buildLegendItem(pollsGradient[0], 'Polls'),
      ],
    );
  }

  /// Строит график активности за один день
  Widget _buildDailyChart(String day, double attendance, double hackathons, double polls) {
    // Фильтруем данные, чтобы исключить нулевые значения
    final List<Map<String, dynamic>> filteredData = [
      {'value': polls, 'gradient': pollsGradient},
      {'value': hackathons, 'gradient': hackathonsGradient},
      {'value': attendance, 'gradient': attendanceGradient},
    ].where((data) => double.tryParse(data['value'].toString()) != null && double.parse(data['value'].toString()) > 0).toList();

    // Если все значения равны 0, показываем одну ячейку с текстом "0"
    if (filteredData.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 50,
            height: 150,
                        child: Center(
              child: Text(
                '0',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            day,
            style: const TextStyle(
              color: Color.fromRGBO(205, 251, 228, 1),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 50,
          height: 150,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: filteredData.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              final isTop = index == 0; // Верхняя граница для первого элемента
              final isBottom = index == filteredData.length - 1; // Нижняя граница для последнего элемента

              return _buildFullHeightBar(
                data['value'],
                data['gradient'],
                '${data['value'].toInt()}',
                isTop: isTop,
                isBottom: isBottom,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: const TextStyle(
            color: Color.fromRGBO(205, 251, 228, 1),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Строит столбец для одного значения активности
  Widget _buildFullHeightBar(double value, List<Color> colors, String label, {bool isTop = false, bool isBottom = false}) {
    // Рассчитываем flex на основе максимального значения 8 часов
    int flexValue = (value / 8 * 100).toInt();

    // Если значение равно 0, то flex = 0
    if (value <= 0) {
      flexValue = 0;
    }

    return Expanded(
      flex: flexValue,
      child: Container(
        width: 40,
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.vertical(
            top: isTop ? Radius.circular(6) : Radius.zero,
            bottom: isBottom ? Radius.circular(6) : Radius.zero,
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.last.withOpacity(0.4),
              blurRadius: 4,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF062B42),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// Строит элемент легенды
  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Color.fromRGBO(205, 251, 228, 1),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}