import 'package:flutter/material.dart';
import 'survey_page.dart';

class DetailedQuestionPage extends StatefulWidget {
  const DetailedQuestionPage({super.key});

  @override
  State<DetailedQuestionPage> createState() => _DetailedQuestionPageState();
}

class _DetailedQuestionPageState extends State<DetailedQuestionPage> {
  int _currentQuestionIndex = 0;
  List<int?> _answers = [null, null, null]; // Store selected answer index for each question

  static const Color secondaryColor = Color.fromRGBO(205, 251, 228, 1);
  static const Color tertiaryColor = Color(0xFFB19CD9);
  static const Color glowColor = Color(0xFFFAEFD9);

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
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: glowColor.withOpacity(0.8),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withOpacity(0.4),
                    offset: const Offset(0, 0),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/Fight_robots.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/placeholder.png',
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _questions[_currentQuestionIndex]['question'],
              style: const TextStyle(
                color: Color.fromRGBO(205, 251, 228, 1),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: (_questions[_currentQuestionIndex]['options'] as List<String>).length,
                itemBuilder: (context, index) {
                  String option = (_questions[_currentQuestionIndex]['options'] as List<String>)[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _answers[_currentQuestionIndex] = index;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _answers[_currentQuestionIndex] == index
                                ? secondaryColor.withOpacity(0.4) // Glow effect when selected
                                : tertiaryColor, // Normal border color
                            width: 2.0,
                          ),
                          boxShadow: _answers[_currentQuestionIndex] == index
                              ? [
                                  BoxShadow(
                                    color: secondaryColor.withOpacity(0.4),
                                    offset: const Offset(0, 0),
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                option,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color.fromRGBO(205, 251, 228, 1),
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
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
                              builder: (context) => SurveyResultsPage(answers: _answers),
                            ),
                          );
                        }
                      }
                    : null, // Disable button if no answer selected
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10), // Adjusted padding
                  backgroundColor: tertiaryColor, // Purple background for the button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5, // Add elevation for shadow effect
                  shadowColor: tertiaryColor.withOpacity(0.4), // Shadow color
                ),
                child: Text(
                  _currentQuestionIndex < _questions.length - 1 ? 'Continue' : 'Finish',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF062B42),
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