import 'package:flutter/material.dart';
import 'package:cod_hammer/widgets/user_info_card_widget.dart';
import 'package:cod_hammer/widgets/radar_chart_widget.dart';
import 'package:cod_hammer/widgets/weekly_activity_widget.dart';
import 'package:cod_hammer/widgets/avatar_widget.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Цветовая палитра
  static const _secondaryColor = Color.fromRGBO(205, 251, 228, 1); // Light Green
  static const _tertiaryColor = Color(0xFFB19CD9); // Light Purple
  static const _glowColor = Color(0xFFFAEFD9); // Glow color
  static const _backgroundColor = Color(0xFF062B42); // Dark Background
  static const _cardColor = Color(0xFF0A3B5C);
  static const _textColorSecondary = Colors.white70;

  // Статус языка (русский/английский)
  bool _isEnglish = false;

  // Перевод данных пользователя
  final Map<String, double> _stats = {
    "Polls": 60,
    "Hackathons": 90,
    "Attendance": 70,
    "Conferences": 40,
    "Bet on sports": 50,
  };

  final List<Map<String, String>> _userInfo = [
    {"label": "Age", "value": "21 years old"},
    {"label": "Interests", "value": "robotics, IoT devices"},
    {"label": "Status", "value": "Ready to participate in hackathons"},
    {"label": "Email", "value": "mari.vas.04@mail.ru"},
  ];

  final List<Map<String, String>> _userInfoTranslations = [
    {"label": "Возраст", "value": "21 год"},
    {"label": "Интересы", "value": "робототехника, IoT устройства"},
    {"label": "Статус", "value": "Готова участвовать в хакатонах"},
    {"label": "Электронная почта", "value": "mari.vas.04@mail.ru"},
  ];

  // Градиенты для графиков
  final List<Color> _attendanceGradient = [
    _glowColor.withOpacity(0.8),
    _glowColor.withOpacity(0.3),
  ];

  final List<Color> _hackathonsGradient = [
    _secondaryColor.withOpacity(0.8),
    _secondaryColor.withOpacity(0.3),
  ];

  final List<Color> _pollsGradient = [
    _tertiaryColor.withOpacity(0.8),
    _tertiaryColor.withOpacity(0.3),
  ];

  // Данные для недельного графика
  final List<Map<String, dynamic>> _weeklyData = [
    {"day": "Mon", "attendance": 6, "hackathons": 0, "polls": 1},
    {"day": "Tue", "attendance": 8, "hackathons": 0, "polls": 0},
    {"day": "Wed", "attendance": 7, "hackathons": 3, "polls": 0},
    {"day": "Thu", "attendance": 8, "hackathons": 0, "polls": 2},
    {"day": "Fri", "attendance": 7.5, "hackathons": 0, "polls": 1},
    {"day": "Sat", "attendance": 0, "hackathons": 5, "polls": 0},
    {"day": "Sun", "attendance": 0, "hackathons": 0, "polls": 0},
  ];

  // Перевод дней недели
  final Map<String, String> _dayTranslations = {
    "Mon": "Пн",
    "Tue": "Вт",
    "Wed": "Ср",
    "Thu": "Чт",
    "Fri": "Пт",
    "Sat": "Сб",
    "Sun": "Вс",
  };

  // Функция для переключения языка
  void _toggleLanguage() {
    setState(() {
      _isEnglish = !_isEnglish;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              UserInfoCardWidget(
                userInfo: _isEnglish ? _userInfo : _userInfoTranslations,
                textColorSecondary: _textColorSecondary,
                cardColor: _cardColor,
                isEnglish: _isEnglish, // Передаем флаг языка
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _toggleLanguage,
                child: MultilingualText(
                  russian: 'Статистика активности',
                  english: 'Activity Statistics',
                  isEnglish: _isEnglish,
                  style: TextStyle(
                    color: _glowColor,
                    fontSize: _isEnglish ? 14 : 16,
                    
                  ),
                ),
              ),
              RadarChartWidget(
                stats: _stats,
                glowColor: _glowColor,
                tertiaryColor: _tertiaryColor,
                cardColor: _cardColor,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _toggleLanguage,
                child: MultilingualText(
                  russian: 'Еженедельная активность',
                  english: 'Weekly Activity',
                  isEnglish: _isEnglish,
                  style: TextStyle(
                    color: _glowColor,
                    fontSize: _isEnglish ? 14 : 16,
                   
                  ),
                ),
              ),
              WeeklyActivityWidget(
                weeklyData: _weeklyData.map((data) {
                  return {
                    "day": _isEnglish ? data["day"] : _dayTranslations[data["day"]],
                    "attendance": data["attendance"],
                    "hackathons": data["hackathons"],
                    "polls": data["polls"],
                  };
                }).toList(),
                attendanceGradient: _attendanceGradient,
                hackathonsGradient: _hackathonsGradient,
                pollsGradient: _pollsGradient,
                cardColor: _cardColor,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        AvatarWidget(
          imageUrl: 'assets/avatar_1.png',
          width: 60,
          height: 60,
          glowColor: _glowColor,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MultilingualText(
                russian: 'Васильченко Мария Михайловна',
                english: 'Vasilchenko Maria Mikhailovna',
                isEnglish: _isEnglish,
                style: TextStyle(
                  color: _glowColor,
                  fontSize: _isEnglish ? 14 : 18,
                  
                ),
              ),
              MultilingualText(
                russian: 'Университет - МИРЭА',
                english: 'University - MIREA',
                isEnglish: _isEnglish,
                style: TextStyle(
                  color: _glowColor.withOpacity(0.8),
                  fontSize: _isEnglish ? 12 : 14,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.logout, color: _glowColor),
          onPressed: () => _showLogoutDialog(context),
          tooltip: 'Logout',
        ),
      ],
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _cardColor,
          title: MultilingualText(
            russian: 'Подтверждение выхода',
            english: 'Logout Confirmation',
            isEnglish: _isEnglish,
            style: TextStyle(
              color: _glowColor,
              fontSize: _isEnglish ? 14 : 16,
             
            ),
          ),
          content: MultilingualText(
            russian: 'Вы уверены, что хотите выйти из профиля?',
            english: 'Are you sure you want to log out?',
            isEnglish: _isEnglish,
            style: TextStyle(
              color: _glowColor.withOpacity(0.8),
              fontSize: _isEnglish ? 12 : 14,
            ),
          ),
          actions: [
            TextButton(
              child: MultilingualText(
                russian: 'Отмена',
                english: 'Cancel',
                isEnglish: _isEnglish,
                style: TextStyle(
                  color: _glowColor.withOpacity(0.8),
                  fontSize: _isEnglish ? 12 : 14,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: MultilingualText(
                russian: 'Выйти',
                english: 'Logout',
                isEnglish: _isEnglish,
                style: TextStyle(
                  color: _tertiaryColor,
                  fontSize: _isEnglish ? 14 : 16,
                  
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: MultilingualText(
                      russian: 'Вы успешно вышли из профиля',
                      english: 'You have successfully logged out',
                      isEnglish: _isEnglish,
                      style: TextStyle(
                        color: _glowColor,
                        fontSize: _isEnglish ? 14 : 16,
                      ),
                    ),
                    backgroundColor: _tertiaryColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// Универсальный виджет для многоязычного текста
class MultilingualText extends StatelessWidget {
  final String russian;
  final String english;
  final bool isEnglish;
  final TextStyle? style;

  const MultilingualText({
    Key? key,
    required this.russian,
    required this.english,
    required this.isEnglish,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      isEnglish ? english : russian,
      style: style?.copyWith(
        fontFamily: isEnglish ? 'Tomorrow' : 'Cornerita',
        fontSize: isEnglish ? (style?.fontSize ?? 14) : (style?.fontSize ?? 16),
        fontWeight: style?.fontWeight,
      ),
    );
  }
}