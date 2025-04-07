import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:pie_chart/pie_chart.dart';

class DetailedQuestionPage extends StatefulWidget {
  const DetailedQuestionPage({super.key});

  @override
  State<DetailedQuestionPage> createState() => _DetailedQuestionPageState();
}

class _DetailedQuestionPageState extends State<DetailedQuestionPage> {
  int _currentQuestionIndex = 0;
  List<int?> _answers = [null, null, null]; // Store selected answer index for each question
  bool _isRussian = true; // Language state - you might want to pass this from QuizPage

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Question 1 : Do you like the whole event of robot beating?',
      'options': [
        'Yes, I like to watch in action',
        'Yes, I\'m part of it',
        'No, I\'m not interested',
        'I am neutral',
      ],
    },
    {
      'question': 'Question 2 : If you could choose a gift card for betting points, which of these options would attract ?',
      'options': [
        'Exclusive gadget (such as smart watch)',
        'Gift card to your favorite store or online platform',
        'Experience or activity (such as concert tickets)',
      ],
    },
    {
      'question': 'Question 3 : If you were a participant in the robot battle, what souvenir would you choose?',
      'options': [
        'Combat robot with lighting and sound effects',
        'T-shirt or hoodie with unique design',
        'Interactive kit to build a mini robot',
      ],
    },
  ];

  String get currentFontFamily {
    return _isRussian ? 'Cornerita' : 'Tomorrow';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF062B42),
      appBar: AppBar(
        backgroundColor: const Color(0xFF062B42),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset('assets/Fight_robots.png', height: 120), // Question Image
            const SizedBox(height: 20),
            Text(
              _questions[_currentQuestionIndex]['question'],
              style: TextStyle(
                color: const Color(0xFFCDFBE4),
                fontSize: 20,
                fontFamily: currentFontFamily,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Column(
              children: (_questions[_currentQuestionIndex]['options'] as List<String>)
                  .asMap()
                  .entries
                  .map((entry) {
                int index = entry.key;
                String option = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _answers[_currentQuestionIndex] = index;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _answers[_currentQuestionIndex] == index
                          ? const Color(0xFFCDFBE4) // Highlight selected option
                          : const Color(0xFFE0F7FA).withOpacity(0.2),
                      foregroundColor: const Color(0xFFCDFBE4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${index + 1}  $option',
                        style: TextStyle(
                          fontFamily: currentFontFamily,
                          fontWeight: FontWeight.bold,
                          color: _answers[_currentQuestionIndex] == index ? const Color(0xFF062B42) : const Color(0xFFCDFBE4),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: _answers[_currentQuestionIndex] != null
                    ? () {
                        if (_currentQuestionIndex < _questions.length - 1) {
                          setState(() {
                            _currentQuestionIndex++;
                          });
                        } else {
                          // Show Results Page or Logic here
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SurveyResultsPage(answers: _answers), // Use SurveyResultsPage
                            ),
                          );
                        }
                      }
                    : null, // Disable button if no answer selected
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCDFBE4),
                  foregroundColor: const Color(0xFF062B42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text(
                  _currentQuestionIndex < _questions.length - 1 ? 'Continue' : 'Finish',
                  style: TextStyle(
                    fontFamily: currentFontFamily,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}


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
            Text(
              'Результаты опроса',
              style: TextStyle(
                fontFamily: 'Cornerita',
                color: const Color(0xFF90EE90),
                fontSize: 40,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Спасибо за участие! Вот статистика ответов:',
              style: TextStyle(
                fontFamily: 'Cornerita',
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Question1Result(), // No need to pass answers for now, using dummy data
                    const SizedBox(height: 30),
                    Question2Result(),
                    const SizedBox(height: 30),
                    Question3Result(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF90EE90),
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'Завершить',
                  style: TextStyle(
                    fontFamily: 'Cornerita',
                    color: const Color(0xFF0E1621),
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1. Ваш интерес к технологическим мероприятиям:',
          style: TextStyle(
            fontFamily: 'Cornerita',
            color: Colors.white,
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
                        const Icon(Icons.hexagon, color: Color(0xFFDAF7A8), size: 12),
                        const SizedBox(width: 8),
                        Text(
                          '${entry.key} - ${entry.value.toInt()}%',
                          style: TextStyle(
                            fontFamily: 'Cornerita',
                            color: Colors.white,
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
                chartRadius: MediaQuery.of(context).size.width / 6,
                colorList: const [
                  Color(0xFFDAF7A8),
                  Color(0xFFC0B2D6),
                  Color(0xFF8D72C1),
                  Color(0xFF6B48FF),
                ],
                initialAngleInDegree: 0,
                chartType: ChartType.disc,
                legendOptions: const LegendOptions(
                  showLegends: false,
                ),
                chartValuesOptions: const ChartValuesOptions(
                  showChartValues: false,
                ),
              ),
            ),
          ],
        ),
      ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '2. Предпочтения в вознаграждениях:',
          style: TextStyle(
            fontFamily: 'Cornerita',
            color: Colors.white,
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
                        const Icon(Icons.hexagon, color: Color(0xFFDAF7A8), size: 12),
                        const SizedBox(width: 8),
                        Text(
                          '${entry.key} - ${entry.value.toInt()}%',
                          style: TextStyle(
                            fontFamily: 'Cornerita',
                            color: Colors.white,
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
                chartRadius: MediaQuery.of(context).size.width / 6,
                colorList: const [
                  Color(0xFFDAF7A8),
                  Color(0xFFC0B2D6),
                  Color(0xFF8D72C1),
                ],
                initialAngleInDegree: 0,
                chartType: ChartType.disc,
                legendOptions: const LegendOptions(
                  showLegends: false,
                ),
                chartValuesOptions: const ChartValuesOptions(
                  showChartValues: false,
                ),
              ),
            ),
          ],
        ),
      ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '3. Выбор сувенира участника:',
          style: TextStyle(
            fontFamily: 'Cornerita',
            color: Colors.white,
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
                        const Icon(Icons.hexagon, color: Color(0xFFDAF7A8), size: 12),
                        const SizedBox(width: 8),
                        Text(
                          '${entry.key} - ${entry.value.toInt()}%',
                          style: TextStyle(
                            fontFamily: 'Cornerita',
                            color: Colors.white,
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
                chartRadius: MediaQuery.of(context).size.width / 6,
                colorList: const [
                  Color(0xFFDAF7A8),
                  Color(0xFFC0B2D6),
                  Color(0xFF8D72C1),
                ],
                initialAngleInDegree: 0,
                chartType: ChartType.disc,
                legendOptions: const LegendOptions(
                  showLegends: false,
                ),
                chartValuesOptions: const ChartValuesOptions(
                  showChartValues: false,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}