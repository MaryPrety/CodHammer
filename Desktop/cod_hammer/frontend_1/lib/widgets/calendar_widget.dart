import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:translator/translator.dart';
import 'package:intl/intl.dart'; // Для форматирования даты
import 'package:url_launcher/url_launcher.dart';

class CalendarWidget extends StatefulWidget {
  const CalendarWidget({super.key, required String fontFamily});

  @override
  _CalendarWidgetState createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCDFBE4), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCDFBE4).withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 400,
          width: double.infinity,
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailedDayPage(selectedDay: selectedDay),
                ),
              );
            },
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: const TextStyle(
                fontFamily: 'Cornerita',
                color: Color(0xFFD8CCFF),
                fontSize: 20,
              ),
              leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.transparent),
              rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.transparent),
              headerPadding: const EdgeInsets.symmetric(vertical: 6),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: const TextStyle(
                fontFamily: 'Cornerita',
                color: Color(0xFFCDFBE4),
                fontSize: 14,
              ),
              weekendStyle: const TextStyle(
                fontFamily: 'Cornerita',
                color: Color(0xFFCDFBE4),
                fontSize: 12,
              ),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: const Color(0xFFD8CCFF).withOpacity(0.3),
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(6),
              ),
              selectedDecoration: BoxDecoration(
                color: const Color(0xFFD8CCFF).withOpacity(0.5),
                shape: BoxShape.rectangle,
                border: Border.all(color: const Color(0xFFD8CCFF), width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              weekendTextStyle: const TextStyle(
                color: Color(0xFFFAEFD9),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              defaultTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
                final weekdays = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
                return Center(
                  child: Text(
                    weekdays[day.weekday - 1],
                    style: const TextStyle(
                      fontFamily: 'Cornerita',
                      color: Color(0xFFCDFBE4),
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class DetailedDayPage extends StatefulWidget {
  final DateTime selectedDay;

  const DetailedDayPage({super.key, required this.selectedDay});

  @override
  _DetailedDayPageState createState() => _DetailedDayPageState();
}

class _DetailedDayPageState extends State<DetailedDayPage> {
  bool _isTranslated = false; // Флаг для переключения языка текста

  Future<String> translateText(String text) async {
    final translator = GoogleTranslator();
    final translation = await translator.translate(text, from: 'ru', to: 'en');
    return translation.text;
  }

  Widget _buildEventColumn({
    required String image,
    required String description,
    required String url,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebViewPage(url: url),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(205, 251, 228, 0.32),
                  offset: const Offset(-11, 11),
                  blurRadius: 49,
                ),
              ],
            ),
            child: Image.network(
              image,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 11),
          FutureBuilder<String>(
            future: translateText(description),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text(
                  'Ошибка перевода',
                  style: TextStyle(color: Colors.red),
                );
              } else if (snapshot.hasData) {
                final String translatedText = snapshot.data!;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _isTranslated = !_isTranslated;
                    });
                  },
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        color: const Color.fromRGBO(216, 204, 255, 1),
                        fontSize: _isTranslated ? 14 : 16, 
                        fontFamily: _isTranslated ? 'Tomorrow' : 'Cornerita',
                        
                      ),
                      children: [
                        TextSpan(
                          text: _isTranslated ? translatedText : description,
                          style: const TextStyle(
                            color: Color.fromRGBO(250, 239, 217, 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return const Text('Данные недоступны');
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('d MMMM', 'ru_RU').format(widget.selectedDay);

    return Scaffold(
      backgroundColor: const Color.fromRGBO(6, 43, 66, 1), // Установлен правильный фон
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(6, 43, 66, 1), // Согласован с общим фоном
        title: Text(
          'Детали ${widget.selectedDay.day}.${widget.selectedDay.month}.${widget.selectedDay.year}',
          style: const TextStyle(
            color: Color(0xFFD8CCFF),
            fontFamily: 'Cornerita',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFD8CCFF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          color: const Color.fromRGBO(6, 43, 66, 1), // Общий фон страницы
          width: double.infinity,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                 
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(6, 43, 66, 1), // Согласован с общим фоном
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      formattedDate,
                      style: const TextStyle(
                        color: Color.fromRGBO(216, 204, 255, 1),
                        fontFamily: 'Tomorrow',
                        fontSize: 20,
                        
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    child: FutureBuilder<String>(
                      future: translateText(
                        'Пока нет событий, но мы можем предоставить информацию о том, чего ожидать или что уже произошло.',
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text(
                            'Ошибка перевода',
                            style: TextStyle(color: Colors.red),
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
                              _isTranslated
                                  ? translatedText
                                  : 'Пока нет событий, но мы можем предоставить информацию о том, чего ожидать или что уже произошло.',
                              style: TextStyle(
                                color: const Color.fromRGBO(205, 251, 228, 1),
                                fontSize: _isTranslated ? 14 : 16, 
                                fontFamily: _isTranslated ? 'Tomorrow' : 'Cornerita',
                                
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        } else {
                          return const Text('Данные недоступны');
                        }
                      },
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 406),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildEventColumn(
                          image:
                              'https://cdn.builder.io/api/v1/image/assets/360f9df7d3f54bedb1c96ecdb7a87f2d/cf91c52925fcbdaca5ba8be6e3420043a1c6b7b5?placeholderIfAbsent=true',
                          description:
                              'Хакатон\nПрошедшее событие: Идея от T1 Дата: 22 марта\nФормат: Оффлайн (в 7 городах России)\nУчастники: Студенты и начинающие специалисты в области разработки, анализа, тестирования и ИИ',
                          url: 'https://u.to/TuUyIg',
                        ),
                        const SizedBox(height: 20),
                        _buildEventColumn(
                          image:
                              'https://cdn.builder.io/api/v1/image/assets/360f9df7d3f54bedb1c96ecdb7a87f2d/a4284e5498f7a281280bcd8fada141c9642d92f2?placeholderIfAbsent=true',
                          description:
                              'Хакатон\nПредстоящее событие: Конкурс Data Fusion 2025 Дата: 7 апреля\nФормат: Онлайн\nУчастники: Эксперты в области анализа данных и машинного обучения',
                          url: 'https://u.to/l_UyIg',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50), // Добавлен дополнительный отступ внизу
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WebViewPage extends StatelessWidget {
  final String url;

  const WebViewPage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(6, 43, 66, 1), // Согласован с общим фоном
        title: const Text(
          'Ссылка',
          style: TextStyle(
            color: Color(0xFFD8CCFF),
            fontFamily: 'Cornerita',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFD8CCFF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final Uri uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Не удалось открыть ссылку')),
              );
            }
          },
          child: const Text('Перейти по ссылке'),
        ),
      ),
    );
  }
}