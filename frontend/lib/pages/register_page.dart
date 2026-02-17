// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:cod_hammer/services/api_service.dart';
import 'package:flutter/material.dart';
import 'authorize_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _studyGroupController = TextEditingController();
  final _enrollmentYearController = TextEditingController();
  final _educationalInstitutionController = TextEditingController();
  final _educationalDirectionController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();

  // Цветовая палитра
  static const _secondaryColor = Color.fromRGBO(205, 251, 228, 1); // Light Green
  static const _tertiaryColor = Color(0xFFB19CD9); // Light Purple
  static const _backgroundColor = Color(0xFF062B42); // Dark Background
  static const _cardColor = Color(0xFF0A3B5C);
  static const _textColorSecondary = Colors.white70;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _studyGroupController.dispose();
    _enrollmentYearController.dispose();
    _educationalInstitutionController.dispose();
    _educationalDirectionController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Регистрация',
                style: TextStyle(
                  fontFamily: 'StalinistOne',
                  color: _secondaryColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              _buildRegisterForm(),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthorizePage()),
                  );
                },
                child: const Text(
                  'Уже есть аккаунт? Войти',
                  style: TextStyle(
                    fontFamily: 'Cornerita',
                    color: _tertiaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Никнейм (необязательно)',
              labelStyle: const TextStyle(
                fontFamily: 'Cornerita',
                color: _textColorSecondary,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _textColorSecondary),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _secondaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _tertiaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _tertiaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: _cardColor.withOpacity(0.5),
            ),
            style: const TextStyle(
              fontFamily: 'Cornerita',
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: const TextStyle(
                fontFamily: 'Cornerita',
                color: _textColorSecondary,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _textColorSecondary),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _secondaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _tertiaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _tertiaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: _cardColor.withOpacity(0.5),
            ),
            style: const TextStyle(
              fontFamily: 'Cornerita',
              color: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Пожалуйста, введите email';
              }
              if (!value.contains('@')) {
                return 'Введите корректный email';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Пароль',
              labelStyle: const TextStyle(
                fontFamily: 'Cornerita',
                color: _textColorSecondary,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _textColorSecondary),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _secondaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _tertiaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _tertiaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: _cardColor.withOpacity(0.5),
            ),
            style: const TextStyle(
              fontFamily: 'Cornerita',
              color: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Пожалуйста, введите пароль';
              }
              if (value.length < 6) {
                return 'Пароль должен быть не менее 6 символов';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _firstNameController,
            decoration: InputDecoration(
              labelText: 'Имя',
              labelStyle: const TextStyle(
                fontFamily: 'Cornerita',
                color: _textColorSecondary,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _textColorSecondary),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _secondaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _tertiaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _tertiaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: _cardColor.withOpacity(0.5),
            ),
            style: const TextStyle(
              fontFamily: 'Cornerita',
              color: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Пожалуйста, введите имя';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _lastNameController,
            decoration: InputDecoration(
              labelText: 'Фамилия',
              labelStyle: const TextStyle(
                fontFamily: 'Cornerita',
                color: _textColorSecondary,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _textColorSecondary),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _secondaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _tertiaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _tertiaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: _cardColor.withOpacity(0.5),
            ),
            style: const TextStyle(
              fontFamily: 'Cornerita',
              color: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Пожалуйста, введите фамилию';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _studyGroupController,
            decoration: InputDecoration(
              labelText: 'Учебная группа',
              labelStyle: const TextStyle(
                fontFamily: 'Cornerita',
                color: _textColorSecondary,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _textColorSecondary),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _secondaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _tertiaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _tertiaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: _cardColor.withOpacity(0.5),
            ),
            style: const TextStyle(
              fontFamily: 'Cornerita',
              color: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Пожалуйста, введите учебную группу';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _enrollmentYearController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Год поступления',
              labelStyle: const TextStyle(
                fontFamily: 'Cornerita',
                color: _textColorSecondary,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _textColorSecondary),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _secondaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _tertiaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _tertiaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: _cardColor.withOpacity(0.5),
            ),
            style: const TextStyle(
              fontFamily: 'Cornerita',
              color: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Пожалуйста, введите год поступления';
              }
              final year = int.tryParse(value);
              if (year == null || year < 1900 || year > 2100) {
                return 'Введите корректный год';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _educationalInstitutionController,
            decoration: InputDecoration(
              labelText: 'Учебное заведение',
              labelStyle: const TextStyle(
                fontFamily: 'Cornerita',
                color: _textColorSecondary,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _textColorSecondary),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _secondaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _tertiaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _tertiaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: _cardColor.withOpacity(0.5),
            ),
            style: const TextStyle(
              fontFamily: 'Cornerita',
              color: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Пожалуйста, введите учебное заведение';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _educationalDirectionController,
            decoration: InputDecoration(
              labelText: 'Учебное направление',
              labelStyle: const TextStyle(
                fontFamily: 'Cornerita',
                color: _textColorSecondary,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _textColorSecondary),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _secondaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _tertiaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _tertiaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: _cardColor.withOpacity(0.5),
            ),
            style: const TextStyle(
              fontFamily: 'Cornerita',
              color: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Пожалуйста, введите учебное направление';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Возраст',
              labelStyle: const TextStyle(
                fontFamily: 'Cornerita',
                color: _textColorSecondary,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _textColorSecondary),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _secondaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _tertiaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _tertiaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: _cardColor.withOpacity(0.5),
            ),
            style: const TextStyle(
              fontFamily: 'Cornerita',
              color: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Пожалуйста, введите возраст';
              }
              final age = int.tryParse(value);
              if (age == null || age < 1 || age > 150) {
                return 'Введите корректный возраст';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Телефон',
              labelStyle: const TextStyle(
                fontFamily: 'Cornerita',
                color: _textColorSecondary,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _textColorSecondary),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: _secondaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _tertiaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _tertiaryColor),
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: _cardColor.withOpacity(0.5),
            ),
            style: const TextStyle(
              fontFamily: 'Cornerita',
              color: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Пожалуйста, введите телефон';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                backgroundColor: _tertiaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
                shadowColor: _tertiaryColor.withOpacity(0.4),
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    await ApiService.register(
                      username: _usernameController.text.isNotEmpty
                          ? _usernameController.text
                          : null,
                      email: _emailController.text,
                      password: _passwordController.text,
                      firstName: _firstNameController.text,
                      lastName: _lastNameController.text,
                      studyGroup: _studyGroupController.text,
                      enrollmentYear: int.parse(_enrollmentYearController.text),
                      educationalInstitution: _educationalInstitutionController.text,
                      educationalDirection: _educationalDirectionController.text,
                      age: int.parse(_ageController.text),
                      phone: _phoneController.text,
                    );

                    // После успешной регистрации сразу авторизуем пользователя
                    await ApiService.login(
                      _emailController.text,
                      _passwordController.text,
                    );

                    Navigator.pushReplacementNamed(context, "/main");
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ошибка регистрации: $e')),
                    );
                  }
                }
              },
              child: const Text(
                'Зарегистрироваться',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Tomorrow',
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}