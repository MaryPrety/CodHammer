import 'package:flutter/material.dart';

class BettingWidget extends StatefulWidget {
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
    Key? key,
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
  }) : super(key: key);

  @override
  _BettingWidgetState createState() => _BettingWidgetState();
}

class _BettingWidgetState extends State<BettingWidget> {
  bool _isRussian = true; // Состояние для переключения языка

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isRussian = !_isRussian; // Переключаем язык при нажатии
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.transparent,
        ),
        child: Column(
          children: [
            _buildButtonsRow(),
            const SizedBox(height: 16),
            _buildPercentageBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: widget.onFirstTeamImageTap,
              child: _buildIconOrImage(_getTeamColor(true), 'assets/weber.png'),
            ),
            const SizedBox(width: 26),
            _buildButton(
              text: widget.firstRobotCoefficient.toStringAsFixed(2),
              color: _getTeamColor(true),
              onTap: widget.onFirstRobotTap,
            ),
          ],
        ),
        _buildTimeButton(widget.matchTime), // Передаем только время матча
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildButton(
              text: widget.secondRobotCoefficient.toStringAsFixed(2),
              color: _getTeamColor(false),
              onTap: widget.onSecondRobotTap,
            ),
            const SizedBox(width: 26),
            GestureDetector(
              onTap: widget.onSecondTeamImageTap,
              child: _buildIconOrImage(_getTeamColor(false), 'assets/au.jpg'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.7), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.7),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color.fromRGBO(69, 105, 109, 0.867),
              fontFamily: 'Cornerita', // Используем пользовательский шрифт
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeButton(String time) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFD8CCFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8CCFF).withOpacity(0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD8CCFF).withOpacity(0.7),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Center(
        child: Text(
          time, // Отображаем только время матча
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color.fromRGBO(69, 105, 109, 0.867),
            fontFamily: 'Cornerita', // Используем пользовательский шрифт
          ),
        ),
      ),
    );
  }

  Widget _buildIconOrImage(Color color, String imagePath) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.7), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.7),
            blurRadius: 10,
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
    final bool isFirstRobotDominant = widget.firstRobotPercentage > widget.secondRobotPercentage;

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
                color: const Color(0xFFCDFBE4).withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
        Align(
          alignment: isFirstRobotDominant ? Alignment.centerLeft : Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: isFirstRobotDominant
                ? widget.firstRobotPercentage / 100
                : widget.secondRobotPercentage / 100,
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
          '${isFirstRobotDominant ? widget.firstRobotPercentage.toStringAsFixed(0) : widget.secondRobotPercentage.toStringAsFixed(0)}%',
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