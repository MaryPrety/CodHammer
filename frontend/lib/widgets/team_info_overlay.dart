import 'package:flutter/material.dart';

class TeamInfoOverlay extends StatefulWidget {
  final String teamName;
  final List<String> teamMembers;
  final String robotName;
  final String robotDetails;
  final String imageUrl;
  final Color teamColor; // Цвет фона для команды

  const TeamInfoOverlay({
    Key? key,
    required this.teamName,
    required this.teamMembers,
    required this.robotName,
    required this.robotDetails,
    required this.imageUrl,
    required this.teamColor, required String fontFamily,
  }) : super(key: key);

  @override
  _TeamInfoOverlayState createState() => _TeamInfoOverlayState();
}

class _TeamInfoOverlayState extends State<TeamInfoOverlay> {
  bool _isRussian = true; // Состояние для переключения языка

  // Метод для перевода текста на английский
  String _translateToEnglish(String russianText) {
    final translations = {
      'WEBER LABS': 'WEBER LABS',
      'Auxilium AI': 'Auxilium AI',
      'Robot - Kolobah': 'Robot - Kolobah',
      'Robot - A.L.F.A': 'Robot - A.L.F.A',
      'Vertical spinner construction\nweight of the robot 110(kg)\nSpeed 26 km/h\nDimensions 630*740*330':
          'Vertical spinner construction\nweight of the robot 110(kg)\nSpeed 26 km/h\nDimensions 630*740*330',
      'Vertical spinner construction\nweight of the robot 160(kg)\nSpeed 25 km/h\nDimensions 1200*1200*340':
          'Vertical spinner construction\nweight of the robot 160(kg)\nSpeed 25 km/h\nDimensions 1200*1200*340',
    };
    return translations[russianText] ?? russianText; // Возвращаем перевод или исходный текст
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isRussian = !_isRussian; // Переключаем язык при нажатии
          });
        },
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.teamColor, // Используем переданный цвет команды
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  widget.imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isRussian ? widget.teamName : _translateToEnglish(widget.teamName),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF062B42),
                  fontFamily: 'Cornerita', // Используем пользовательский шрифт
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.teamMembers.join('\n'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF062B42),
                  fontFamily: 'Cornerita', // Используем пользовательский шрифт
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isRussian ? widget.robotName : _translateToEnglish(widget.robotName),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF062B42),
                  fontFamily: 'Cornerita', // Используем пользовательский шрифт
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _isRussian ? widget.robotDetails : _translateToEnglish(widget.robotDetails),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF062B42),
                  fontFamily: 'Cornerita', // Используем пользовательский шрифт
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Закрываем оверлей
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: const Color(0xFF456977),
                  backgroundColor: const Color(0xFFD8CCFF), // Цвет кнопки
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: Text(
                    _isRussian ? 'Закрыть' : 'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Cornerita', // Используем пользовательский шрифт
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}