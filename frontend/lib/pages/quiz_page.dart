// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:cod_hammer/pages/detailed_question_page.dart';
import 'package:cod_hammer/providers/language_provider.dart';
import 'package:cod_hammer/services/api_service.dart';
import 'package:cod_hammer/pages/create_survey_page.dart';
import 'package:cod_hammer/pages/survey_statistics_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<dynamic> _surveys = [];
  bool _isLoading = true;
  String? _userRole;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadSurveys();
    // Обновляем таймер каждую минуту
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
      // Игнорируем ошибку
    }
  }

  Future<void> _loadSurveys() async {
    try {
      final surveys = await ApiService.getSurveys();
      if (mounted) {
        setState(() {
          _surveys = surveys;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatTimeLeft(DateTime? endDate, bool isEnglish) {
    if (endDate == null) return '';
    
    final now = DateTime.now();
    if (endDate.isBefore(now)) {
      return isEnglish ? 'Ended' : 'Завершён';
    }

    final difference = endDate.difference(now);
    
    if (difference.inDays > 0) {
      return isEnglish 
          ? '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} left'
          : '${difference.inDays} ${_getDayWord(difference.inDays)} осталось';
    } else if (difference.inHours > 0) {
      return isEnglish
          ? '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} left'
          : '${difference.inHours} ${_getHourWord(difference.inHours)} осталось';
    } else if (difference.inMinutes > 0) {
      return isEnglish
          ? '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} left'
          : '${difference.inMinutes} ${_getMinuteWord(difference.inMinutes)} осталось';
    } else {
      return isEnglish ? 'Ending soon' : 'Заканчивается';
    }
  }

  String _getDayWord(int days) {
    if (days % 10 == 1 && days % 100 != 11) return 'день';
    if (days % 10 >= 2 && days % 10 <= 4 && (days % 100 < 10 || days % 100 >= 20)) return 'дня';
    return 'дней';
  }

  String _getHourWord(int hours) {
    if (hours % 10 == 1 && hours % 100 != 11) return 'час';
    if (hours % 10 >= 2 && hours % 10 <= 4 && (hours % 100 < 10 || hours % 100 >= 20)) return 'часа';
    return 'часов';
  }

  String _getMinuteWord(int minutes) {
    if (minutes % 10 == 1 && minutes % 100 != 11) return 'минута';
    if (minutes % 10 >= 2 && minutes % 10 <= 4 && (minutes % 100 < 10 || minutes % 100 >= 20)) return 'минуты';
    return 'минут';
  }

  String _formatVotes(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF062B42),
      floatingActionButton: _userRole == 'admin'
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateSurveyPage(),
                  ),
                );
                if (result == true) {
                  _loadSurveys();
                }
              },
              backgroundColor: const Color(0xFFFAEFD9),
              child: const Icon(
                Icons.add,
                color: Color(0xFF062B42),
              ),
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return SingleChildScrollView(
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 480),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Consumer<LanguageProvider>(
                  builder: (context, languageProvider, _) {
                    final isRussian = languageProvider.isRussian;
                    final isEnglish = !isRussian;

                    if (_isLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFCDFBE4)),
                          ),
                        ),
                      );
                    }

                    if (_surveys.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Text(
                            isEnglish ? 'No surveys available' : 'Нет доступных опросников',
                            style: const TextStyle(
                              color: Color(0xFFCDFBE4),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        ..._surveys.map((survey) {
                          final endDateStr = survey['end_date'];
                          DateTime? endDate;
                          if (endDateStr != null) {
                            endDate = DateTime.tryParse(endDateStr.toString());
                          }
                          final isPassed = endDate != null && endDate.isBefore(DateTime.now());
                          final responseCount = survey['response_count'] ?? 0;
                          final imageUrl = survey['image_url']?.toString() ?? 'assets/Fight_robots.png';
                          
                          // Поддержка многоязычных названий
                          String title = '';
                          final titleData = survey['title'];
                          if (titleData is Map) {
                            // Если title - это объект с ru и en
                            title = isRussian 
                                ? (titleData['ru']?.toString() ?? titleData['en']?.toString() ?? '')
                                : (titleData['en']?.toString() ?? titleData['ru']?.toString() ?? '');
                          } else {
                            // Если title - это просто строка
                            title = titleData?.toString() ?? '';
                          }
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 50),
                            child: _buildQuizQuestion(
                              survey: survey,
                              imageUrl: imageUrl,
                              timeLeft: _formatTimeLeft(endDate, isEnglish),
                              votes: _formatVotes(responseCount),
                              question: title,
                              isMobile: isMobile,
                              isRussian: isRussian,
                              isPassed: isPassed,
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuizQuestion({
    required Map<String, dynamic> survey,
    required String imageUrl,
    required String timeLeft,
    required String votes,
    required String question,
    required bool isMobile,
    required bool isRussian,
    bool isPassed = false,
  }) {
    final surveyId = survey['id'] as int?;
    final isAdmin = _userRole == 'admin';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailedQuestionPage(survey: survey),
              ),
            ).then((_) {
              _loadSurveys();
            });
          },
          child: _buildOctagonFrame(
            imageUrl: imageUrl,
            width: isMobile ? 80 : 90,
            height: isMobile ? 80 : 90,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Row(
                    children: [
                      Image.asset(
                        isPassed ? 'assets/time_passed.png' : 'assets/time_actual.png',
                        width: 15,
                        height: 15 / 0.75,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeLeft,
                        style: TextStyle(
                          color: const Color(0xFFCDFBE4),
                          fontSize: isRussian ? 16 : 14,
                          fontFamily: isRussian ? 'Cornerita' : 'Tomorrow',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 36),
                  Row(
                    children: [
                      Image.asset(
                        isPassed ? 'assets/avatar_passed.png' : 'assets/avatar_actual.png',
                        width: 15,
                        height: 15,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        votes,
                        style: TextStyle(
                          color: const Color(0xFFCDFBE4),
                          fontSize: isRussian ? 16 : 14,
                          fontFamily: isRussian ? 'Cornerita' : 'Tomorrow',
                        ),
                      ),
                    ],
                  ),
                  if (isAdmin && surveyId != null) ...[
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.bar_chart,
                        color: Color(0xFFCDFBE4),
                        size: 28,
                      ),
                      iconSize: 28,
                      tooltip: isRussian ? 'Статистика' : 'Statistics',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SurveyStatisticsPage(
                              surveyId: surveyId,
                              survey: survey,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                question,
                style: TextStyle(
                  color: const Color(0xFFCDFBE4),
                  fontSize: isRussian ? 16 : 14,
                  fontFamily: isRussian ? 'Cornerita' : 'Tomorrow',
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOctagonFrame({
    required String imageUrl,
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.8),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.4),
            offset: const Offset(0, 0),
            blurRadius: 6,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: imageUrl.startsWith('http') || imageUrl.startsWith('assets/')
            ? (imageUrl.startsWith('http')
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/placeholder.png',
                        fit: BoxFit.cover,
                      );
                    },
                  )
                : Image.asset(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/placeholder.png',
                        fit: BoxFit.cover,
                      );
                    },
                  ))
            : Image.asset(
                'assets/placeholder.png',
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}
