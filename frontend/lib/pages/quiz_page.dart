// ignore_for_file: deprecated_member_use

import 'package:cod_hammer/pages/detailed_question_page.dart';
import 'package:flutter/material.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  bool _isRussian = true; // Состояние для переключения языка

  String get currentFontFamily {
    return _isRussian ? 'Cornerita' : 'Tomorrow';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isRussian = !_isRussian; // Переключаем язык при нажатии
        });
      },
      child: Scaffold(
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
                      // Первый вопрос
                      _buildQuizQuestion(
                        questionNumber: 1, // Pass question number
                        imageUrl: 'assets/Fight_robots.png',
                        timeLeftIcon: 'assets/time_actual.png',
                        avatarIcon: 'assets/avatar_actual.png',
                        timeLeft: _isRussian ? '3 часа осталось' : '3 hours left',
                        votes: '24.2k',
                        question: _isRussian ? 'Какой вид вознаграждения вы бы хотели?' : 'What kind of reward would you like?',
                        aspectRatio: 0.97,
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 50),
                      // Второй вопрос
                      _buildQuizQuestion(
                        questionNumber: 2, // Pass question number
                        imageUrl: 'assets/Evtihiev.png',
                        timeLeftIcon: 'assets/time_passed.png',
                        avatarIcon: 'assets/avatar_passed.png',
                        timeLeft: _isRussian ? 'заканчивается' : 'is ending',
                        votes: '100.2k',
                        question: _isRussian ? 'Переименование улицы Евтихиева!' : 'Rename Evtikhiev street!',
                        aspectRatio: 1,
                        isMobile: isMobile,
                        isPassed: true,
                      ),
                      const SizedBox(height: 51),
                      // Заголовок комментариев с переводом
                      LanguageSensitiveText(
                        russianText: 'Комментарии пользователей',
                        englishText: 'User comments',
                        isMobile: isMobile,
                        isRussian: _isRussian,
                      ),
                      const SizedBox(height: 38),
                      // Первый комментарий
                      _buildComment(
                        avatarUrl: 'assets/avatar_1.png',
                        comment: _isRussian ? 'Как хорошо, что наконец-то стали прислушиваться к мнению студентов' : 'It\'s good that they finally started listening to students\' opinions',
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 40),
                      // Второй комментарий
                      _buildComment(
                        avatarUrl: 'assets/avatar_2.png',
                        comment: _isRussian ? 'Согласен, раньше с этим было тяжелее' : 'I agree, it used to be harder',
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
      ),
    );
  }

  // Метод для отображения вопроса
  Widget _buildQuizQuestion({
    required int questionNumber, // Add questionNumber parameter
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
        InkWell(
          onTap: () {
            if (questionNumber == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailedQuestionPage(),
                ),
              );
            }
          },
          child: _buildOctagonFrame(
            imageUrl: imageUrl,
            width: isMobile ? 80 : 90,
            height: (isMobile ? 80 : 90) / aspectRatio,
          ),
        ),
        const SizedBox(width: 10), // Увеличен отступ между изображением и текстом
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
                      const SizedBox(width: 8), // Увеличен отступ между иконкой и текстом
                      // Перевод времени
                      LanguageSensitiveText(
                        russianText: timeLeft,
                        englishText: timeLeft,
                        isMobile: isMobile,
                        isRussian: _isRussian,
                      ),
                    ],
                  ),
                  const SizedBox(width: 36), // Увеличен отступ между блоками
                  Row(
                    children: [
                      Image.asset(
                        avatarIcon,
                        width: 15,
                        height: 15,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8), // Увеличен отступ между иконкой и текстом
                      // Перевод количества голосов
                      LanguageSensitiveText(
                        russianText: votes,
                        englishText: votes,
                        isMobile: isMobile,
                        isRussian: _isRussian,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10), // Увеличен отступ между строками
              // Перевод основного текста вопроса
              LanguageSensitiveText(
                russianText: question,
                englishText: question,
                isMobile: isMobile,
                isRussian: _isRussian,
              ),
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
        const SizedBox(width: 15), // Увеличен отступ между аватаром и текстом
        Expanded(
          child: LanguageSensitiveText(
            russianText: comment,
            englishText: comment,
            isMobile: isMobile,
            isRussian: _isRussian,
          ),
        ),
      ],
    );
  }

  // Метод для создания закругленной рамки с изображением
Widget _buildOctagonFrame({
  required String imageUrl,
  required double width,
  required double height,
}) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18), // Закругленные углы
      border: Border.all(
        color: Colors.white.withOpacity(0.8), // Более яркий ободок
        width: 3, // Увеличенная толщина ободка
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.white.withOpacity(0.4),
          offset: const Offset(0, 0), // Смещение тени
          blurRadius: 6, // Радиус размытия
          spreadRadius: 2, // Расширение свечения
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14), // Закругленные углы для изображения
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

// Виджет для отображения текста с учетом языка
class LanguageSensitiveText extends StatelessWidget {
  final String russianText;
  final String englishText;
  final bool isMobile;
  final bool isRussian;

  const LanguageSensitiveText({
    super.key,
    required this.russianText,
    required this.englishText,
    required this.isMobile,
    required this.isRussian,
  });

  String get currentFontFamily {
    return isRussian ? 'Cornerita' : 'Tomorrow';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      isRussian ? russianText : englishText,
      style: TextStyle(
        color: const Color(0xFFCDFBE4),
        fontSize: isRussian ? 16 : 14, // Разные размеры шрифта для русского и английского
        fontFamily: currentFontFamily,
      ),
    );
  }
}
