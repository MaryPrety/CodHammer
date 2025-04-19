import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';

class SurveyResultsPage extends StatelessWidget {
  final List<int?> answers; // Receive answers from DetailedQuestionPage

  const SurveyResultsPage({super.key, required this.answers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF062B42),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            _buildText('Результаты опроса', 40),
            const SizedBox(height: 30),
            Text(
              'Спасибо за участие! Вот статистика ответов:',
              style: TextStyle(
                fontFamily: 'Cornerita',
                color: Colors.white70,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: const [
                    Question1Result(),
                    SizedBox(height: 30),
                    Question2Result(),
                    SizedBox(height: 30),
                    Question3Result(),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            _buildFinishButton(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildText(String text, double fontSize) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Cornerita',
        color: Color.fromRGBO(205, 251, 228, 1),
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFinishButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          Navigator.popUntil(context, (route) => route.isFirst); // Return to the main page
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color.fromRGBO(205, 251, 228, 1),
          foregroundColor: const Color(0xFF062B42),
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        ),
        child: Text(
          'Завершить',
          style: TextStyle(
            fontFamily: 'Cornerita',
            color: Color(0xFF0A3B5C),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class Question1Result extends StatelessWidget {
  const Question1Result({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, double> dataMap = {
      "Да, мне нравится наблюдать": 60,
      "Да, я участвую": 15,
      "Нет, мне не интересно": 20,
      "Нейтрально": 5,
    };

    return _buildQuestionResult(
      context,
      '1. Ваш интерес к технологическим мероприятиям:',
      dataMap,
    );
  }
}

class Question2Result extends StatelessWidget {
  const Question2Result({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, double> dataMap = {
      "Эксклюзивный гаджет": 60,
      "Подарочная карта": 25,
      "Впечатление или мероприятие": 15,
    };

    return _buildQuestionResult(
      context,
      '2. Предпочтения в вознаграждениях:',
      dataMap,
    );
  }
}

class Question3Result extends StatelessWidget {
  const Question3Result({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, double> dataMap = {
      "Боевой робот": 45,
      "Футболка или толстовка": 15,
      "Интерактивный набор": 40,
    };

    return _buildQuestionResult(
      context,
      '3. Выбор сувенира участника:',
      dataMap,
    );
  }
}

Widget _buildQuestionResult(BuildContext context, String question, Map<String, double> dataMap) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        question,
        style: TextStyle(
          fontFamily: 'Cornerita',
          color: Colors.white70,
          fontSize: 20,
        ),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: dataMap.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.hexagon, color: Color.fromRGBO(205, 251, 228, 1), size: 12),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.key} - ${entry.value.toInt()}%',
                        style: TextStyle(
                          fontFamily: 'Cornerita',
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(
            width: 150,
            height: 150,
            child: PieChart(
              dataMap: dataMap,
              animationDuration: const Duration(milliseconds: 800),
              chartRadius: 60,
              colorList: const [
                Color.fromRGBO(205, 251, 228, 1),
                Color(0xFFFAEFD9),
                Colors.white70,
                Color(0xFFB19CD9),
              ],
              initialAngleInDegree: 0,
              chartType: ChartType.disc,
              legendOptions: const LegendOptions(showLegends: false),
              chartValuesOptions: const ChartValuesOptions(showChartValues: false),
            ),
          ),
        ],
      ),
    ],
  );
}