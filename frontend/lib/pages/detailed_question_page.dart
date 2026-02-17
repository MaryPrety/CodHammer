import 'package:flutter/material.dart';
import 'package:cod_hammer/services/api_service.dart';

class DetailedQuestionPage extends StatefulWidget {
  final Map<String, dynamic> survey;

  const DetailedQuestionPage({super.key, required this.survey});

  @override
  State<DetailedQuestionPage> createState() => _DetailedQuestionPageState();
}

class _DetailedQuestionPageState extends State<DetailedQuestionPage> {
  int _currentQuestionIndex = 0;
  List<int?> _answers = [];
  bool _isSubmitting = false;

  static const Color secondaryColor = Color.fromRGBO(205, 251, 228, 1);
  static const Color tertiaryColor = Color(0xFFB19CD9);
  static const Color glowColor = Color(0xFFFAEFD9);

  List<Map<String, dynamic>> get _questions {
    final questions = widget.survey['questions'] as List<dynamic>? ?? [];
    return questions.map((q) => {
      'text': q['text'] ?? '',
      'options': (q['options'] as List<dynamic>?) ?? [],
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _answers = List.filled(_questions.length, null);
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
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  // ignore: deprecated_member_use
                  color: glowColor.withOpacity(0.8),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: glowColor.withOpacity(0.4),
                    offset: const Offset(0, 0),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _buildSurveyImage(),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _questions[_currentQuestionIndex]['text'] ?? '',
              style: const TextStyle(
                color: Color.fromRGBO(205, 251, 228, 1),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: (_questions[_currentQuestionIndex]['options']
                        as List<dynamic>)
                    .length,
                itemBuilder: (context, index) {
                  String option = (_questions[_currentQuestionIndex]['options']
                      as List<dynamic>)[index].toString();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _answers[_currentQuestionIndex] = index;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _answers[_currentQuestionIndex] == index
                                // ignore: deprecated_member_use
                                ? secondaryColor.withOpacity(
                                    0.4) // Glow effect when selected
                                : tertiaryColor, // Normal border color
                            width: 2.0,
                          ),
                          boxShadow: _answers[_currentQuestionIndex] == index
                              ? [
                                  BoxShadow(
                                    // ignore: deprecated_member_use
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
                onPressed: _answers[_currentQuestionIndex] != null && !_isSubmitting
                    ? () async {
                        if (_currentQuestionIndex < _questions.length - 1) {
                          setState(() {
                            _currentQuestionIndex++;
                          });
                        } else {
                          await _submitSurvey();
                        }
                      }
                    : null, // Disable button if no answer selected
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 10), // Adjusted padding
                  backgroundColor:
                      tertiaryColor, // Purple background for the button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5, // Add elevation for shadow effect
                  // ignore: deprecated_member_use
                  shadowColor: tertiaryColor.withOpacity(0.4), // Shadow color
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF062B42)),
                        ),
                      )
                    : Text(
                        _currentQuestionIndex < _questions.length - 1
                            ? 'Continue'
                            : 'Finish',
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

  Widget _buildSurveyImage() {
    final imageUrl = widget.survey['image_url']?.toString();
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http')) {
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/placeholder.png',
              fit: BoxFit.cover,
            );
          },
        );
      } else if (imageUrl.startsWith('assets/')) {
        return Image.asset(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/placeholder.png',
              fit: BoxFit.cover,
            );
          },
        );
      }
    }
    return Image.asset(
      'assets/Fight_robots.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/placeholder.png',
          fit: BoxFit.cover,
        );
      },
    );
  }

  Future<void> _submitSurvey() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final surveyId = widget.survey['id'] as int;
      final answers = _answers.map((a) => a ?? 0).toList();

      await ApiService.submitSurvey(
        surveyId: surveyId,
        answers: answers,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Опросник успешно пройден')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки ответов: $e')),
        );
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
