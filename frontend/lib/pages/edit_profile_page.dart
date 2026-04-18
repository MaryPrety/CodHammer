import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cod_hammer/services/api_service.dart';
import 'package:cod_hammer/widgets/avatar_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> profileData;
  final VoidCallback onProfileUpdated;

  const EditProfilePage({
    super.key,
    required this.profileData,
    required this.onProfileUpdated,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const _backgroundColor = Color(0xFF062B42);
  static const _cardColor = Color(0xFF0A3B5C);
  static const _glowColor = Color(0xFFFAEFD9);
  static const _textColorSecondary = Colors.white70;
  static const String _avatarKey = 'profile_avatar_path';

  late TextEditingController _nameController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _studyGroupController;
  late TextEditingController _enrollmentYearController;
  late TextEditingController _educationalInstitutionController;
  late TextEditingController _educationalDirectionController;
  late TextEditingController _ageController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _interestsController;
  late TextEditingController _statusController;

  bool _isLoading = false;
  String? _avatarPath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profileData['name'] ?? widget.profileData['username'] ?? '');
    _firstNameController = TextEditingController(text: widget.profileData['first_name'] ?? '');
    _lastNameController = TextEditingController(text: widget.profileData['last_name'] ?? '');
    _studyGroupController = TextEditingController(text: widget.profileData['study_group'] ?? '');
    _enrollmentYearController = TextEditingController(text: widget.profileData['enrollment_year']?.toString() ?? '');
    _educationalInstitutionController = TextEditingController(text: widget.profileData['educational_institution'] ?? '');
    _educationalDirectionController = TextEditingController(text: widget.profileData['educational_direction'] ?? '');
    _ageController = TextEditingController(text: widget.profileData['age']?.toString() ?? '');
    _phoneController = TextEditingController(text: widget.profileData['phone'] ?? '');
    _emailController = TextEditingController(text: widget.profileData['email'] ?? '');
    _interestsController = TextEditingController(
      text: (widget.profileData['interests'] as List?)?.join(', ') ?? ''
    );
    _statusController = TextEditingController(text: widget.profileData['status'] ?? 'Активен');
    _loadAvatarPath();
  }

  Future<void> _loadAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(_avatarKey);
    if (mounted) {
      setState(() {
        _avatarPath = savedPath;
      });
    }
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
        // Копируем файл в директорию приложения
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'profile_avatar_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
        final savedImage = await File(image.path).copy(path.join(appDir.path, fileName));
        
        if (mounted) {
          setState(() {
            _avatarPath = savedImage.path;
          });
          // Сохраняем путь в SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_avatarKey, savedImage.path);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выбора изображения: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _studyGroupController.dispose();
    _enrollmentYearController.dispose();
    _educationalInstitutionController.dispose();
    _educationalDirectionController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _interestsController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  final _formKey = GlobalKey<FormState>();

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final interests = _interestsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      await ApiService.updateProfile(
        name: _nameController.text.isNotEmpty ? _nameController.text : null,
        email: _emailController.text,
        age: int.tryParse(_ageController.text) ?? 0,
        status: _statusController.text,
        interests: interests,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        studyGroup: _studyGroupController.text,
        enrollmentYear: int.tryParse(_enrollmentYearController.text) ?? 0,
        educationalInstitution: _educationalInstitutionController.text,
        educationalDirection: _educationalDirectionController.text,
      );

    widget.onProfileUpdated();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Профиль успешно обновлен')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Редактировать профиль',
          style: TextStyle(
            color: Color(0xFFD8CCFF),
          ),
        ),
        backgroundColor: _cardColor,
        iconTheme: const IconThemeData(color: Color(0xFFD8CCFF)),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_glowColor),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.save, color: Color(0xFFD8CCFF)),
                  onPressed: _saveProfile,
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  AvatarWidget(
                    imageUrl: _avatarPath,
                    width: 100,
                    height: 100,
                    glowColor: _glowColor,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _glowColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: _backgroundColor,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _pickImage,
              child: Text(
                'Изменить фотографию',
                style: TextStyle(color: _glowColor),
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(_nameController, 'Никнейм (необязательно)'),
            const SizedBox(height: 24),
            _buildTextField(_firstNameController, 'Имя', isRequired: true),
            const SizedBox(height: 24),
            _buildTextField(_lastNameController, 'Фамилия', isRequired: true),
            const SizedBox(height: 24),
            _buildTextField(_studyGroupController, 'Учебная группа', isRequired: true),
            const SizedBox(height: 24),
            _buildTextField(_enrollmentYearController, 'Год поступления', keyboardType: TextInputType.number, isRequired: true),
            const SizedBox(height: 24),
            _buildTextField(_educationalInstitutionController, 'Учебное заведение', isRequired: true),
            const SizedBox(height: 24),
            _buildTextField(_educationalDirectionController, 'Учебное направление', isRequired: true),
            const SizedBox(height: 24),
            _buildTextField(_ageController, 'Возраст', keyboardType: TextInputType.number, isRequired: true),
            const SizedBox(height: 24),
            _buildTextField(_phoneController, 'Телефон', keyboardType: TextInputType.phone, isRequired: true),
            const SizedBox(height: 24),
            _buildTextField(_emailController, 'Email', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 24),
            _buildTextField(_statusController, 'Статус'),
            const SizedBox(height: 24),
            _buildTextField(_interestsController, 'Интересы (через запятую, не больше 5-и)'),
            const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType? keyboardType, bool isRequired = false}) {
    // Для текстовых полей (не email и не число) разрешаем ввод на русском
    final bool isTextField = keyboardType == null || keyboardType == TextInputType.text;
    
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType ?? TextInputType.text,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: Colors.white),
      // Явно разрешаем ввод на русском языке для текстовых полей
      enableSuggestions: isTextField,
      autocorrect: isTextField,
      // Убираем любые ограничения на ввод символов
      inputFormatters: null,
      validator: isRequired ? (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Поле обязательно для заполнения';
        }
        if (keyboardType == TextInputType.number) {
          final num = int.tryParse(value);
          if (num == null) {
            return 'Введите корректное число';
          }
          if (label.contains('Год') && (num < 1900 || num > 2100)) {
            return 'Введите корректный год';
          }
          if (label.contains('Возраст') && (num < 1 || num > 150)) {
            return 'Введите корректный возраст';
          }
        }
        return null;
      } : null,
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
        // Добавляем подсказку для текстовых полей
        helperText: isTextField ? 'Поддерживается ввод на русском и английском языках' : null,
        helperStyle: TextStyle(
          color: _textColorSecondary.withOpacity(0.7),
          fontSize: 11,
        ),
        helperMaxLines: 2,
      ),
    );
  }
}