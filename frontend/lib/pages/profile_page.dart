import 'package:flutter/material.dart';
import 'package:cod_hammer/widgets/user_info_card_widget.dart';
import 'package:cod_hammer/widgets/radar_chart_widget.dart';
import 'package:cod_hammer/widgets/weekly_activity_widget.dart';
import 'package:cod_hammer/widgets/avatar_widget.dart';
import 'package:cod_hammer/services/api_service.dart';

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

  bool _isEnglish = false;
  late Future<Map<String, dynamic>> _profileData;
  List<Map<String, dynamic>> _weeklyData = [];
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
  }

  void _toggleLanguage() {
    setState(() {
      _isEnglish = !_isEnglish;
      _profileData = _loadProfileData();
    });
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

    _weeklyData = List<Map<String, dynamic>>.from(response['weekly_activity'] ?? []);
    return response;
    } catch (e) {
      debugPrint('Error loading profile: $e');
      throw Exception('Error loading profile: ${e.toString()}');
    }
  }

  List<Map<String, String>> _buildUserInfo(Map<String, dynamic> data) {
    return [
      {"label": "Age", "value": "${data['age'] ?? 'N/A'} years"},
      {"label": "Interests", "value": (data['interests'] ?? []).join(', ')},
      {"label": "Status", "value": data['status'] ?? 'Unknown'},
      {"label": "Email", "value": data['email'] ?? 'N/A'},
    ];
  }

  Map<String, double> _buildStats(Map<String, dynamic> data) {
    return {
      "Polls": data['stats']['polls'].toDouble() ?? 0.0,
      "Hackathons": data['stats']['hackathons'].toDouble() ?? 0.0,
      "Attendance": data['stats']['attendance'].toDouble() ?? 0.0,
      "Conferences": data['stats']['conferences'].toDouble() ?? 0.0,
      "Bet on sports": data['stats']['bet'].toDouble() ?? 0.0,
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

  Widget _buildHeader(Map<String, dynamic> data) {
    return Row(
      children: [
        AvatarWidget(imageUrl: data['avatar_url'], width: 40, height: 40, glowColor: Color.fromARGB(239, 255, 255, 255),),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['name'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _isEnglish ? 'Community Member' : 'Участник сообщества',
              style: TextStyle(
                color: _glowColor.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ],
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(data),
          const SizedBox(height: 20),
          UserInfoCardWidget(
            userInfo: _isEnglish 
                ? _buildUserInfo(data)
                : _translateUserInfo(_buildUserInfo(data)),
            textColorSecondary: _textColorSecondary,
            cardColor: _cardColor,
            isEnglish: _isEnglish,
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Activity Statistics'),
          RadarChartWidget(
            stats: _buildStats(data),
            glowColor: _glowColor,
            tertiaryColor: _tertiaryColor,
            cardColor: _cardColor,
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Weekly Activity'),
          WeeklyActivityWidget(
            weeklyData: _weeklyData.map((data) {
              return {
                "day": _isEnglish ? data["day"] : _dayTranslations[data["day"]],
                "attendance": data["attendance"],
                "hackathons": data["hackathons"],
                "polls": data["polls"],
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

  Widget _buildSectionTitle(String title) {
    return GestureDetector(
      onTap: _toggleLanguage,
      child: Text(
        _isEnglish ? title : _getRussianTitle(title),
        style: TextStyle(
          color: _glowColor,
          fontSize: _isEnglish ? 14 : 16,
          fontWeight: FontWeight.w500,
        ),
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