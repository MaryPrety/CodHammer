import 'pages/authorize_page.dart';
import 'pages/bet_page.dart';
import 'pages/calendar_page.dart';
import 'pages/profile_page.dart';
import 'pages/quiz_page.dart';
import 'pages/register_page.dart';
import 'pages/shop_page.dart';
import 'pages/story_page.dart';
import 'pages/menu_page.dart';
import 'pages/cart_page.dart';
import 'services/api_service.dart';
import 'providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cod_hammer/widgets/app_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Проверяем не только наличие токена, но и его валидность на сервере
    final isValid = await ApiService.validateToken();
    if (mounted) {
      setState(() {
        _isAuthenticated = isValid;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, _) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
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
            locale: languageProvider.locale,
            home: _isAuthenticated 
                ? MainNavigation(
                    onLogout: () async {
                      setState(() => _isAuthenticated = false);
                      if (mounted && _navigatorKey.currentState != null) {
                        _navigatorKey.currentState!.pushReplacementNamed('/auth');
                      }
                    },
                  ) 
                : AuthorizePage(
                    onLoginSuccess: () {
                      setState(() => _isAuthenticated = true);
                      if (mounted && _navigatorKey.currentState != null) {
                        _navigatorKey.currentState!.pushReplacementNamed('/main');
                      }
                    },
                  ),
            routes: {
              '/main': (context) => _isAuthenticated 
                  ? MainNavigation(
                      onLogout: () async {
                        setState(() => _isAuthenticated = false);
                        if (mounted && _navigatorKey.currentState != null) {
                          _navigatorKey.currentState!.pushReplacementNamed('/auth');
                        }
                      },
                    ) 
                  : AuthorizePage(
                    onLoginSuccess: () {
                      setState(() => _isAuthenticated = true);
                      if (mounted && _navigatorKey.currentState != null) {
                        _navigatorKey.currentState!.pushReplacementNamed('/main');
                      }
                    },
                  ),
              '/auth': (context) => AuthorizePage(
                    onLoginSuccess: () {
                      setState(() => _isAuthenticated = true);
                      if (mounted && _navigatorKey.currentState != null) {
                        _navigatorKey.currentState!.pushReplacementNamed('/main');
                      }
                    },
                  ),
              '/register': (context) => const RegisterPage(),
            },
            onGenerateRoute: (settings) {
              if (!_isAuthenticated && settings.name != '/auth' && settings.name != '/register') {
                return MaterialPageRoute(
                  builder: (context) => AuthorizePage(
                    onLoginSuccess: () {
                      setState(() => _isAuthenticated = true);
                      if (mounted && _navigatorKey.currentState != null) {
                        _navigatorKey.currentState!.pushReplacementNamed('/main');
                      }
                    },
                  ),
                );
              }
              return null;
            },
          );
        },
      ),
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
  final int _gemCount = 0;
  late PageController _pageController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _shopPageKey = GlobalKey();

  late final List<Widget> _pages = [
    const CalendarPage(),
    const QuizPage(),
    const BetPage(),
    ShopPage(key: _shopPageKey), // Магазин добавлен в основную панель (Шипунов Д.А., 26.01.2026)
    const ProfilePage(),
  ];
  
  // Индекс для страницы меню (будет использоваться как индекс 5)
  static const int menuPageIndex = 5;

  @override
  void initState() {
    super.initState();
    // Инициализируем PageController с учетом того, что меню - последняя страница
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: CustomAppBar(
        title: 'CodHammer',
        isProfilePage: _currentIndex == 3,
        points: _currentIndex == 3 ? _gemCount : null,
        onTitleTap: null, // Убираем переход на магазин при клике на заголовок
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBody() {
    // Основные страницы с возможностью свайпа на меню
    // Меню всегда доступно как последняя страница в PageView
    // Индексы: 0-Календарь, 1-Опросы, 2-Ставки, 3-Магазин, 4-Профиль, 5-Меню (Шипунов Д.А., 26.01.2026)
    return PageView(
      controller: _pageController,
      onPageChanged: (index) {
        if (index == _pages.length) {
          // Если свайпнули на меню (последняя страница)
          setState(() {
            _currentIndex = menuPageIndex;
          });
        } else {
          // Переход между основными страницами
          setState(() {
            _currentIndex = index;
          });
        }
      },
      children: [
        ..._pages,
        // Добавляем меню как последнюю страницу для свайпа
        MenuPage(
          onLogout: widget.onLogout,
          onNavigateToPage: _handleMenuNavigation,
        ),
      ],
    );
  }

  void _handleMenuNavigation(int pageType) {
    // pageType: 0 - Магазин, 1 - История, 2 - Календарь, 3 - Опросы, 4 - Ставки, 5 - Профиль, 6 - Корзина
    // Индексы в основном PageView: 0-Календарь, 1-Опросы, 2-Ставки, 3-Магазин, 4-Профиль
    if (pageType == 1) {
      // История покупок - показываем как отдельную страницу поверх меню (Шипунов Д.А., 26.01.2026)
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const StoryPage(orderHistory: []),
        ),
      );
      return;
    }
    
    if (pageType == 6) {
      // Корзина - показываем как отдельную страницу поверх меню
      // Получаем список товаров из ShopPage через статический метод
      final products = ShopPage.getProductsFromState(_shopPageKey);
      final shopPageState = _shopPageKey.currentState;
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CartPage(
            products: products ?? [],
            onCartUpdated: () {
              // Обновляем состояние ShopPage если оно доступно
              if (shopPageState != null) {
                shopPageState.setState(() {});
              }
            },
          ),
        ),
      );
      return;
    }
    
    int targetIndex;
    if (pageType == 0) {
      // Магазин - индекс 3 (Шипунов Д.А., 26.01.2026)
      targetIndex = 3;
    } else {
      // Переход на основные страницы
      // 2->0 (Календарь), 3->1 (Опросы), 4->2 (Ставки), 5->4 (Профиль)
      targetIndex = pageType - 2;
    }
    
    setState(() {
      _currentIndex = targetIndex;
    });
    // Используем Future.microtask для анимации после обновления состояния
    Future.microtask(() {
      if (mounted && _pageController.hasClients) {
        _pageController.animateToPage(
          targetIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }


  Widget _buildBottomNavBar() {
    // Если мы на странице меню, не показываем навигацию
    if (_currentIndex == menuPageIndex) {
      return const SizedBox.shrink();
    }
    // Показываем основную навигацию
    // Индексы: 0-Календарь, 1-Опросы, 2-Ставки, 3-Магазин, 4-Профиль (Шипунов Д.А., 26.01.2026)
    return Container(
      height: 60,
      color: const Color(0xFFFAEFD9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavIcon(0, 'calendar'),
          _buildNavIcon(1, 'quiz'),
          _buildNavIcon(2, 'bet'),
          _buildNavIcon(3, 'bag'), // Магазин (Шипунов Д.А., 26.01.2026)
          _buildNavIcon(4, 'person'), // Профиль (индекс изменился с 3 на 4) (Шипунов Д.А., 26.01.2026)
          _buildMenuIcon(),
        ],
      ),
    );
  }

  Widget _buildMenuIcon() {
    final isActive = _currentIndex == menuPageIndex;
    return IconButton(
      onPressed: () {
        // Переход на меню
        setState(() {
          _currentIndex = menuPageIndex;
        });
        // Переключаемся на страницу меню в PageView
        _pageController.animateToPage(
          _pages.length, // Индекс меню (последняя страница)
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      icon: Icon(
        Icons.menu,
        color: isActive ? const Color(0xFF062B42) : const Color(0xFF456978),
        size: 30,
      ),
    );
  }

  Widget _buildNavIcon(int index, String iconName) {
    final isActive = _currentIndex == index;
    final activeIcon = 'assets/Active_$iconName.png';
    final inactiveIcon = 'assets/$iconName.png';

    return IconButton(
      onPressed: () {
        setState(() {
          _currentIndex = index;
        });
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      icon: Image.asset(
        isActive ? activeIcon : inactiveIcon,
        width: 30,
        height: 30,
      ),
    );
  }

  // Метод удален - больше не используется, так как магазин теперь в основной панели
  // @deprecated
  // ignore: unused_element
  Future<bool> _showExitShopConfirmation_DEPRECATED(BuildContext context, {int? targetIndex}) async {
    // Проверяем, нужно ли показывать диалог
    final prefs = await SharedPreferences.getInstance();
    final skipConfirmation = prefs.getBool('skip_shop_exit_confirmation') ?? false;
    
    if (skipConfirmation) {
      // Если пользователь выбрал не показывать диалог, сразу переходим
      if (targetIndex != null) {
        if (targetIndex == menuPageIndex) {
          // Переход на меню
          setState(() {
            _currentIndex = menuPageIndex;
          });
          if (_pageController.hasClients) {
            _pageController.jumpToPage(_pages.length);
          }
        } else if (targetIndex == 4) {
          // Переход на профиль (индекс 4)
          _navigateToProfile();
        } else {
          // Переход на другие страницы
          setState(() {
            _currentIndex = targetIndex;
          });
          if (_pageController.hasClients) {
            _pageController.jumpToPage(targetIndex);
          }
        }
      } else {
        _navigateToProfile();
      }
      return true;
    }

    // Показываем диалог подтверждения
    bool dontShowAgain = false;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF062B42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Text(
                'Подтверждение',
                style: TextStyle(
                  color: Color(0xFFCDFBE4),
                  fontFamily: 'Cornerita',
                  fontSize: 20,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Вы хотите покинуть данную страницу?',
                    style: TextStyle(
                      color: Color(0xFFCDFBE4),
                      fontFamily: 'Cornerita',
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Checkbox(
                        value: dontShowAgain,
                        onChanged: (bool? value) {
                          setDialogState(() {
                            dontShowAgain = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFFB19CD9),
                        checkColor: Colors.white,
                      ),
                      const Expanded(
                        child: Text(
                          'Больше не показывать',
                          style: TextStyle(
                            color: Color(0xFFCDFBE4),
                            fontFamily: 'Cornerita',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop({'confirmed': false, 'dontShowAgain': false});
                  },
                  child: const Text(
                    'Нет',
                    style: TextStyle(
                      color: Color(0xFFB19CD9),
                      fontFamily: 'Cornerita',
                      fontSize: 16,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop({'confirmed': true, 'dontShowAgain': dontShowAgain});
                  },
                  child: const Text(
                    'Да',
                    style: TextStyle(
                      color: Color(0xFFCDFBE4),
                      fontFamily: 'Cornerita',
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && result['confirmed'] == true) {
      // Если пользователь выбрал "Да"
      if (result['dontShowAgain'] == true) {
        // Сохраняем настройку
        await prefs.setBool('skip_shop_exit_confirmation', true);
      }
      // Переходим на целевую страницу
      if (targetIndex != null) {
        if (targetIndex == menuPageIndex) {
          // Переход на меню
          // Устанавливаем флаг для предотвращения обработки промежуточных индексов
          // Сначала устанавливаем состояние
          setState(() {
            _currentIndex = menuPageIndex;
          });
          // Используем WidgetsBinding для гарантированного выполнения после обновления состояния
          // И используем несколько кадров для гарантии правильного перехода
          WidgetsBinding.instance.addPostFrameCallback((_) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _pageController.hasClients) {
                // Проверяем текущую страницу перед переходом
                final currentPage = _pageController.page?.round();
                if (currentPage != _pages.length) {
                  // Используем jumpToPage для немедленного перехода без анимации
                  _pageController.jumpToPage(_pages.length);
                }
              }
            });
          });
        } else if (targetIndex == 4) {
          // Переход на профиль (индекс 4)
          _navigateToProfile();
        } else {
          // Переход на другие страницы
          setState(() {
            _currentIndex = targetIndex;
          });
          if (_pageController.hasClients) {
            _pageController.jumpToPage(targetIndex);
          }
        }
      } else {
        _navigateToProfile();
      }
      return true;
    }
    return false;
  }

  void _navigateToProfile() {
    setState(() {
      _currentIndex = 4; // Профиль теперь на индексе 4
    });
    _pageController.animateToPage(
      4,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
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
