import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final Map<String, double> stats = {
    "Polls": 60,
    "Hackathons": 90,
    "Attendance": 70,
    "Conferences": 40,
    "Bet on sports": 50,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF062B42),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
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

  Widget _buildHeader() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 30,
          backgroundImage: AssetImage('assets/avatar.png'),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Vasilchenko Maria Mikhailovna',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'university - MIREA',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _InfoText('Age: 21 years old'),
        _InfoText('Interest: robotics, IoT devices'),
        _InfoText('Ready to participate in hackathons'),
        _InfoText('Email: mari.vas.04@mail.ru'),
      ],
    );
  }

  /// **📌 Пентограммный график (RadarChart)**
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
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 12), // ✅ исправленный стиль текста
        // getTitle: (index, angle) => stats.keys.elementAt(index), // ✅ исправленный заголовок
      ),
    ),
  );
}


  /// **📌 Гистограмма (Bar Chart)**
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

  /// **📌 Виджет для одной полоски в бар-чарте**
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

/// **📌 Виджет для отображения информации**
class _InfoText extends StatelessWidget {
  final String text;
  const _InfoText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
    );
  }
}
