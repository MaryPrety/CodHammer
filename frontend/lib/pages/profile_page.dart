import 'package:cod_hammer/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String errorMessage = '';

  final Map<String, double> stats = {
    "Polls": 60,
    "Hackathons": 90,
    "Attendance": 70,
    "Conferences": 40,
    "Bet on sports": 50,
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final data = await ApiService.getCurrentUser();
      setState(() {
        userData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Ошибка загрузки данных: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Подтверждение выхода'),
          content: const Text('Вы уверены, что хотите выйти из профиля?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Отмена'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Выйти', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await ApiService.logout();
                Navigator.of(context).pop(); 
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Вы успешно вышли из профиля')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF062B42),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF062B42),
        body: Center(
          child: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF062B42),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildUserInfo(),
            const SizedBox(height: 20),
            _buildRadarChart(),
            const SizedBox(height: 20),
            _buildBarChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 30,
          backgroundImage: AssetImage('assets/avatar.png'),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userData?['username'] ?? 'Неизвестный пользователь',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
              ),
              Text(
                'Роль: ${userData?['role'] ?? 'student'}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: () => _showLogoutDialog(context),
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoText('Возраст: ${userData?['age'] ?? 'не указан'}'),
        _InfoText('Email: ${userData?['email'] ?? 'не указан'}'),
        _InfoText('Телефон: ${userData?['phone'] ?? 'не указан'}'),
        _InfoText('Дата регистрации: ${_formatDate(userData?['created_at'])}'),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'неизвестно';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}.${date.month}.${date.year}';
    } catch (e) {
      return 'неизвестно';
    }
  }


  Widget _buildRadarChart() {
    return SizedBox(
      height: 300,
      child: RadarChart(
        RadarChartData(
          radarTouchData: RadarTouchData(enabled: false),
          titlePositionPercentageOffset: 0.2,
          radarShape: RadarShape.polygon,
          tickCount: 5,
          tickBorderData: const BorderSide(color: Colors.white24),
          radarBorderData: const BorderSide(color: Colors.white),
          radarBackgroundColor: Colors.transparent,
          dataSets: [
            RadarDataSet(
              dataEntries: stats.values.map((e) => RadarEntry(value: e)).toList(),
              fillColor: Colors.blue.withOpacity(0.3),
              borderColor: Colors.blue,
              borderWidth: 2,
            ),
          ],
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBar(stats['Attendance'] ?? 0, const Color(0xFFB0F1FF)),
            const SizedBox(width: 10),
            _buildBar(stats['Hackathons'] ?? 0, const Color(0xFF90EE90)),
            const SizedBox(width: 10),
            _buildBar(stats['Polls'] ?? 0, const Color(0xFFB19CD9)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text("Attendance", style: TextStyle(color: Colors.white, fontSize: 14)),
            SizedBox(width: 30),
            Text("Hackathons", style: TextStyle(color: Colors.white, fontSize: 14)),
            SizedBox(width: 30),
            Text("Polls", style: TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildBar(double value, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: 20,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            Container(
              width: 20,
              height: 100 * (value / 100),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoText extends StatelessWidget {
  final String text;
  const _InfoText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Roboto'),
      ),
    );
  }
}