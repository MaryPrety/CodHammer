import 'package:cod_hammer/pages/bet_page.dart';
import 'package:cod_hammer/pages/calendar_page.dart';
import 'package:cod_hammer/pages/profile_page.dart';
import 'package:cod_hammer/pages/quiz_page.dart';
import 'package:flutter/material.dart';


void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CodHammer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Tomorrow',
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const CalendarPage(), // Страница календаря
    const QuizPage(),     // Страница викторины
    const BetPage(),      // Страница ставок
    const ProfilePage(),  // Страница профиля
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CodHammer',
          style: TextStyle(
            fontFamily: 'StalinistOne',
            color: Color(0xFFCDFBE4),
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF062B42),
        elevation: 0,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: _buildSmartNavBar(),
    );
  }

  Widget _buildSmartNavBar() {
    return Container(
      height: 60,
      color: const Color(0xFFFAEFD9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavIcon(0, 'calendar'),
          _buildNavIcon(1, 'quiz'),
          _buildNavIcon(2, 'bet'),
          _buildNavIcon(3, 'person'),
        ],
      ),
    );
  }

  Widget _buildNavIcon(int index, String iconName) {
    final isActive = _currentIndex == index;
    final activeIcon = 'assets/Active_$iconName.png';
    final inactiveIcon = 'assets/$iconName.png';

    return IconButton(
      onPressed: () => setState(() => _currentIndex = index),
      icon: Image.asset(
        isActive ? activeIcon : inactiveIcon,
        width: 30,
        height: 30,
      ),
    );
  }
}