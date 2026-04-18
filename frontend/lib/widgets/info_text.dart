import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import '../providers/language_provider.dart';
import 'package:provider/provider.dart';

class InfoText extends StatefulWidget {
  const InfoText({super.key});

  @override
  State<InfoText> createState() => _InfoTextState();
}

class _InfoTextState extends State<InfoText> {
  final String _russianText = 'Вы можете изучить календарь событий...';

  Future<String> _translateRussianText() async {
    try {
      final translator = GoogleTranslator();
      final translation = await translator.translate(_russianText, to: 'en');
      return translation.text;
    } catch (e) {
      return 'Translation error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final isEnglish = languageProvider.isEnglish;
        return FutureBuilder<String>(
          key: ValueKey(isEnglish), // Пересоздаем FutureBuilder при изменении языка
          future: _translateRussianText(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final translatedText = snapshot.data ?? '';
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                isEnglish ? translatedText : _russianText,
                style: TextStyle(
                  color: const Color(0xFFFAEFD9),
                  fontSize: isEnglish ? 14 : 16,
                  fontFamily: isEnglish ? 'Tomorrow' : 'Cornerita',
                ),
              ),
            );
          },
        );
      },
    );
  }
}