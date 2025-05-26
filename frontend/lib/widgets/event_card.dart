// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:translator/translator.dart';

class EventCard extends StatefulWidget {
  final String iconPath;
  final String text;
  final String russianFontFamily;
  final String englishFontFamily;

  const EventCard({
    super.key,
    required this.iconPath,
    required this.text,
    required this.russianFontFamily,
    required this.englishFontFamily,
  });

  @override
  _EventCardState createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool _isTranslated = false;

  Future<String> translateText(String text) async {
    final translator = GoogleTranslator();
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
          return Padding(
            padding: const EdgeInsets.all(16.0), // Добавляем отступы по всем сторонам
            child: GestureDetector(
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
                        fontSize: _isTranslated ? 14 : 16, // Уменьшаем размер шрифта для английского текста
                        fontFamily: _isTranslated
                            ? widget.englishFontFamily
                            : widget.russianFontFamily,
                      ),
                    ),
                  ),
                ],
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
