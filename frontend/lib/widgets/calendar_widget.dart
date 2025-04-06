import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:translator/translator.dart';

class CalendarWidget extends StatefulWidget {
  const CalendarWidget({super.key});

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
                fontFamily: 'StalinistOne',
                color: Color(0xFFD8CCFF),
                fontSize: 14,
              ),
              leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.transparent),
              rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.transparent),
              headerPadding: const EdgeInsets.symmetric(vertical: 6),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontFamily: 'StalinistOne',
                color: Color(0xFFCDFBE4),
                fontSize: 10,
              ),
              weekendStyle: TextStyle(
                fontFamily: 'StalinistOne',
                color: Color(0xFFCDFBE4),
                fontSize: 10,
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
                fontSize: 10,
              ),
              defaultTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              dowBuilder: (context, day) {
                final weekdays = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
                return Center(
                  child: Text(
                    weekdays[day.weekday - 1],
                    style: const TextStyle(
                      fontFamily: 'StalinistOne',
                      color: Color(0xFFCDFBE4),
                      fontSize: 10,
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

  Widget _buildPastEventColumn() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(205, 251, 228, 0.32),
                  offset: Offset(-11, 11),
                  blurRadius: 49,
                ),
              ],
            ),
            child: Image.network(
              'https://cdn.builder.io/api/v1/image/assets/360f9df7d3f54bedb1c96ecdb7a87f2d/cf91c52925fcbdaca5ba8be6e3420043a1c6b7b5?placeholderIfAbsent=true',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 11),
          FutureBuilder<String>(
            future: translateText(
              'Хакатон\nПрошедшее событие: Идея от T1 Дата: 22 марта\nФормат: Оффлайн (в 7 городах России)\nУчастники: Студенты и начинающие специалисты в области разработки, анализа, тестирования и ИИ',
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
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        color: Color.fromRGBO(216, 204, 255, 1),
                        fontSize: 14,
                        fontFamily: 'Tomorrow',
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: _isTranslated ? translatedText : 'Хакатон\nПрошедшее событие: Идея от T1 Дата: 22 марта\nФормат: Оффлайн (в 7 городах России)\nУчастники: Студенты и начинающие специалисты в области разработки, анализа, тестирования и ИИ',
                          style: TextStyle(
                            color: Color.fromRGBO(250, 239, 217, 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return Text('Данные недоступны');
              }
            },
          ),
          const SizedBox(height: 38),
          InkWell(
            onTap: () {},
            child: const Text(
              'https://u.to/TuUyIg',
              style: TextStyle(
                color: Color.fromRGBO(205, 251, 228, 1),
                fontSize: 12,
                fontFamily: 'Tomorrow',
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventColumn() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(216, 204, 255, 0.32),
                  offset: Offset(-8, 8),
                  blurRadius: 45,
                ),
              ],
            ),
            child: Image.network(
              'https://cdn.builder.io/api/v1/image/assets/360f9df7d3f54bedb1c96ecdb7a87f2d/a4284e5498f7a281280bcd8fada141c9642d92f2?placeholderIfAbsent=true',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 11),
          FutureBuilder<String>(
            future: translateText(
              'Хакатон\nПредстоящее событие: Конкурс Data Fusion 2025 Дата: 7 апреля\nФормат: Онлайн\nУчастники: Эксперты в области анализа данных и машинного обучения',
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
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        color: Color.fromRGBO(205, 251, 228, 1),
                        fontSize: 14,
                        fontFamily: 'Tomorrow',
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: _isTranslated ? translatedText : 'Хакатон\nПредстоящее событие: Конкурс Data Fusion 2025 Дата: 7 апреля\nФормат: Онлайн\nУчастники: Эксперты в области анализа данных и машинного обучения',
                          style: TextStyle(
                            color: Color.fromRGBO(216, 204, 255, 1),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return Text('Данные недоступны');
              }
            },
          ),
          const SizedBox(height: 56),
          InkWell(
            onTap: () {},
            child: const Text(
              'https://u.to/l_UyIg',
              style: TextStyle(
                color: Color.fromRGBO(216, 204, 255, 1),
                fontSize: 12,
                fontFamily: 'Tomorrow',
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Детали ${widget.selectedDay.day}.${widget.selectedDay.month}.${widget.selectedDay.year}',
          style: const TextStyle(
            color: Color(0xFFD8CCFF),
            fontFamily: 'StalinistOne',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFD8CCFF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          color: const Color.fromRGBO(6, 43, 66, 1),
          width: double.infinity,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 70),
                  // CodHammer Title
                  Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: const Text(
                      'CodHammer',
                      style: TextStyle(
                        color: Color.fromRGBO(205, 251, 228, 1),
                        fontSize: 32,
                        fontFamily: 'Stalinist One',
                        fontWeight: FontWeight.w400,
                        shadows: [
                          Shadow(
                            color: Color.fromRGBO(0, 27, 44, 0.45),
                            offset: Offset(0, 4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Date
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    child: const Text(
                      '24 марта',
                      style: TextStyle(
                        color: Color.fromRGBO(216, 204, 255, 1),
                        fontFamily: 'Tomorrow',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Description
                  Container(
                    margin: const EdgeInsets.only(top: 38),
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
                              _isTranslated ? translatedText : 'Пока нет событий, но мы можем предоставить информацию о том, чего ожидать или что уже произошло.',
                              style: TextStyle(
                                color: Color.fromRGBO(205, 251, 228, 1),
                                fontSize: 16,
                                fontFamily: 'Tomorrow',
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        } else {
                          return Text('Данные недоступны');
                        }
                      },
                    ),
                  ),
                  // Two columns section
                  Container(
                    margin: const EdgeInsets.only(top: 32),
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 406),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPastEventColumn(),
                        const SizedBox(width: 20),
                        _buildUpcomingEventColumn(),
                      ],
                    ),
                  ),
                  // Poll section
                  Container(
                    margin: const EdgeInsets.only(top: 29),
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 352),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.network(
                          'https://cdn.builder.io/api/v1/image/assets/360f9df7d3f54bedb1c96ecdb7a87f2d/f8a4d7be307a89c9efda7aac2e64c201d226206e?placeholderIfAbsent=true',
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 10),
                        FutureBuilder<String>(
                          future: translateText('Опрос: Будете ли вы участвовать в конкурсе Data Fusion 2025?'),
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
                                  _isTranslated ? translatedText : 'Опрос: Будете ли вы участвовать в конкурсе Data Fusion 2025?',
                                  style: TextStyle(
                                    color: Color.fromRGBO(216, 204, 255, 1),
                                    fontSize: 17,
                                    fontFamily: 'Tomorrow',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            } else {
                              return Text('Данные недоступны');
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            RadioListTile<String>(
                              title: const Text('Боевой робот с подсветкой и звуковыми эффектами'),
                              value: 'option1',
                              groupValue: null,
                              onChanged: (value) {},
                            ),
                            RadioListTile<String>(
                              title: const Text('Футболка или худи с уникальным дизайном'),
                              value: 'option2',
                              groupValue: null,
                              onChanged: (value) {},
                            ),
                            RadioListTile<String>(
                              title: const Text('Интерактивный набор для создания мини-робота'),
                              value: 'option3',
                              groupValue: null,
                              onChanged: (value) {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                          ),
                          child: const Text(
                            'Сохранить',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}