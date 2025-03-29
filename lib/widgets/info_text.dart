import 'package:flutter/material.dart';
import 'package:translator/translator.dart';

class InfoText extends StatefulWidget {
  const InfoText({Key? key}) : super(key: key);

  @override
  _InfoTextState createState() => _InfoTextState();
}

class _InfoTextState extends State<InfoText> {
  bool _isTranslated = false; // Флаг для переключения языка текста

  Future<String> translateText(String text) async {
    final translator = GoogleTranslator();
    // Перевод с русского на английский
    final translation = await translator.translate(text, from: 'ru', to: 'en');
    return translation.text;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: translateText(
        'Вы можете изучить календарь событий и найти интересные хакатоны, геймджемы и научные конференции.',
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text(
            'Ошибка: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          );
        } else if (snapshot.hasData) {
          final String translatedText = snapshot.data!;
          return GestureDetector(
            onTap: () {
              setState(() {
                _isTranslated = !_isTranslated;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _isTranslated ? translatedText : 'Вы можете изучить календарь событий и найти интересные хакатоны, геймджемы и научные конференции.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFFAEFD9),
                  fontSize: 14,
                  height: 1.5,
                  fontFamily: _isTranslated ? 'Tomorrow' : 'Cornerita-Regular',
                  fontWeight: FontWeight.bold, // Добавлено полужирное начертание
                ),
              ),
            ),
          );
        } else {
          return const Text('Данные недоступны');
        }
      },
    );
  }
}