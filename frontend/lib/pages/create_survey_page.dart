import 'package:flutter/material.dart';
import 'package:cod_hammer/services/api_service.dart';
import 'package:cod_hammer/providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CreateSurveyPage extends StatefulWidget {
  const CreateSurveyPage({super.key});

  @override
  State<CreateSurveyPage> createState() => _CreateSurveyPageState();
}

class _CreateSurveyPageState extends State<CreateSurveyPage> {
  static const _backgroundColor = Color(0xFF062B42);
  static const _cardColor = Color(0xFF0A3B5C);
  static const _glowColor = Color(0xFFFAEFD9);
  static const _textColorSecondary = Colors.white70;

  final _formKey = GlobalKey<FormState>();
  final _titleRuController = TextEditingController();
  final _titleEnController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<QuestionController> _questions = [];
  DateTime? _endDate;
  TimeOfDay? _endTime;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addQuestion();
  }

  void _addQuestion() {
    setState(() {
      _questions.add(QuestionController());
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка выбора изображения: $e')),
      );
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 7)),
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
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
      _selectEndTime();
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
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
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  Future<void> _saveSurvey() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте хотя бы один вопрос')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Загрузить изображение на сервер и получить URL
      // Пока используем локальный путь или null
      String? imageUrl;
      if (_selectedImage != null) {
        // Здесь должна быть загрузка на сервер
        // imageUrl = await uploadImage(_selectedImage!);
      }

      DateTime? endDateTime;
      if (_endDate != null && _endTime != null) {
        endDateTime = DateTime(
          _endDate!.year,
          _endDate!.month,
          _endDate!.day,
          _endTime!.hour,
          _endTime!.minute,
        );
      }

      final questions = _questions.map((q) => {
        'text': q.textController.text,
        'type': 'multiple_choice',
        'options': q.options
            .where((opt) => opt.textController.text.isNotEmpty)
            .map((opt) => opt.textController.text)
            .toList(),
      }).toList();

      // Формируем название в формате JSON для поддержки двух языков
      final titleRu = _titleRuController.text.trim();
      final titleEn = _titleEnController.text.trim();
      final title = titleRu.isNotEmpty || titleEn.isNotEmpty
          ? {
              if (titleRu.isNotEmpty) 'ru': titleRu,
              if (titleEn.isNotEmpty) 'en': titleEn,
            }
          : (titleRu.isNotEmpty ? titleRu : titleEn);

      await ApiService.createSurvey(
        title: title,
        description: _descriptionController.text.trim(),
        questions: questions,
        imageUrl: imageUrl,
        endDate: endDateTime,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Опросник успешно создан')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка создания опросника: $e')),
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
    _titleRuController.dispose();
    _titleEnController.dispose();
    _descriptionController.dispose();
    for (var q in _questions) {
      q.dispose();
    }
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
              isEnglish ? 'Create Survey' : 'Создать опросник',
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
                  // Загрузка изображения
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _glowColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  color: _glowColor,
                                  size: 48,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isEnglish ? 'Add Image' : 'Добавить изображение',
                                  style: TextStyle(
                                    color: _glowColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    _titleRuController,
                    'Название опросника (русский)',
                    isRequired: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _titleEnController,
                    'Survey Title (English)',
                    isRequired: true,
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    _descriptionController,
                    isEnglish ? 'Description' : 'Описание',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  // Дата окончания
                  TextFormField(
                    readOnly: true,
                    onTap: _selectEndDate,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: isEnglish ? 'End Date (Optional)' : 'Дата окончания (необязательно)',
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
                    controller: TextEditingController(
                      text: _endDate != null && _endTime != null
                          ? '${_endDate!.day}.${_endDate!.month}.${_endDate!.year} ${_endTime!.hour}:${_endTime!.minute.toString().padLeft(2, '0')}'
                          : '',
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Вопросы
                  Text(
                    isEnglish ? 'Questions' : 'Вопросы',
                    style: TextStyle(
                      color: _glowColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(_questions.length, (index) {
                    return _buildQuestionCard(index, isEnglish);
                  }),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add),
                    label: Text(isEnglish ? 'Add Question' : 'Добавить вопрос'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _cardColor,
                      foregroundColor: _glowColor,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveSurvey,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _glowColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(_backgroundColor),
                            )
                          : Text(
                              isEnglish ? 'Create Survey' : 'Создать опросник',
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

  Widget _buildQuestionCard(int index, bool isEnglish) {
    final question = _questions[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  '${isEnglish ? 'Question' : 'Вопрос'} ${index + 1}',
                  style: TextStyle(
                    color: _glowColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_questions.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeQuestion(index),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            question.textController,
            isEnglish ? 'Question Text' : 'Текст вопроса',
            isRequired: true,
          ),
          const SizedBox(height: 16),
          Text(
            isEnglish ? 'Options' : 'Варианты ответов',
            style: TextStyle(
              color: _textColorSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(question.options.length, (optIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      question.options[optIndex].textController,
                      '${isEnglish ? 'Option' : 'Вариант'} ${optIndex + 1}',
                      isRequired: true,
                    ),
                  ),
                  if (question.options.length > 2)
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          question.options.removeAt(optIndex);
                        });
                      },
                    ),
                ],
              ),
            );
          }),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                question.options.add(OptionController());
              });
            },
            icon: const Icon(Icons.add, size: 16),
            label: Text(isEnglish ? 'Add Option' : 'Добавить вариант'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _backgroundColor,
              foregroundColor: _glowColor,
            ),
          ),
        ],
      ),
    );
  }
}

class QuestionController {
  final TextEditingController textController = TextEditingController();
  final List<OptionController> options = [];

  QuestionController() {
    options.add(OptionController());
    options.add(OptionController());
  }

  void dispose() {
    textController.dispose();
    for (var opt in options) {
      opt.dispose();
    }
  }
}

class OptionController {
  final TextEditingController textController = TextEditingController();

  void dispose() {
    textController.dispose();
  }
}
