import 'package:flutter/material.dart';
import 'package:translator/translator.dart';

class EventCard extends StatefulWidget {
  final String iconPath;
  final String text;

  const EventCard({
    super.key,
    required this.iconPath,
    required this.text,
  });

  @override
  _EventCardState createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
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
      future: translateText(widget.text),
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
            child: Row(
              children: [
                Image.asset(
                  widget.iconPath,
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isTranslated ? translatedText : widget.text,
                    style: TextStyle(
                      color: const Color(0xFFFAEFD9),
                      fontSize: 16,
                      fontFamily: _isTranslated ? 'Tomorrow' : 'Cornerita-Regular',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return const Text('Данные недоступны');
        }
      },
    );
  }
}