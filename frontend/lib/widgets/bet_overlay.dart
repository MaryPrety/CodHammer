import 'package:flutter/material.dart';

class BetOverlay extends StatefulWidget {
  final String teamName; // Название команды
  final double coefficient; // Коэффициент ставки
  final bool isFirstTeam; // true = первая команда (зеленый), false = вторая команда (желтый)

  const BetOverlay({
    Key? key,
    required this.teamName,
    required this.coefficient,
    required this.isFirstTeam, required String fontFamily,
  }) : super(key: key);

  @override
  _BetOverlayState createState() => _BetOverlayState();
}

class _BetOverlayState extends State<BetOverlay> {
  final TextEditingController _betAmountController = TextEditingController();
  double _totalPotential = 0.0;
  bool _isRussian = true; // Состояние для переключения языка

  // Метод для расчета потенциального выигрыша
  void _calculateTotal() {
    final betAmount = double.tryParse(_betAmountController.text);
    if (betAmount != null && betAmount > 0) {
      setState(() {
        _totalPotential = betAmount * widget.coefficient;
      });
    } else {
      setState(() {
        _totalPotential = 0.0;
      });
    }
  }

  // Метод для получения цвета в зависимости от команды
  Color _getTeamColor() {
    return widget.isFirstTeam ? const Color(0xFFCDFBE4) : const Color(0xFFFAEFD9); // Зеленый для первой команды, желтый для второй
  }

  // Цвет текста
  static const Color _textColor = Color(0xFF456977);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _getTeamColor(), // Используем цвет команды для фона
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Название команды
            GestureDetector(
              onTap: () {
                setState(() {
                  _isRussian = !_isRussian; // Переключаем язык при нажатии
                });
              },
              child: Text(
                _isRussian ? widget.teamName : _translateToEnglish(widget.teamName), // Русский или английский текст
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _textColor,
                  fontFamily: 'Cornerita', // Используем пользовательский шрифт
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Поле ввода ставки
            TextField(
              controller: _betAmountController,
              keyboardType: TextInputType.number,
              onChanged: (_) => _calculateTotal(),
              decoration: InputDecoration(
                labelText: _isRussian ? 'Введите сумму ставки' : 'Enter bet amount',
                labelStyle: TextStyle(color: _textColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
              ),
              style: TextStyle(color: _textColor),
            ),
            const SizedBox(height: 20),

            // Потенциальный выигрыш
            Text(
              _isRussian
                  ? 'Потенциальный выигрыш: ${_totalPotential.toStringAsFixed(2)}'
                  : 'Potential Winnings: ${_totalPotential.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _textColor,
                fontFamily: 'Cornerita', // Используем пользовательский шрифт
              ),
            ),
            const SizedBox(height: 20),

            // Кнопка подтверждения ставки
            ElevatedButton(
              onPressed: () {
                if (_totalPotential > 0) {
                  Navigator.of(context).pop(); // Закрываем оверлей
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _isRussian ? 'Введите корректную сумму ставки' : 'Please enter a valid bet amount',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: const Color(0xFF456977),
                backgroundColor: const Color.fromRGBO(216, 204, 255, 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Text(
                  _isRussian ? 'Подтвердить ставку' : 'Confirm Bet',
                  style: TextStyle(fontSize: 16, color: _textColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Метод для перевода текста на английский
  String _translateToEnglish(String russianText) {
    final translations = {
      'Вебер Лабс': 'Вебер Лабс',
      'Auxilium AI': 'Auxilium AI',
    };
    return translations[russianText] ?? russianText; // Возвращаем перевод или исходный текст
  }

  @override
  void dispose() {
    _betAmountController.dispose();
    super.dispose();
  }
}