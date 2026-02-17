import 'package:flutter/material.dart';
import 'package:cod_hammer/services/api_service.dart';
import 'package:cod_hammer/providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class CreateEventPage extends StatefulWidget {
  final DateTime? selectedDate;

  const CreateEventPage({super.key, this.selectedDate});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  static const _backgroundColor = Color(0xFF062B42);
  static const _cardColor = Color(0xFF0A3B5C);
  static const _glowColor = Color(0xFFFAEFD9);
  static const _textColorSecondary = Colors.white70;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  
  String _selectedType = 'Conference';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  final Map<String, String> _eventTypes = {
    'Conference': 'Научные конференции',
    'Hackathons': 'Хакатоны',
    'Workshop': 'Мастер-классы',
    'Seminar': 'Семинары',
    'Meeting': 'Встречи',
    'Webinar': 'Вебинары',
    'Exhibition': 'Выставки',
    'Competition': 'Соревнования',
  };

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _dateController = TextEditingController();
    _timeController = TextEditingController();
    
    if (widget.selectedDate != null) {
      _selectedDate = widget.selectedDate!;
      _selectedTime = TimeOfDay.fromDateTime(widget.selectedDate!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDateAndTimeControllers();
  }

  void _updateDateAndTimeControllers() {
    final dateFormat = DateFormat('yyyy-MM-dd');
    _dateController.text = dateFormat.format(_selectedDate);
    _timeController.text = _selectedTime.format(context);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _glowColor,
              onPrimary: _backgroundColor,
              surface: _cardColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updateDateAndTimeControllers();
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _glowColor,
              onPrimary: _backgroundColor,
              surface: _cardColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _updateDateAndTimeControllers();
      });
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Объединяем дату и время
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      
      // Конечная дата - через 2 часа от начала (можно изменить)
      final endDateTime = startDateTime.add(const Duration(hours: 2));

      await ApiService.createEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        startDate: startDateTime,
        endDate: endDateTime,
      );

      if (mounted) {
        Navigator.pop(context, true); // Возвращаем true для обновления календаря
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Событие успешно создано')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка создания события: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final isEnglish = languageProvider.isEnglish;
        return Scaffold(
          backgroundColor: _backgroundColor,
          appBar: AppBar(
            title: Text(
              isEnglish ? 'Create Event' : 'Создать событие',
              style: const TextStyle(
                color: Color(0xFFD8CCFF),
              ),
            ),
            backgroundColor: _cardColor,
            iconTheme: const IconThemeData(color: Color(0xFFD8CCFF)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    _titleController,
                    isEnglish ? 'Event Title' : 'Название события',
                    isRequired: true,
                  ),
                  const SizedBox(height: 24),
                  _buildTypeDropdown(isEnglish),
                  const SizedBox(height: 24),
                  _buildDateField(isEnglish),
                  const SizedBox(height: 24),
                  _buildTimeField(isEnglish),
                  const SizedBox(height: 24),
                  _buildTextField(
                    _descriptionController,
                    isEnglish ? 'Description' : 'Описание',
                    maxLines: 5,
                    isRequired: true,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _glowColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        isEnglish ? 'Create Event' : 'Создать событие',
                        style: const TextStyle(
                          color: _backgroundColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _textColorSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _glowColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _glowColor),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Поле обязательно для заполнения';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildTypeDropdown(bool isEnglish) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEnglish ? 'Event Type' : 'Тип события',
          style: TextStyle(
            color: _textColorSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: _glowColor.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedType,
            dropdownColor: _cardColor,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
            ),
            items: _eventTypes.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(isEnglish ? entry.key : entry.value),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedType = value;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(bool isEnglish) {
    return TextFormField(
      controller: _dateController,
      readOnly: true,
      onTap: _selectDate,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: isEnglish ? 'Date' : 'Дата',
        labelStyle: TextStyle(color: _textColorSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        suffixIcon: const Icon(Icons.calendar_today, color: _glowColor),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _glowColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _glowColor),
        ),
      ),
    );
  }

  Widget _buildTimeField(bool isEnglish) {
    return TextFormField(
      controller: _timeController,
      readOnly: true,
      onTap: _selectTime,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: isEnglish ? 'Time' : 'Время',
        labelStyle: TextStyle(color: _textColorSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        suffixIcon: const Icon(Icons.access_time, color: _glowColor),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _glowColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: _glowColor),
        ),
      ),
    );
  }
}
