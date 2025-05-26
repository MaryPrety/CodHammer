import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'register_page.dart';

class AuthorizePage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;
  const AuthorizePage({super.key, this.onLoginSuccess});

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
      backgroundColor: _backgroundColor,
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
                  color: _secondaryColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              _buildLoginForm(),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterPage()),
                  );
                },
                child: Text(
                  'Нет аккаунта? Зарегистрироваться',
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

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              labelText: 'Email или телефон',
              labelStyle: TextStyle(
                fontFamily: 'Cornerita',
                color: _textColorSecondary,
              ),
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
            keyboardType: TextInputType.visiblePassword,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Пароль',
              labelStyle: TextStyle(
                fontFamily: 'Cornerita',
                color: _textColorSecondary,
              ),
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
                    await ApiService.login(
                      _emailController.text,
                      _passwordController.text,
                    );

                  final token = await ApiService.getToken();
                  if (token != null) {
                    if (mounted) {
                      widget.onLoginSuccess?.call();
                      Navigator.of(context).pushReplacementNamed('/main');
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Ошибка: токен не получен")),
                    );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Ошибка входа: $e")),
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
