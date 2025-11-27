import 'package:flutter/material.dart';
import 'package:cod_hammer/services/api_service.dart';
import 'package:cod_hammer/widgets/avatar_widget.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> profileData;
  final VoidCallback onProfileUpdated;

  const EditProfilePage({
    Key? key,
    required this.profileData,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const _backgroundColor = Color(0xFF062B42);
  static const _cardColor = Color(0xFF0A3B5C);
  static const _glowColor = Color(0xFFFAEFD9);
  static const _textColorSecondary = Colors.white70;

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _emailController;
  late TextEditingController _interestsController;
  late TextEditingController _statusController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profileData['name']);
    _ageController = TextEditingController(text: widget.profileData['age']?.toString() ?? '');
    _emailController = TextEditingController(text: widget.profileData['email'] ?? '');
    _interestsController = TextEditingController(
      text: (widget.profileData['interests'] as List?)?.join(', ') ?? ''
    );
    _statusController = TextEditingController(text: widget.profileData['status'] ?? 'Active');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _interestsController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
  setState(() => _isLoading = true);

  try {
    final interests = _interestsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    await ApiService.updateProfile(
      name: _nameController.text,
      email: _emailController.text,
      age: int.tryParse(_ageController.text) ?? 0,
      status: _statusController.text,
      interests: interests,
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
        title: const Text('Редактировать профиль'),
        backgroundColor: _cardColor,
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_glowColor),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _saveProfile,
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AvatarWidget(
              imageUrl: widget.profileData['avatar_url'],
              width: 100,
              height: 100,
              glowColor: _glowColor,
            ),
            const SizedBox(height: 20),
            _buildTextField(_nameController, 'Имя'),
            const SizedBox(height: 10),
            _buildTextField(_ageController, 'Возраст', keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            _buildTextField(_emailController, 'Email', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 10),
            _buildTextField(_statusController, 'Статус'),
            const SizedBox(height: 10),
            _buildTextField(_interestsController, 'Интересы (через запятую, не больше 5-и)'),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _textColorSecondary),
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