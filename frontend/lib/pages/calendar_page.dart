import 'package:flutter/material.dart';
import '../widgets/info_text.dart';
import '../widgets/event_card.dart';
import '../widgets/calendar_widget.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});
  
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  bool _isTranslated = false;
  final String russianFontFamily = 'Cornerita'; 
  final String englishFontFamily = 'Tomorrow';

  @override
  Widget build(BuildContext context) {
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
                    isTranslated: _isTranslated,
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