import 'package:cod_hammer/pages/edit_profile_page.dart';
import 'package:cod_hammer/pages/create_event_page.dart';
import 'package:cod_hammer/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:cod_hammer/widgets/user_info_card_widget.dart';
import 'package:cod_hammer/widgets/radar_chart_widget.dart';
import 'package:cod_hammer/widgets/weekly_activity_widget.dart';
import 'package:cod_hammer/widgets/avatar_widget.dart';
import 'package:cod_hammer/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _secondaryColor = Color.fromRGBO(205, 251, 228, 1);
  static const _tertiaryColor = Color(0xFFB19CD9);
  static const _glowColor = Color(0xFFFAEFD9);
  static const _backgroundColor = Color(0xFF062B42);
  static const _cardColor = Color(0xFF0A3B5C);
  static const _textColorSecondary = Colors.white70;
  static const String _avatarKey = 'profile_avatar_path';
  late Future<Map<String, dynamic>> _profileData;
  List<Map<String, dynamic>> _weeklyData = [];
  String? _avatarPath;
  String? _userRole;
  final Map<String, String> _dayTranslations = {
    "Monday": "Понедельник",
    "Tuesday": "Вторник",
    "Wednesday": "Среда",
    "Thursday": "Четверг",
    "Friday": "Пятница",
    "Saturday": "Суббота",
    "Sunday": "Воскресенье",
  };

  @override
  void initState() {
    super.initState();
    _profileData = _loadProfileData();
    _loadAvatarPath();
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

  Future<void> _loadAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(_avatarKey);
    if (mounted) {
      setState(() {
        _avatarPath = savedPath;
      });
    }
  }


   Future<Map<String, dynamic>> _loadProfileData() async {
     try {
       final response = await ApiService.getProfile();
       if (response['weekly_activity'] == null) {
      response['weekly_activity'] = [];
    }
    
    if (response['interests'] == null) {
      response['interests'] = [];
    }
    
    if (response['stats'] == null) {
      response['stats'] = {
        'polls': 0,
        'hackathons': 0,
        'attendance': 0,
        'conferences': 0,
        'bet': 0
      };
    }

    // Если данных нет, создаем массив с нулями для всех дней недели
    final weeklyActivity = response['weekly_activity'] as List?;
    if (weeklyActivity == null || weeklyActivity.isEmpty) {
      final daysOfWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
      response['weekly_activity'] = daysOfWeek.map((day) => {
        "day": day,
        "attendance": 0,
        "hackathons": 0,
        "polls": 0,
      }).toList();
    }

    _weeklyData = List<Map<String, dynamic>>.from(response['weekly_activity'] ?? []);
    return response;
    } catch (e) {
      debugPrint('Error loading profile: $e');
      throw Exception('Error loading profile: ${e.toString()}');
    }
  }

  List<Map<String, String>> _buildUserInfo(Map<String, dynamic> data, bool isEnglish) {
    return [
      {"label": "Age", "value": "${data['age'] ?? 'N/A'} ${isEnglish ? 'years' : 'лет'}"},
      {"label": "Interests", "value": (data['interests'] ?? []).join(', ')},
      {"label": "Status", "value": data['status'] ?? (isEnglish ? 'Unknown' : 'Неизвестно')},
      {"label": "Email", "value": data['email'] ?? 'N/A'},
    ];
  }

  Map<String, double> _buildStats(Map<String, dynamic> data) {
    // Безопасное преобразование значений в double
    double getDoubleValue(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed ?? 0.0;
      }
      return 0.0;
    }
    
    final stats = data['stats'] ?? {};
    return {
      "Polls": getDoubleValue(stats['polls']),
      "Hackathons": getDoubleValue(stats['hackathons']),
      "Attendance": getDoubleValue(stats['attendance']),
      "Conferences": getDoubleValue(stats['conferences']),
      "Bet on sports": getDoubleValue(stats['bet']),
    };
  }

  List<Map<String, String>> _translateUserInfo(List<Map<String, String>> info) {
    return info.map((item) {
      return {
        "label": _translateLabel(item["label"]!),
        "value": item["value"]!,
      };
    }).toList();
  }

  String _translateLabel(String label) {
    const translations = {
      "Age": "Возраст",
      "Interests": "Интересы",
      "Status": "Статус",
      "Email": "Электронная почта",
    };
    return translations[label] ?? label;
  }

  /// Имя в шапке: никнейм (name/username), иначе «Имя Фамилия», иначе заглушка.
  String _headerDisplayName(Map<String, dynamic> data, bool isEnglish) {
    String trimOrEmpty(dynamic v) => (v ?? '').toString().trim();

    final fromName = trimOrEmpty(data['name']);
    final fromUsername = trimOrEmpty(data['username']);
    final nick = fromName.isNotEmpty ? fromName : fromUsername;
    if (nick.isNotEmpty) return nick;

    final first = trimOrEmpty(data['first_name']);
    final last = trimOrEmpty(data['last_name']);
    final full = [first, last].where((s) => s.isNotEmpty).join(' ');
    if (full.isNotEmpty) return full;

    return isEnglish ? 'No name' : 'Без имени';
  }

  Widget _buildHeader(Map<String, dynamic> data, bool isEnglish) {
    return Row(
      children: [
        AvatarWidget(
          imageUrl: _avatarPath,
          width: 40,
          height: 40,
          glowColor: Color.fromARGB(239, 255, 255, 255),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _headerDisplayName(data, isEnglish),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                isEnglish ? 'Community Member' : 'Участник сообщества',
                style: TextStyle(
                  color: _glowColor.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        // Кнопка создания события (только для админов)
        if (_userRole == 'admin')
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: _glowColor),
            tooltip: isEnglish ? 'Create event' : 'Создать событие',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateEventPage(),
                ),
              );
            },
          ),
        // Кнопка переключения языка
        Consumer<LanguageProvider>(
          builder: (context, languageProvider, _) {
            return IconButton(
              icon: Icon(
                Icons.language,
                color: _glowColor,
              ),
              tooltip: isEnglish ? 'Переключить на русский' : 'Switch to English',
              onPressed: () {
                languageProvider.toggleLanguage();
              },
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.edit, color: _glowColor),
          tooltip: isEnglish ? 'Edit profile' : 'Редактировать профиль',
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProfilePage(
                  profileData: data,
                  onProfileUpdated: () {
                    setState(() {
                      _profileData = _loadProfileData();
                      _loadAvatarPath();
                    });
                  },
                ),
              ),
            );
            // Обновляем путь к аватару после возврата со страницы редактирования
            await _loadAvatarPath();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _profileData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoading();
            } else if (snapshot.hasError) {
              return _buildError(snapshot.error.toString());
            }
            return _buildProfileContent(snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(Map<String, dynamic> data) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final isEnglish = languageProvider.isEnglish;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(data, isEnglish),
              const SizedBox(height: 20),
              UserInfoCardWidget(
                userInfo: isEnglish 
                    ? _buildUserInfo(data, isEnglish)
                    : _translateUserInfo(_buildUserInfo(data, isEnglish)),
                textColorSecondary: _textColorSecondary,
                cardColor: _cardColor,
                isEnglish: isEnglish,
                points: data['points'] ?? 0,
                onInfoPressed: () => _showDetailsDialog(data, isEnglish),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Activity Statistics', isEnglish),
              RadarChartWidget(
                stats: _buildStats(data),
                glowColor: _glowColor,
                tertiaryColor: _tertiaryColor,
                cardColor: _cardColor,
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Weekly Activity', isEnglish),
              WeeklyActivityWidget(
                weeklyData: _weeklyData.map((data) {
                  // Безопасное преобразование значений в double
                  double getDoubleValue(dynamic value) {
                    if (value == null) return 0.0;
                    if (value is int) return value.toDouble();
                    if (value is double) return value;
                    return 0.0;
                  }
                  
                  final day = data["day"] ?? "";
                  return {
                    "day": isEnglish ? day : (_dayTranslations[day] ?? day),
                    "attendance": getDoubleValue(data["attendance"]),
                    "hackathons": getDoubleValue(data["hackathons"]),
                    "polls": getDoubleValue(data["polls"]),
                  };
                }).toList(),
                attendanceGradient: [
                  _glowColor.withOpacity(0.8),
                  _glowColor.withOpacity(0.3),
                ],
                hackathonsGradient: [
                  _secondaryColor.withOpacity(0.8),
                  _secondaryColor.withOpacity(0.3),
                ],
                pollsGradient: [
                  _tertiaryColor.withOpacity(0.8),
                  _tertiaryColor.withOpacity(0.3),
                ],
                cardColor: _cardColor,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDetailsDialog(Map<String, dynamic> data, bool isEnglish) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEnglish ? 'More Details' : 'Подробнее',
                        style: TextStyle(
                          color: _secondaryColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: _textColorSecondary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow(
                    isEnglish ? 'First Name' : 'Имя',
                    data['first_name'] ?? (isEnglish ? 'Not specified' : 'Не указано'),
                    isEnglish,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    isEnglish ? 'Last Name' : 'Фамилия',
                    data['last_name'] ?? (isEnglish ? 'Not specified' : 'Не указано'),
                    isEnglish,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    isEnglish ? 'Username' : 'Имя пользователя',
                    data['name'] ?? data['username'] ?? (isEnglish ? 'Not specified' : 'Не указано'),
                    isEnglish,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    isEnglish ? 'Phone' : 'Телефон',
                    data['phone'] ?? (isEnglish ? 'Not specified' : 'Не указано'),
                    isEnglish,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    isEnglish ? 'Study Group' : 'Учебная группа',
                    data['study_group'] ?? (isEnglish ? 'Not specified' : 'Не указано'),
                    isEnglish,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    isEnglish ? 'Enrollment Year' : 'Год поступления',
                    data['enrollment_year']?.toString() ?? (isEnglish ? 'Not specified' : 'Не указано'),
                    isEnglish,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    isEnglish ? 'Educational Institution' : 'Учебное заведение',
                    data['educational_institution'] ?? (isEnglish ? 'Not specified' : 'Не указано'),
                    isEnglish,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    isEnglish ? 'Educational Direction' : 'Учебное направление',
                    data['educational_direction'] ?? (isEnglish ? 'Not specified' : 'Не указано'),
                    isEnglish,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    isEnglish ? 'Course' : 'Курс',
                    data['course']?.toString() ?? (isEnglish ? 'Not specified' : 'Не указано'),
                    isEnglish,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    isEnglish ? 'Semester' : 'Семестр',
                    data['semester']?.toString() ?? (isEnglish ? 'Not specified' : 'Не указано'),
                    isEnglish,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    isEnglish ? 'Account Created' : 'Аккаунт создан',
                    data['created_at'] != null
                        ? _formatDate(data['created_at'], isEnglish)
                        : (isEnglish ? 'Not specified' : 'Не указано'),
                    isEnglish,
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _secondaryColor,
                        foregroundColor: _backgroundColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isEnglish ? 'Close' : 'Закрыть',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, bool isEnglish) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _glowColor.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: _secondaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic dateValue, bool isEnglish) {
    try {
      String dateStr = dateValue.toString();
      // Пытаемся распарсить дату в разных форматах
      DateTime? date;
      
      // Если это строка в формате ISO
      if (dateStr.contains('T') || dateStr.contains(' ')) {
        date = DateTime.tryParse(dateStr);
      }
      
      if (date == null) {
        return dateStr;
      }
      
      if (isEnglish) {
        return '${date.day}/${date.month}/${date.year}';
      } else {
        return '${date.day}.${date.month}.${date.year}';
      }
    } catch (e) {
      return dateValue.toString();
    }
  }

  Widget _buildLoading() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(_glowColor),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Ошибка загрузки данных',
            style: TextStyle(color: _glowColor, fontSize: 18),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _tertiaryColor),
            onPressed: () {
              setState(() {
                _profileData = _loadProfileData();
              });
            },
            child: Text('Повторить', style: TextStyle(color: _glowColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isEnglish) {
    return Text(
      isEnglish ? title : _getRussianTitle(title),
      style: TextStyle(
        color: _glowColor,
        fontSize: isEnglish ? 14 : 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  String _getRussianTitle(String englishTitle) {
    const titles = {
      'Activity Statistics': 'Статистика активности',
      'Weekly Activity': 'Еженедельная активность',
    };
    return titles[englishTitle] ?? englishTitle;
  }
}