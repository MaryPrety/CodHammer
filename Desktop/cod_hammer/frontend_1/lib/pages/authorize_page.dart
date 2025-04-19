import 'package:cod_hammer/services/api_service.dart';
import 'package:flutter/material.dart';
import 'register_page.dart';

class AuthorizePage extends StatefulWidget {
  const AuthorizePage({super.key});

  @override
  _AuthorizePageState createState() => _AuthorizePageState();
}

class _AuthorizePageState extends State<AuthorizePage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Цветовая палитра
  static const _secondaryColor = Color.fromRGBO(205, 251, 228, 1); // Light Green
  static const _tertiaryColor = Color(0xFFB19CD9); // Light Purple
  static const _backgroundColor = Color(0xFF062B42); // Dark Background
  static const _cardColor = Color(0xFF0A3B5C);
  static const _textColorSecondary = Colors.white70;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor, // Используем темный фон
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Вход в систему',
                style: TextStyle(
                  fontFamily: 'StalinistOne',
                  color: _secondaryColor, // Легкий зеленый текст
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              _buildLoginForm(),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterPage()),
                  );
                },
                child: Text(
                  'Нет аккаунта? Зарегистрироваться',
                  style: TextStyle(
                    fontFamily: 'Cornerita',
                    color: _tertiaryColor, // Легкий фиолетовый текст
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email или телефон',
              labelStyle: TextStyle(
                fontFamily: 'Cornerita',
                color: _textColorSecondary,
              ), // Белый текст с прозрачностью
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _textColorSecondary),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _secondaryColor),
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
                return 'Пожалуйста, введите email или телефон';
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
              labelStyle: TextStyle(
                fontFamily: 'Cornerita',
                color: _textColorSecondary,
              ), // Белый текст с прозрачностью
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _textColorSecondary),
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _secondaryColor),
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
          const SizedBox(height: 20),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.5, // 50% of screen width
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10), // Adjusted padding
                backgroundColor: _tertiaryColor, // Фиолетовый фон кнопки
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5, // Add elevation for shadow effect
                shadowColor: _tertiaryColor.withOpacity(0.4), // Shadow color
                
              ),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    await ApiService.login(
                      _emailController.text,
                      _passwordController.text,
                    );

                    Navigator.pushReplacementNamed(context, "/main");
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Ошибка ввода: $e")),
                    );
                  }
                }
              },
              child: const Text(
                'Войти',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Tomorrow',
                  color: Colors.white,
                  fontSize: 16, // Увеличенный размер шрифта
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}