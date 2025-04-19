import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import 'dart:ui';

class InfoText extends StatefulWidget {
  final String fontFamily;
  final String englishFontFamily;

  const InfoText({
    super.key,
    required this.fontFamily,
    required this.englishFontFamily,
  });

  @override
  _InfoTextState createState() => _InfoTextState();
}

class _InfoTextState extends State<InfoText> {
  bool _isTranslated = false;
  String? _translatedText;

  final String _russianText =
      'Вы можете изучить календарь событий и найти интересные хакатоны, геймджемы и научные конференции.';

  @override
  void initState() {
    super.initState();
    _translateRussianText();
  }

  Future<void> _translateRussianText() async {
    final translator = GoogleTranslator();
    final translation = await translator.translate(_russianText, from: 'ru', to: 'en');
    _translatedText = translation.text;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: Future.value(null),
      builder: (context, snapshot) {
        if (_translatedText == null && snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (_translatedText == null && snapshot.hasError) {
          return Text(
            'Ошибка перевода',
            style: const TextStyle(color: Colors.red),
          );
        } else {
          return GestureDetector(
            onTap: () {
              setState(() {
                _isTranslated = !_isTranslated;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _isTranslated ? _translatedText! : _russianText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFFAEFD9),
                   fontSize: _isTranslated ? 14 : 16,
                  height: 1.5,
                  fontFamily: _isTranslated
                      ? widget.englishFontFamily
                      : widget.fontFamily,
                ),
              ),
            ),
          );
        }
      },
    );
  }
}