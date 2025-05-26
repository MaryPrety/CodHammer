import 'package:flutter/material.dart';
import 'package:translator/translator.dart';

class InfoText extends StatefulWidget {
  final bool isTranslated; 
  final String fontFamily;
  final String englishFontFamily;

  const InfoText({
    super.key,
    required this.isTranslated,
    required this.fontFamily,
    required this.englishFontFamily,
  });

  @override
  _InfoTextState createState() => _InfoTextState();
}

class _InfoTextState extends State<InfoText> {
  String? _translatedText;
  late Future<void> _translationFuture;

  final String _russianText = 'Вы можете изучить календарь событий...';

  @override
  void initState() {
    super.initState();
    _translationFuture = _translateRussianText();
  }

  Future<void> _translateRussianText() async {
    try {
      final translator = GoogleTranslator();
      final translation = await translator.translate(_russianText, to: 'en');
      if (mounted) {
        setState(() => _translatedText = translation.text);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _translatedText = 'Ошибка перевода');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _translationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            widget.isTranslated ? (_translatedText ?? '') : _russianText,
            style: TextStyle(
              color: const Color(0xFFFAEFD9),
              fontSize: widget.isTranslated ? 14 : 16,
              fontFamily: widget.isTranslated 
                  ? widget.englishFontFamily 
                  : widget.fontFamily,
            ),
          ),
        );
      },
    );
  }
}