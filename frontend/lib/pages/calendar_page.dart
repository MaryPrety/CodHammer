import 'package:flutter/material.dart';
import '../widgets/info_text.dart';
import '../widgets/event_card.dart';
import '../widgets/calendar_widget.dart';
import '../services/api_service.dart';
import '../pages/create_event_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  String? _userRole;
  int _calendarKey = 0;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final role = await ApiService.getUserRole();
      if (mounted) {
        setState(() {
          _userRole = role;
        });
      }
    } catch (e) {
      // Игнорируем ошибку, роль останется null
    }
  }

  bool get _isAdmin => _userRole == 'admin';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF062B42),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateEventPage(),
                  ),
                );
                if (result == true && mounted) {
                  // Событие создано, обновляем календарь через пересоздание
                  setState(() {
                    _calendarKey++;
                  });
                }
              },
              backgroundColor: const Color(0xFFFAEFD9),
              child: const Icon(
                Icons.add,
                color: Color(0xFF062B42),
              ),
            )
          : null,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  CalendarWidget(key: ValueKey(_calendarKey)),
                  const SizedBox(height: 20),
                  const InfoText(),
                  const SizedBox(height: 20),
                  EventCard(
                    iconPath: 'assets/quiz_.png',
                    text: "Не забудьте проголосовать в предстоящих опросах",
                  ),
                  const SizedBox(height: 10),
                  EventCard(
                    iconPath: 'assets/bet_.png',
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