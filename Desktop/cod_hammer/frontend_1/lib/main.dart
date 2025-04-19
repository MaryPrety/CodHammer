// main.dart
import 'pages/authorize_page.dart';
import 'pages/bet_page.dart';
import 'pages/calendar_page.dart';
import 'pages/profile_page.dart';
import 'pages/quiz_page.dart';
import 'pages/register_page.dart';
import 'pages/shop_page.dart'; // Импортируем новую страницу
import 'pages/story_page.dart'; // Импортируем страницу истории покупок
import 'services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cod_hammer/widgets/app_bar.dart';

void main() async {
  setUrlStrategy(PathUrlStrategy());
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU', null);

  final token = await ApiService.getToken();

  runApp(MyApp(
    initialRoute: token != null ? '/main' : '/auth',
  ));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CodHammer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Tomorrow',
      ),
      initialRoute: initialRoute,
      routes: {
        '/auth': (context) => const AuthorizePage(),
        '/register': (context) => const RegisterPage(),
        '/main': (context) => const MainNavigation(),
      },
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
  int _shopIndex = 0; // Индекс для навигации внутри магазина
  int _gemCount = 6500;

  final List<Widget> _pages = [
    const CalendarPage(),
    const QuizPage(),
    const BetPage(),
    const ProfilePage(),
  ];

  final List<Widget> _shopPages = [
    const ShopPage(),
    const StoryPage(orderHistory: [],), // Страница истории покупок
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'CodHammer',
        isProfilePage: _currentIndex == 3,
        gemCount: _currentIndex == 3 ? _gemCount : null,
        onTitleTap: () {
          // Переход на страницу магазина при нажатии на заголовок
          setState(() {
            _currentIndex = 4; // Индекс страницы магазина
            _shopIndex = 0; // Сброс индекса внутри магазина
          });
        },
      ),
      body: _currentIndex == 4 ? _shopPages[_shopIndex] : _pages[_currentIndex],
      bottomNavigationBar: _currentIndex == 4 ? _buildShopNavBar() : _buildSmartNavBar(),
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

  Widget _buildShopNavBar() {
    return Container(
      height: 60,
      color: const Color(0xFFFAEFD9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavIcon(0, 'bag'), // Иконка сумки для магазина
          _buildNavIcon(1, 'story'), // Иконка истории для истории покупок
          _buildNavIcon(3, 'person'), // Переход на профиль и основное меню
        ],
      ),
    );
  }

  Widget _buildNavIcon(int index, String iconName) {
    final isActive = _currentIndex == 4 ? _shopIndex == index : _currentIndex == index;
    final activeIcon = 'assets/Active_$iconName.png';
    final inactiveIcon = 'assets/$iconName.png';

    return IconButton(
      onPressed: () {
        setState(() {
          if (_currentIndex == 4) {
            if (index == 3) {
              _currentIndex = index; // Возврат к основному меню
            } else {
              _shopIndex = index;
            }
          } else {
            _currentIndex = index;
            if (index == 4) {
              _shopIndex = 0; // Сброс индекса внутри магазина
            }
          }
        });
      },
      icon: Image.asset(
        isActive ? activeIcon : inactiveIcon,
        width: 30,
        height: 30,
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      double millions = count / 1000000;
      return '${millions.toStringAsFixed(millions.truncateToDouble() == millions ? 0 : 1)}m';
    } else if (count >= 1000) {
      double thousands = count / 1000;
      return '${thousands.toStringAsFixed(thousands.truncateToDouble() == thousands ? 0 : 1)}k';
    } else {
      return count.toString();
    }
  }
}