import 'package:flutter/material.dart';
import '../widgets/info_text.dart';
import '../widgets/event_card.dart';
import '../widgets/calendar_widget.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({Key? key}) : super(key: key);

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
                  const CalendarWidget(),
                  const SizedBox(height: 20),
                  const InfoText(),
                  const SizedBox(height: 20),
                  EventCard(
                    iconPath: 'assets/Quiz_.png',
                    text: "Не забудьте проголосовать в предстоящих опросах",
                  ),
                  const SizedBox(height: 10),
                  EventCard(
                    iconPath: 'assets/Bet_.png',
                    text: 'Скоро битва роботов, а значит и ставки',
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