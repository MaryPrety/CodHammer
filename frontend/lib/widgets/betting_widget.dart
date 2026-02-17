// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';

class BettingWidget extends StatelessWidget {
  final double firstRobotPercentage;
  final double secondRobotPercentage;
  final double firstRobotCoefficient;
  final double secondRobotCoefficient;
  final String matchTime;
  final String firstTeamName;
  final String secondTeamName;
  final VoidCallback onFirstRobotTap;
  final VoidCallback onSecondRobotTap;
  final VoidCallback onFirstTeamImageTap;
  final VoidCallback onSecondTeamImageTap;

  const BettingWidget({
    super.key,
    required this.firstRobotPercentage,
    required this.secondRobotPercentage,
    required this.firstRobotCoefficient,
    required this.secondRobotCoefficient,
    required this.matchTime,
    required this.onFirstRobotTap,
    required this.onSecondRobotTap,
    required this.onFirstTeamImageTap,
    required this.onSecondTeamImageTap,
    required this.firstTeamName,
    required this.secondTeamName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.transparent,
      ),
      child: Column(
        children: [
          _buildButtonsRow(context),
          const SizedBox(height: 16),
          _buildPercentageBar(),
        ],
      ),
    );
  }

  Widget _buildButtonsRow(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final buttonWidth = constraints.maxWidth / 4.5;
      final timeButtonWidth = constraints.maxWidth / 4;
      
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: onFirstTeamImageTap,
                child: _buildIconOrImage(_getTeamColor(true), 'assets/weber.png'),
              ),
              const SizedBox(width: 8), // Уменьшаем отступ
              _buildButton(
                width: buttonWidth,
                text: firstRobotCoefficient.toStringAsFixed(2),
                color: _getTeamColor(true),
                onTap: onFirstRobotTap,
              ),
            ],
          ),
          _buildTimeButton(matchTime, width: timeButtonWidth),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildButton(
                width: buttonWidth,
                text: secondRobotCoefficient.toStringAsFixed(2),
                color: _getTeamColor(false),
                onTap: onSecondRobotTap,
              ),
              const SizedBox(width: 8), // Уменьшаем отступ
              GestureDetector(
                onTap: onSecondTeamImageTap,
                child: _buildIconOrImage(_getTeamColor(false), 'assets/au.jpg'),
              ),
            ],
          ),
        ],
      );
    },
  );
}

  Widget _buildButton({
  required String text,
  required Color color,
  required VoidCallback onTap,
  double? width,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: width ?? 80, // Используем переданную ширину или значение по умолчанию
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4), // Уменьшаем горизонтальный padding
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Center(
        child: FittedBox( // Добавляем FittedBox для автоматического масштабирования текста
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color.fromRGBO(69, 105, 109, 0.867),
              fontFamily: 'Cornerita',
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildTimeButton(String time, {double? width}) {
  return Container(
    width: width ?? 90, 
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFD8CCFF),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFD8CCFF).withOpacity(0.7), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFD8CCFF).withOpacity(0.3),
          blurRadius: 6,
          spreadRadius: 3,
        ),
      ],
    ),
    child: Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          time,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color.fromRGBO(69, 105, 109, 0.867),
            fontFamily: 'Cornerita',
          ),
        ),
      ),
    ),
  );
}

  Widget _buildIconOrImage(Color color, String imagePath) {
    return Container(
      width: 25,
      height: 25,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.7), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildPercentageBar() {
    final bool isFirstRobotDominant = firstRobotPercentage > secondRobotPercentage;

    // Определяем цвета для доминирующей и противоположной команд
    final Color dominantColor = isFirstRobotDominant ? _getTeamColor(true) : _getTeamColor(false);
    final Color oppositeColor = isFirstRobotDominant ? _getTeamColor(false) : _getTeamColor(true);

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: oppositeColor, // Цвет фона теперь соответствует НЕ доминирующей команде
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFCDFBE4).withOpacity(0.3),
                blurRadius: 6,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        Align(
          alignment: isFirstRobotDominant ? Alignment.centerLeft : Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: isFirstRobotDominant
                ? firstRobotPercentage / 100
                : secondRobotPercentage / 100,
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                borderRadius: isFirstRobotDominant
                    ? const BorderRadius.horizontal(left: Radius.circular(10))
                    : const BorderRadius.horizontal(right: Radius.circular(10)),
                color: dominantColor, // Цвет заполнения теперь соответствует доминирующей команде
              ),
            ),
          ),
        ),
        Text(
          '${isFirstRobotDominant ? firstRobotPercentage.toStringAsFixed(0) : secondRobotPercentage.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color.fromRGBO(69, 105, 109, 0.867),
            fontFamily: 'Cornerita', // Используем пользовательский шрифт
          ),
        ),
      ],
    );
  }

  // Метод для получения цвета в зависимости от команды
  Color _getTeamColor(bool isFirstTeam) {
    return isFirstTeam ? const Color(0xFFCDFBE4) : const Color(0xFFFAEFD9);
  }
}