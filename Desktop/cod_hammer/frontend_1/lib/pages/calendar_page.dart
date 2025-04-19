import 'package:flutter/material.dart';
import '../widgets/info_text.dart';
import '../widgets/event_card.dart';
import '../widgets/calendar_widget.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Определяем шрифты для русского и английского текста
    const String russianFontFamily = 'Cornerita'; // Используем название семейства
    const String englishFontFamily = 'Tomorrow'; // Используем название семейства

    return Scaffold(
      backgroundColor: const Color(0xFF062B42),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  CalendarWidget(fontFamily: russianFontFamily),
                  const SizedBox(height: 20),
                  InfoText(
                    fontFamily: russianFontFamily,
                    englishFontFamily: englishFontFamily,
                  ),
                  const SizedBox(height: 20),
                  EventCard(
                    iconPath: 'assets/Quiz_.png',
                    text: "Не забудьте проголосовать в предстоящих опросах",
                    russianFontFamily: russianFontFamily,
                    englishFontFamily: englishFontFamily,
                  ),
                  const SizedBox(height: 10),
                  EventCard(
                    iconPath: 'assets/Bet_.png',
                    text: 'Скоро битва роботов, а значит и ставки',
                    russianFontFamily: russianFontFamily,
                    englishFontFamily: englishFontFamily,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}