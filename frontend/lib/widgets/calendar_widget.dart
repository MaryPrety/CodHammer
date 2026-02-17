// ignore_for_file: library_private_types_in_public_api, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:translator/translator.dart';
import 'package:intl/intl.dart'; // Для форматирования даты
import 'package:url_launcher/url_launcher.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../pages/create_event_page.dart';
import 'package:provider/provider.dart';

class CalendarWidget extends StatefulWidget {
  const CalendarWidget({super.key});

  @override
  _CalendarWidgetState createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {

  late DateTime _focusedDay;
  late DateTime _selectedDay;
  Set<DateTime> _eventDates = {}; // Только активные события для отображения точек

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
      try {
        final events = await ApiService.getEvents();
        if (mounted) {
          setState(() {
            _eventDates = {};
            final now = DateTime.now();
            
            for (var event in events) {
              if (event['start_date'] != null) {
                final dateStr = event['start_date'].toString();
                final startDate = DateTime.tryParse(dateStr);
                
                if (startDate != null) {
                  // Проверяем, завершено ли событие
                  bool isCompleted = false;
                  if (event['end_date'] != null) {
                    final endDateStr = event['end_date'].toString();
                    final endDate = DateTime.tryParse(endDateStr);
                    if (endDate != null) {
                      isCompleted = endDate.isBefore(now);
                    }
                  }
                  
                  // Добавляем в календарь только активные (не завершённые) события
                  if (!isCompleted) {
                    final dayOnly = DateTime(startDate.year, startDate.month, startDate.day);
                    _eventDates.add(dayOnly);
                  }
                }
              }
            }
          });
        }
      } catch (e) {
        // Игнорируем ошибку
      }
  }

  bool _isEventDay(DateTime day) {
    final dayOnly = DateTime(day.year, day.month, day.day);
    return _eventDates.contains(dayOnly);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final isEnglish = languageProvider.isEnglish;
        final fontFamily = isEnglish ? 'Tomorrow' : 'Cornerita';
        final weekdays = isEnglish 
            ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
            : ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];
        
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
                eventLoader: (day) {
                  return _isEventDay(day) ? [1] : [];
                },
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
                  ).then((_) {
                    // Обновляем события после возврата со страницы деталей
                    _loadEvents();
                  });
                },
                locale: isEnglish ? 'en_US' : 'ru_RU',
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontFamily: fontFamily,
                    color: const Color(0xFFD8CCFF),
                    fontSize: 20,
                  ),
                  leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.transparent),
                  rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.transparent),
                  headerPadding: const EdgeInsets.symmetric(vertical: 6),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    fontFamily: fontFamily,
                    color: const Color(0xFFCDFBE4),
                    fontSize: 14,
                  ),
                  weekendStyle: TextStyle(
                    fontFamily: fontFamily,
                    color: const Color(0xFFCDFBE4),
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
                  weekendTextStyle: TextStyle(
                    color: const Color(0xFFFAEFD9),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    fontFamily: fontFamily,
                  ),
                  defaultTextStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    fontFamily: fontFamily,
                  ),
                  markerDecoration: BoxDecoration(
                    color: const Color(0xFFCDFBE4),
                    shape: BoxShape.circle,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  dowBuilder: (context, day) {
                    return Center(
                      child: Text(
                        weekdays[day.weekday - 1],
                        style: TextStyle(
                          fontFamily: fontFamily,
                          color: const Color(0xFFCDFBE4),
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                  markerBuilder: (context, date, events) {
                    if (events.isNotEmpty) {
                      return Positioned(
                        bottom: 1,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFCDFBE4),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        );
      },
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
  List<dynamic> _dayEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDayEvents();
  }

  Future<void> _loadDayEvents() async {
    try {
      final allEvents = await ApiService.getEvents();
      if (mounted) {
        setState(() {
          _dayEvents = allEvents.where((event) {
            if (event['start_date'] == null) return false;
            final dateStr = event['start_date'].toString();
            final eventDate = DateTime.tryParse(dateStr);
            if (eventDate == null) return false;
            // Сравниваем только дату без времени
            return eventDate.year == widget.selectedDay.year &&
                   eventDate.month == widget.selectedDay.month &&
                   eventDate.day == widget.selectedDay.day;
          }).toList();
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

  // Проверка, завершено ли событие
  bool _isEventCompleted(Map<String, dynamic> event) {
    if (event['end_date'] == null) return false;
    final endDateStr = event['end_date'].toString();
    final endDate = DateTime.tryParse(endDateStr);
    if (endDate == null) return false;
    return endDate.isBefore(DateTime.now());
  }

  Future<String> translateText(String text) async {
    final translator = GoogleTranslator();
    final translation = await translator.translate(text, from: 'ru', to: 'en');
    return translation.text;
  }

  Widget _buildEventCard(Map<String, dynamic> event, bool isEnglish, String fontFamily) {
    final title = event['title'] ?? '';
    final description = event['description'] ?? '';
    final type = event['type'] ?? '';
    final startDate = event['start_date'];
    final isCompleted = _isEventCompleted(event);
    
    String formattedTime = '';
    if (startDate != null) {
      try {
        final date = DateTime.tryParse(startDate.toString());
        if (date != null) {
          formattedTime = DateFormat('HH:mm').format(date);
        }
      } catch (e) {
        // Игнорируем ошибку
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailsPage(event: event),
          ),
        );
      },
      child: Opacity(
        opacity: isCompleted ? 0.6 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(10, 59, 92, 1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCompleted 
                  ? Colors.grey.withOpacity(0.5)
                  : const Color(0xFFCDFBE4).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: isCompleted 
                                  ? Colors.grey
                                  : const Color(0xFFFAEFD9),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: fontFamily,
                              decoration: isCompleted 
                                  ? TextDecoration.lineThrough 
                                  : TextDecoration.none,
                            ),
                          ),
                        ),
                        if (isCompleted)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isEnglish ? 'Completed' : 'Завершено',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                                fontFamily: fontFamily,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (formattedTime.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.grey.withOpacity(0.2)
                            : const Color(0xFFCDFBE4).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        formattedTime,
                        style: TextStyle(
                          color: isCompleted
                              ? Colors.grey
                              : const Color(0xFFCDFBE4),
                          fontSize: 12,
                          fontFamily: fontFamily,
                        ),
                      ),
                    ),
                ],
              ),
              if (type.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  type,
                  style: TextStyle(
                    color: isCompleted
                        ? Colors.grey.withOpacity(0.6)
                        : const Color(0xFFCDFBE4).withOpacity(0.8),
                    fontSize: 14,
                    fontFamily: fontFamily,
                  ),
                ),
              ],
              if (description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCompleted
                        ? Colors.grey.withOpacity(0.7)
                        : Colors.white70,
                    fontSize: 14,
                    fontFamily: fontFamily,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    isEnglish ? 'More details' : 'Подробнее',
                    style: TextStyle(
                      color: isCompleted
                          ? Colors.grey
                          : const Color(0xFFCDFBE4),
                      fontSize: 12,
                      fontFamily: fontFamily,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: isCompleted
                        ? Colors.grey
                        : const Color(0xFFCDFBE4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final isEnglish = languageProvider.isEnglish;
        final locale = isEnglish ? 'en_US' : 'ru_RU';
        final String formattedDate = DateFormat('d MMMM', locale).format(widget.selectedDay);
        final fontFamily = isEnglish ? 'Tomorrow' : 'Cornerita';
        final titleText = isEnglish 
            ? 'Details ${widget.selectedDay.day}.${widget.selectedDay.month}.${widget.selectedDay.year}'
            : 'Детали ${widget.selectedDay.day}.${widget.selectedDay.month}.${widget.selectedDay.year}';

        return FutureBuilder<String?>(
          future: ApiService.getUserRole(),
          builder: (context, snapshot) {
            final isAdmin = snapshot.data == 'admin';
            return Scaffold(
              backgroundColor: const Color.fromRGBO(6, 43, 66, 1), // Установлен правильный фон
              appBar: AppBar(
                backgroundColor: const Color.fromRGBO(6, 43, 66, 1), // Согласован с общим фоном
                title: Text(
                  titleText,
                  style: TextStyle(
                    color: const Color(0xFFD8CCFF),
                    fontFamily: fontFamily,
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFFD8CCFF)),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: isAdmin
                    ? [
                        IconButton(
                          icon: const Icon(Icons.add, color: Color(0xFFD8CCFF)),
                          tooltip: isEnglish ? 'Create event' : 'Создать событие',
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateEventPage(
                                  selectedDate: widget.selectedDay,
                                ),
                              ),
                            );
                            if (result == true) {
                              Navigator.pop(context, true);
                            }
                          },
                        ),
                      ]
                    : null,
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
                      style: TextStyle(
                        color: const Color.fromRGBO(216, 204, 255, 1),
                        fontFamily: fontFamily,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (!_isLoading && _dayEvents.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      child: FutureBuilder<String>(
                        key: ValueKey(isEnglish), // Пересоздаем FutureBuilder при изменении языка
                        future: translateText(
                          'Пока нет событий, но мы можем предоставить информацию о том, чего ожидать или что уже произошло.',
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Text(
                              isEnglish ? 'Translation error' : 'Ошибка перевода',
                              style: TextStyle(color: Colors.red),
                            );
                          } else if (snapshot.hasData) {
                            final String translatedText = snapshot.data!;
                            return Text(
                              isEnglish
                                  ? translatedText
                                  : 'Пока нет событий, но мы можем предоставить информацию о том, чего ожидать или что уже произошло.',
                              style: TextStyle(
                                color: const Color.fromRGBO(205, 251, 228, 1),
                                fontSize: isEnglish ? 14 : 16, 
                                fontFamily: fontFamily,
                              ),
                              textAlign: TextAlign.center,
                            );
                          } else {
                            return const Text('Данные недоступны');
                          }
                        },
                      ),
                    ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    )
                  else if (_dayEvents.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        isEnglish
                            ? 'No events scheduled for this day'
                            : 'На этот день событий не запланировано',
                        style: TextStyle(
                          color: const Color.fromRGBO(205, 251, 228, 1),
                          fontSize: isEnglish ? 14 : 16,
                          fontFamily: fontFamily,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 406),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _dayEvents.map((event) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _buildEventCard(event, isEnglish, fontFamily),
                          );
                        }).toList(),
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
          },
        );
      },
    );
  }
}

class EventDetailsPage extends StatelessWidget {
  final Map<String, dynamic> event;

  const EventDetailsPage({super.key, required this.event});

  bool _isEventCompleted() {
    if (event['end_date'] == null) return false;
    final endDateStr = event['end_date'].toString();
    final endDate = DateTime.tryParse(endDateStr);
    if (endDate == null) return false;
    return endDate.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final isEnglish = languageProvider.isEnglish;
        final fontFamily = isEnglish ? 'Tomorrow' : 'Cornerita';
        final title = event['title'] ?? '';
        final description = event['description'] ?? '';
        final type = event['type'] ?? '';
        final startDate = event['start_date'];
        final endDate = event['end_date'];
        final isCompleted = _isEventCompleted();

        String formattedStartDate = '';
        String formattedStartTime = '';
        String formattedEndDate = '';
        String formattedEndTime = '';

        if (startDate != null) {
          try {
            final date = DateTime.tryParse(startDate.toString());
            if (date != null) {
              formattedStartDate = DateFormat('d MMMM yyyy', isEnglish ? 'en_US' : 'ru_RU').format(date);
              formattedStartTime = DateFormat('HH:mm').format(date);
            }
          } catch (e) {
            // Игнорируем ошибку
          }
        }

        if (endDate != null) {
          try {
            final date = DateTime.tryParse(endDate.toString());
            if (date != null) {
              formattedEndDate = DateFormat('d MMMM yyyy', isEnglish ? 'en_US' : 'ru_RU').format(date);
              formattedEndTime = DateFormat('HH:mm').format(date);
            }
          } catch (e) {
            // Игнорируем ошибку
          }
        }

        return Scaffold(
          backgroundColor: const Color.fromRGBO(6, 43, 66, 1),
          appBar: AppBar(
            backgroundColor: const Color.fromRGBO(6, 43, 66, 1),
            title: Text(
              isEnglish ? 'Event Details' : 'Подробности события',
              style: TextStyle(
                color: const Color(0xFFD8CCFF),
                fontFamily: fontFamily,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFFD8CCFF)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: isCompleted
                              ? Colors.grey
                              : const Color(0xFFFAEFD9),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: fontFamily,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                    ),
                    if (isCompleted)
                      Container(
                        margin: const EdgeInsets.only(left: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isEnglish ? 'Completed' : 'Завершено',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontFamily: fontFamily,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Тип события
                if (type.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCDFBE4).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFCDFBE4).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        color: const Color(0xFFCDFBE4),
                        fontSize: 14,
                        fontFamily: fontFamily,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Дата и время начала
                if (formattedStartDate.isNotEmpty) ...[
                  _buildInfoRow(
                    isEnglish ? 'Start Date' : 'Дата начала',
                    formattedStartDate,
                    fontFamily,
                  ),
                  const SizedBox(height: 12),
                  if (formattedStartTime.isNotEmpty)
                    _buildInfoRow(
                      isEnglish ? 'Start Time' : 'Время начала',
                      formattedStartTime,
                      fontFamily,
                    ),
                  const SizedBox(height: 24),
                ],

                // Дата и время окончания
                if (formattedEndDate.isNotEmpty) ...[
                  _buildInfoRow(
                    isEnglish ? 'End Date' : 'Дата окончания',
                    formattedEndDate,
                    fontFamily,
                  ),
                  const SizedBox(height: 12),
                  if (formattedEndTime.isNotEmpty)
                    _buildInfoRow(
                      isEnglish ? 'End Time' : 'Время окончания',
                      formattedEndTime,
                      fontFamily,
                    ),
                  const SizedBox(height: 24),
                ],

                // Описание
                if (description.isNotEmpty) ...[
                  Text(
                    isEnglish ? 'Description' : 'Описание',
                    style: TextStyle(
                      color: const Color(0xFFCDFBE4),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: fontFamily,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(10, 59, 92, 1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFCDFBE4).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      description,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                        fontFamily: fontFamily,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, String fontFamily) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: const Color(0xFFCDFBE4).withOpacity(0.8),
              fontSize: 14,
              fontFamily: fontFamily,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: fontFamily,
            ),
          ),
        ),
      ],
    );
  }
}

class WebViewPage extends StatelessWidget {
  final String url;

  const WebViewPage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final isEnglish = languageProvider.isEnglish;
        final fontFamily = isEnglish ? 'Tomorrow' : 'Cornerita';
        final titleText = isEnglish ? 'Link' : 'Ссылка';
        final buttonText = isEnglish ? 'Go to link' : 'Перейти по ссылке';
        final errorText = isEnglish ? 'Failed to open link' : 'Не удалось открыть ссылку';

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color.fromRGBO(6, 43, 66, 1), // Согласован с общим фоном
            title: Text(
              titleText,
              style: TextStyle(
                color: const Color(0xFFD8CCFF),
                fontFamily: fontFamily,
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
                    SnackBar(content: Text(errorText)),
                  );
                }
              },
              child: Text(buttonText),
            ),
          ),
        );
      },
    );
  }
}