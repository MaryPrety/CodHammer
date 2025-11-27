import 'pages/authorize_page.dart';
import 'pages/bet_page.dart';
import 'pages/calendar_page.dart';
import 'pages/profile_page.dart';
import 'pages/quiz_page.dart';
import 'pages/register_page.dart';
import 'pages/shop_page.dart';
import 'pages/story_page.dart';
import 'services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cod_hammer/widgets/app_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU', null);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final token = await ApiService.getToken();
    setState(() {
      _isAuthenticated = token != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CodHammer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Tomorrow',
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ru', 'RU'),
      routes: {
        '/main': (context) => _isAuthenticated 
            ? MainNavigation(
                onLogout: () => setState(() => _isAuthenticated = false),
              ) 
            : AuthorizePage(
              onLoginSuccess: () => setState(() => _isAuthenticated = true),
            ),
        '/auth': (context) => const AuthorizePage(),
        '/register': (context) => const RegisterPage(),
      },
      onGenerateRoute: (settings) {
        if (!_isAuthenticated && settings.name != '/auth') {
          return MaterialPageRoute(
            builder: (context) => const AuthorizePage(),
          );
        }
        return null;
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  final VoidCallback onLogout;

  const MainNavigation({super.key, required this.onLogout});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  int _shopIndex = 0;
  final int _gemCount = 0;

  final List<Widget> _pages = [
    const CalendarPage(),
    const QuizPage(),
    const BetPage(),
    const ProfilePage(),
  ];

  final List<Widget> _shopPages = [
    const ShopPage(),
    const StoryPage(orderHistory: []),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'CodHammer',
        isProfilePage: _currentIndex == 3,
        points: _currentIndex == 3 ? _gemCount : null,
        onTitleTap: () {
          setState(() {
            _currentIndex = 4;
            _shopIndex = 0;
          });
        },
      ),
      body: _currentIndex == 4 ? _shopPages[_shopIndex] : _pages[_currentIndex],
      bottomNavigationBar:
          _currentIndex == 4 ? _buildShopNavBar() : _buildSmartNavBar(),
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
          _buildNavIcon(4, 'exit'),
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
          _buildNavIcon(0, 'bag'),
          _buildNavIcon(1, 'story'),
          _buildNavIcon(3, 'person'),
        ],
      ),
    );
  }

  Widget _buildNavIcon(int index, String iconName) {
    final isActive = 
        _currentIndex == 4 ? _shopIndex == index : _currentIndex == index;
    final activeIcon = 'assets/Active_$iconName.png';
    final inactiveIcon = 'assets/$iconName.png';

    return IconButton(
      onPressed: () {
        if (index == 4) { // Кнопка выхода
          ApiService.logout().then((_) => widget.onLogout());
        } else {
          setState(() {
            if (_currentIndex == 4) {
              if (index == 3) {
                _currentIndex = index;
              } else {
                _shopIndex = index;
              }
            } else {
              _currentIndex = index;
            }
          });
        }
      },
      icon: Image.asset(
        isActive ? activeIcon : inactiveIcon,
        width: 30,
        height: 30,
      ),
    );
  }

  // ignore: unused_element
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
