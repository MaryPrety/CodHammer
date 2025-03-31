import 'package:flutter/material.dart';
import 'package:translator/translator.dart';

class QuizPage extends StatelessWidget {
  const QuizPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF062B42),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return SingleChildScrollView(
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 480),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // Убран заголовок "CodHammer"
                    const SizedBox(height: 20), // Уменьшен интервал
                    // Первый вопрос
                    _buildQuizQuestion(
                      imageUrl: 'assets/Fight_robots.png',
                      timeLeftIcon: 'assets/time_actual.png',
                      avatarIcon: 'assets/avatar_actual.png',
                      timeLeft: '3 часа осталось',
                      votes: '24.2k',
                      question: 'Какой вид вознаграждения вы бы хотели?',
                      aspectRatio: 0.97,
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: 50),
                    // Второй вопрос
                    _buildQuizQuestion(
                      imageUrl: 'assets/Evtihiev.png',
                      timeLeftIcon: 'assets/time_passed.png',
                      avatarIcon: 'assets/avatar_passed.png',
                      timeLeft: 'заканчивается',
                      votes: '100.2k',
                      question: 'Переименование улицы Евтихиева!',
                      aspectRatio: 1,
                      isMobile: isMobile,
                      isPassed: true,
                    ),
                    const SizedBox(height: 51),
                    // Заголовок комментариев с переводом
                    TranslateText(
                      question: 'Комментарии пользователей',
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: 38),
                    // Первый комментарий
                    _buildComment(
                      avatarUrl: 'assets/avatar_1.png',
                      comment: 'Как хорошо, что наконец-то стали прислушиваться к мнению студентов',
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: 40),
                    // Второй комментарий
                    _buildComment(
                      avatarUrl: 'assets/avatar_2.png',
                      comment: 'Согласен, раньше с этим было тяжелее',
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Метод для отображения вопроса
  Widget _buildQuizQuestion({
    required String imageUrl,
    required String timeLeftIcon,
    required String avatarIcon,
    required String timeLeft,
    required String votes,
    required String question,
    required double aspectRatio,
    required bool isMobile,
    bool isPassed = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Изображение вопроса с восьмиугольной рамкой и свечением
        _buildOctagonFrame(
          imageUrl: imageUrl,
          width: isMobile ? 80 : 90,
          height: (isMobile ? 80 : 90) / aspectRatio,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Row(
                    children: [
                      Image.asset(
                        timeLeftIcon,
                        width: 15,
                        height: 15 / 0.75,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 4),
                      // Перевод времени
                      TranslateText(
                        question: timeLeft,
                        isMobile: isMobile,
                      ),
                    ],
                  ),
                  const SizedBox(width: 28),
                  Row(
                    children: [
                      Image.asset(
                        avatarIcon,
                        width: 15,
                        height: 15,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 4),
                      // Перевод количества голосов
                      TranslateText(
                        question: votes,
                        isMobile: isMobile,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 5),
              // Перевод основного текста вопроса
              TranslateText(question: question, isMobile: isMobile),
            ],
          ),
        ),
      ],
    );
  }

  // Метод для отображения комментария
  Widget _buildComment({
    required String avatarUrl,
    required String comment,
    required bool isMobile,
  }) {
    return Row(
      children: [
        // Аватар пользователя с восьмиугольной рамкой и свечением
        _buildOctagonFrame(
          imageUrl: avatarUrl,
          width: isMobile ? 50 : 60,
          height: isMobile ? 50 : 60,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TranslateText(question: comment, isMobile: isMobile),
        ),
      ],
    );
  }

  // Метод для создания восьмиугольной рамки с изображением
  Widget _buildOctagonFrame({
    required String imageUrl,
    required double width,
    required double height,
  }) {
    return ClipPath(
      clipper: SharpOctagonClipper(),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white.withOpacity(0.9), // Более яркий ободок
            width: 3, // Увеличенная толщина ободка
          ),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(250, 239, 217, 0.8), // Более яркое свечение
              offset: const Offset(0, 0),
              blurRadius: 16, // Увеличен радиус размытия
              spreadRadius: 4, // Расширенное свечение
            ),
          ],
        ),
        child: Image.asset(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/placeholder.png',
              fit: BoxFit.cover,
            );
          },
        ),
      ),
    );
  }
}

// CustomClipper для восьмиугольной формы с острыми углами
class SharpOctagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const cornerSize = 8.0; // Размер срезанных углов (увеличено для более четкой формы)

    // Верхняя часть
    path.moveTo(cornerSize, 0); // Начало слева сверху
    path.lineTo(size.width - cornerSize, 0); // Линия вправо до угла
    path.lineTo(size.width, cornerSize); // Угол справа сверху

    // Правая сторона
    path.lineTo(size.width, size.height - cornerSize); // Линия вниз до угла
    path.lineTo(size.width - cornerSize, size.height); // Угол справа снизу

    // Нижняя часть
    path.lineTo(cornerSize, size.height); // Линия влево до угла
    path.lineTo(0, size.height - cornerSize); // Угол слева снизу

    // Левая сторона
    path.lineTo(0, cornerSize); // Линия вверх до угла
    path.close(); // Замыкаем путь

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Виджет для перевода текста
class TranslateText extends StatefulWidget {
  final String question;
  final bool isMobile;

  const TranslateText({
    super.key,
    required this.question,
    required this.isMobile,
  });

  @override
  _TranslateTextState createState() => _TranslateTextState();
}

class _TranslateTextState extends State<TranslateText> {
  bool _isTranslated = false; // Флаг для переключения языка текста

  Future<String> translateText(String text) async {
    final translator = GoogleTranslator();
    // Перевод с русского на английский
    final translation = await translator.translate(text, from: 'ru', to: 'en');
    return translation.text;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: translateText(widget.question),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text(
            'Error: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          );
        } else if (snapshot.hasData) {
          final String translatedText = snapshot.data!;
          return GestureDetector(
            onTap: () {
              setState(() {
                _isTranslated = !_isTranslated;
              });
            },
            child: Text(
              _isTranslated ? translatedText : widget.question,
              style: TextStyle(
                color: const Color(0xFFCDFBE4),
                fontSize: widget.isMobile ? 16 : 20,
                fontFamily: 'Tomorrow',
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        } else {
          return const Text('No data available');
        }
      },
    );
  }
}