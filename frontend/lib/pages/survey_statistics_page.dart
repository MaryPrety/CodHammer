import 'package:flutter/material.dart';
import 'package:cod_hammer/services/api_service.dart';
import 'package:cod_hammer/providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:pie_chart/pie_chart.dart';

class SurveyStatisticsPage extends StatefulWidget {
  final int surveyId;
  final Map<String, dynamic> survey;

  const SurveyStatisticsPage({
    super.key,
    required this.surveyId,
    required this.survey,
  });

  @override
  State<SurveyStatisticsPage> createState() => _SurveyStatisticsPageState();
}

class _SurveyStatisticsPageState extends State<SurveyStatisticsPage> {
  Map<String, dynamic>? _statistics;
  bool _isLoading = true;
  String? _error;

  static const _backgroundColor = Color(0xFF062B42);
  static const _cardColor = Color(0xFF0A3B5C);
  static const _glowColor = Color(0xFFFAEFD9);
  static const _textColor = Color(0xFFCDFBE4);

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final statistics = await ApiService.getSurveyStatistics(widget.surveyId);
      if (mounted) {
        setState(() {
          _statistics = statistics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getTitle(bool isEnglish) {
    final titleData = widget.survey['title'];
    if (titleData is Map) {
      return isEnglish
          ? (titleData['en']?.toString() ?? titleData['ru']?.toString() ?? '')
          : (titleData['ru']?.toString() ?? titleData['en']?.toString() ?? '');
    }
    return titleData?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final isEnglish = languageProvider.isEnglish;
        final fontFamily = isEnglish ? 'Tomorrow' : 'Cornerita';

        return Scaffold(
          backgroundColor: _backgroundColor,
          appBar: AppBar(
            title: Text(
              isEnglish ? 'Survey Statistics' : 'Статистика опросника',
              style: const TextStyle(
                color: Color(0xFFD8CCFF),
              ),
            ),
            backgroundColor: _cardColor,
            iconTheme: const IconThemeData(color: Color(0xFFD8CCFF)),
          ),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_textColor),
                  ),
                )
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : _statistics == null
                      ? Center(
                          child: Text(
                            isEnglish
                                ? 'No statistics available'
                                : 'Статистика недоступна',
                            style: const TextStyle(color: _textColor),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Заголовок опросника
                              Text(
                                _getTitle(isEnglish),
                                style: TextStyle(
                                  color: _glowColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: fontFamily,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${isEnglish ? 'Total responses' : 'Всего ответов'}: ${_statistics!['total_responses'] ?? 0}',
                                style: TextStyle(
                                  color: _textColor,
                                  fontSize: 16,
                                  fontFamily: fontFamily,
                                ),
                              ),
                              const SizedBox(height: 30),
                              // Статистика по каждому вопросу
                              ...((_statistics!['questions'] as List<dynamic>?) ?? []).map((questionData) {
                                return _buildQuestionStatistics(
                                  questionData as Map<String, dynamic>,
                                  isEnglish,
                                  fontFamily,
                                );
                              }),
                            ],
                          ),
                        ),
        );
      },
    );
  }

  Widget _buildQuestionStatistics(
    Map<String, dynamic> questionData,
    bool isEnglish,
    String fontFamily,
  ) {
    final questionIndex = questionData['question_index'] ?? 0;
    final questionText = questionData['question_text'] ?? '';
    final options = (questionData['options'] as List<dynamic>?) ?? [];
    final statistics = (questionData['statistics'] as Map<String, dynamic>?) ?? {};
    final percentages = (questionData['percentages'] as Map<String, dynamic>?) ?? {};
    final totalResponses = _statistics!['total_responses'] as int? ?? 0;

    // Формируем данные для диаграммы
    final Map<String, double> dataMap = {};
    for (var option in options) {
      final optionStr = option.toString();
      final count = (statistics[optionStr] as num?)?.toInt() ?? 0;
      if (totalResponses > 0) {
        dataMap[optionStr] = (count / totalResponses * 100);
      } else {
        dataMap[optionStr] = 0.0;
      }
    }

    // Цвета для диаграммы
    final colorList = [
      const Color(0xFFCDFBE4),
      const Color(0xFFFAEFD9),
      Colors.white70,
      const Color(0xFFB19CD9),
      const Color(0xFFD8CCFF),
      Colors.cyanAccent,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _glowColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${isEnglish ? 'Question' : 'Вопрос'} $questionIndex: $questionText',
            style: TextStyle(
              color: _glowColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: fontFamily,
            ),
          ),
          const SizedBox(height: 20),
          if (totalResponses == 0)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                isEnglish
                    ? 'No responses yet'
                    : 'Пока нет ответов',
                style: TextStyle(
                  color: _textColor.withOpacity(0.7),
                  fontSize: 14,
                  fontFamily: fontFamily,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: options.map((option) {
                      final optionStr = option.toString();
                      final count = (statistics[optionStr] as num?)?.toInt() ?? 0;
                      final percentage = (percentages[optionStr] as num?)?.toDouble() ?? 0.0;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colorList[options.indexOf(option) % colorList.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    optionStr,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontFamily: fontFamily,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$count ${isEnglish ? 'votes' : 'голосов'} (${percentage.toStringAsFixed(1)}%)',
                                    style: TextStyle(
                                      color: _textColor.withOpacity(0.8),
                                      fontSize: 12,
                                      fontFamily: fontFamily,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 150,
                  height: 150,
                  child: PieChart(
                    dataMap: dataMap,
                    animationDuration: const Duration(milliseconds: 800),
                    chartRadius: 60,
                    colorList: colorList,
                    initialAngleInDegree: 0,
                    chartType: ChartType.disc,
                    legendOptions: const LegendOptions(showLegends: false),
                    chartValuesOptions: const ChartValuesOptions(showChartValues: false),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
